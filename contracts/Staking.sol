// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

error STAKING_indexOutOfBounds();
error STAKING_invalidTokenId();
error STAKING_transferFailed();
error STAKING_noDividends();

contract Staking is BaseContract, ERC721 {
    /**
     * Contract constructor.
     */
    constructor() ERC721("Tux Staking", "TUXS") {}

    using Strings for address;
    using Strings for uint256;

    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    /**
     * External contracts.
     */
    IERC20 private _tux;
    IERC20 private _usdc;
    IUniswapV2Router02 private _router;

    /**
     * Global stats.
     */
    uint256 public totalWcStaked;
    uint256 public totalRcStaked;
    uint256 public totalDividends;
    uint256 private _dividendsPerShare;
    uint256 public lastUpdate;
    uint256 public currentTuxPrice;

    /**
     * Token data.
     */
    uint256 private _tokenIdTracker;

    mapping(uint256 => uint256) private _stakeAmount;
    mapping(uint256 => uint256) private _stakeStart;
    mapping(uint256 => uint256) private _startingStakeAmount;
    mapping(uint256 => uint256) private _dividendsCompounded;
    mapping(uint256 => uint256) private _dividendsClaimed;
    mapping(uint256 => uint256) private _dividendDebt;

    /**
     * Setup.
     */
    function setup() external override
    {
        _usdc = IERC20(addressBook.get("Usdc"));
        _tux = IERC20(addressBook.get("Tux"));
        _router = IUniswapV2Router02(addressBook.get("Router"));
    }

    /**
     * Token of owner by index
     * @param owner_ Owner address.
     * @param index_ Index.
     * @return uint256 Token ID.
     */
    function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256)
    {
        return _tokenOfOwnerByIndex(owner_, index_);
    }

    /**
     * Token of owner by index internal
     * @param owner_ Owner address.
     * @param index_ Index.
     * @return uint256 Token ID.
     */
    function _tokenOfOwnerByIndex(address owner_, uint256 index_) internal view returns (uint256)
    {
        if(balanceOf(owner_) <= index_) revert STAKING_indexOutOfBounds();
        for(uint256 i = 1; i <= _tokenIdTracker; i++) {
            if(ownerOf(i) == owner_) {
                if(index_ == 0) return i;
                index_--;
            }
        }
        return 0;
    }

    /**
     * Token URI.
     * @param tokenId_ Token ID.
     * @return string Token metadata.
     */
    function tokenURI(uint256 tokenId_) public view override returns (string memory)
    {
        if(tokenId_ <= 0 || tokenId_ > _tokenIdTracker) revert STAKING_invalidTokenId();
        string memory _type_ = 'White Carpet';
        string memory _currency_ = 'TUX';
        uint256 _value_ = _stakeAmount[tokenId_] / 1e18;
        uint256 _age_ = (block.timestamp - _stakeStart[tokenId_]) / 1 days;
        if(tokenType(tokenId_) == 2) {
            _type_ = 'Red Carpet';
            _currency_ = 'USDC';
        }
        if(tokenType(tokenId_) == 3) {
            _type_ = 'Dead';
            _currency_ = 'TUX';
            _value_ = 0;
        }
        bytes memory _meta_ = abi.encodePacked(
            '{',
            '"name": "Tux Staking #', tokenId_.toString(), '",',
            '"description": "Tux Staking",',
            '"image": "', tokenImage(tokenId_), '",',
            '"attributes": [',
            abi.encodePacked(
                '{"trait_type": "Type", "value": "', _type_, '"},',
                '{"trait_type": "Value", "value": "', _value_.toString(), ' ', _currency_, '"},',
                '{"trait_type": "Age", "value": "', _age_.toString(), ' days"}'
            ),
            ']',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(_meta_)
            )
        );
    }

    /**
     * Token type.
     * @param tokenId_ Token ID.
     * @return uint256 Token type.
     * @dev 1 = White Carpet, 2 = Red Carpet, 3 = Dead.
     */
    function tokenType(uint256 tokenId_) public view returns (uint256)
    {
        return _tokenType(tokenId_);
    }

    /**
     * Token type internal.
     * @param tokenId_ Token ID.
     * @return uint256 Token type.
     * @dev 1 = White Carpet, 2 = Red Carpet, 3 = Dead.
     */
    function _tokenType(uint256 tokenId_) internal view returns (uint256)
    {
        return 1;
    }

    /**
     * Token image.
     * @param tokenId_ Token ID.
     * @return string Token image.
     */
    function tokenImage(uint256 tokenId_) public view returns (string memory)
    {
        return _tokenImage(tokenId_);
    }

    /**
     * Token image internal.
     * @param tokenId_ Token ID.
     * @return string Token image.
     */
    function _tokenImage(uint256 tokenId_) internal view returns (string memory)
    {
        return 'https://picsum.photos/600';
    }

    /**
     * Token value.
     * @param tokenId_ Token ID.
     * @return uint256 Token value.
     */
    function tokenValue(uint256 tokenId_) public view returns (uint256)
    {
        return _tokenValue(tokenId_);
    }

    /**
     * Token value internal.
     * @param tokenId_ Token ID.
     * @return uint256 Token value.
     */
    function _tokenValue(uint256 tokenId_) internal view returns (uint256)
    {
        return _stakeAmount[tokenId_];
    }

    /**
     * Stake.
     * @param amount_ Amount to stake
     */
    function stake(uint256 amount_) external
    {
        _updateRewards();
        // Transfer tokens in.
        if(!_tux.transferFrom(msg.sender, address(this), amount_)) revert STAKING_transferFailed();
        totalWcStaked += amount_;
        // Create stake.
        _tokenIdTracker++;
        _stakeAmount[_tokenIdTracker] = amount_;
        _startingStakeAmount[_tokenIdTracker] = amount_;
        _stakeStart[_tokenIdTracker] = block.timestamp;
        _dividendDebt[_tokenIdTracker] = (amount_ * _dividendsPerShare) / 1e18;
        _mint(msg.sender, _tokenIdTracker);
    }

    /**
     * Compound.
     * @param tokenId_ Token ID.
     */
    function compound(uint256 tokenId_) external
    {
        _updateRewards();
        if(tokenId_ <= 0 || tokenId_ > _tokenIdTracker) revert STAKING_invalidTokenId();
        if(ownerOf(tokenId_) != msg.sender) revert STAKING_invalidTokenId();
        if(tokenType(tokenId_) != 1) revert STAKING_invalidTokenId();
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        if(_availableDividends_ <= 0) revert STAKING_noDividends();
        _dividendDebt[tokenId_] = (_stakeAmount[tokenId_] * _dividendsPerShare) / 1e18;
        totalWcStaked += _availableDividends_;
        _dividendsCompounded[tokenId_] += _availableDividends_;
        _stakeAmount[tokenId_] += _availableDividends_;
    }

    /**
     * Claim.
     * @param tokenId_ Token ID.
     */
    function claim(uint256 tokenId_) external
    {
        _updateRewards();
        if(tokenId_ <= 0 || tokenId_ > _tokenIdTracker) revert STAKING_invalidTokenId();
        if(ownerOf(tokenId_) != msg.sender) revert STAKING_invalidTokenId();
        if(tokenType(tokenId_) != 1) revert STAKING_invalidTokenId();
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        if(_availableDividends_ <= 0) revert STAKING_noDividends();
        _dividendDebt[tokenId_] = (_stakeAmount[tokenId_] * _dividendsPerShare) / 1e18;
        _dividendsClaimed[tokenId_] += _availableDividends_;
        if(!_tux.transfer(msg.sender, _availableDividends_)) revert STAKING_transferFailed();
    }

    /**
     * Unstake.
     * @param tokenId_ Token ID.
     */
    function unstake(uint256 tokenId_) external
    {
        _updateRewards();
        if(tokenId_ <= 0 || tokenId_ > _tokenIdTracker) revert STAKING_invalidTokenId();
        if(ownerOf(tokenId_) != msg.sender) revert STAKING_invalidTokenId();
        if(tokenType(tokenId_) != 1) revert STAKING_invalidTokenId();
        uint256 _stakeAmount_ = _stakeAmount[tokenId_];
        _stakeAmount[tokenId_] = 0;
        _transfer(msg.sender, deadAddress, tokenId_);
        totalWcStaked -= _stakeAmount_;
        if(!_tux.transfer(msg.sender, _stakeAmount_)) revert STAKING_transferFailed();
    }

    /**
     * Staked amount.
     * @param owner_ Owner address.
     * @return uint256 Total amount staked by owner.
     */
    function stakedAmount(address owner_) external view returns (uint256)
    {
        uint256 _balance_ = balanceOf(owner_);
        uint256 _stakedAmount_ = 0;
        for(uint256 i = 0; i < _balance_; i++) {
            _stakedAmount_ += _stakeAmount[_tokenOfOwnerByIndex(owner_, i)];
        }
        return _stakedAmount_;
    }

    /**
     * Update rewards.
     */
    function updateRewards() public
    {
        return _updateRewards();
    }

    /**
     * Update rewards internal.
     */
    function _updateRewards() internal
    {
        if(block.timestamp - lastUpdate < 1 hours) return;
        lastUpdate = (block.timestamp / 1 hours) * 1 hours;
        uint256 _newRewards_ = _tux.balanceOf(address(this)) - totalWcStaked;
        totalDividends += _newRewards_;
        _dividendsPerShare += (_newRewards_ * 1e18) / totalWcStaked;
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_tux);
        _path_[1] = address(_usdc);
        currentTuxPrice = _router.getAmountsOut(1e18, _path_)[1];
    }

    /**
     * Available dividends.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function availableDividends(uint256 tokenId_) public returns (uint256)
    {
        return _availableDividends(tokenId_);
    }

    /**
     * Available dividends internal.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function _availableDividends(uint256 tokenId_) internal returns (uint256)
    {
        if(tokenType(tokenId_) != 1) return 0;
        if(_stakeAmount[tokenId_] == 0) return 0;
        return ((_stakeAmount[tokenId_] * _dividendsPerShare) / 1e18) - _dividendDebt[tokenId_];
    }
}
