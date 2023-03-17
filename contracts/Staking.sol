// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "./interfaces/ICollateralVault.sol";
import "./interfaces/ITaxHandler.sol";
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

    using Strings for uint256;

    address constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    /**
     * External contracts.
     */
    ICollateralVault private _collateralVault;
    IERC20 private _tux;
    IERC20 private _usdc;
    IUniswapV2Router02 private _router;
    ITaxHandler private _taxHandler;

    /**
     * Properties.
     */
    uint256 private _burnPercent = 75;
    uint256 private _transferTax = 5;
    uint256 public maxRcReward = 10000e18;

    /**
     * Token data.
     */
    uint256 private _tokenIdTracker;
    mapping(uint256 => uint256) private _stakeType;
    mapping(uint256 => uint256) private _stakeAmount;
    mapping(uint256 => uint256) private _stakeStart;
    mapping(uint256 => uint256) private _stakePrice;
    mapping(uint256 => uint256) private _startingStakeAmount;
    mapping(uint256 => uint256) private _dividendsCompounded;
    mapping(uint256 => uint256) private _dividendsClaimed;
    mapping(uint256 => uint256) private _dividendDebt;
    mapping(uint256 => uint256) private _tuxRefundAvailable;
    mapping(uint256 => uint256) private _rcValue;
    mapping(uint256 => uint256) private _rcRewardAvailable;

    /**
     * RC/WC data.
     */
    uint256 public totalWcStaked;
    uint256 public totalRcStaked;
    uint256 public totalDividends;
    uint256 private _dividendsPerShare;
    uint256 private _tuxRefunds;
    uint256 public lastUpdate;
    uint256 public rcRewarded;
    uint256 public rcClaimed;
    uint256 public rcPending;
    uint256 public lastRcRewarded;
    uint256 public lastRcEntered;

    /**
     * Setup.
     */
    function setup() external override
    {
        _collateralVault = ICollateralVault(addressBook.get("CollateralVault"));
        _usdc = IERC20(addressBook.get("Usdc"));
        _tux = IERC20(addressBook.get("Tux"));
        _router = IUniswapV2Router02(addressBook.get("Router"));
        _taxHandler = ITaxHandler(addressBook.get("TaxHandler"));
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
        bytes memory _meta_ = abi.encodePacked(
            '{',
            '"name": "Tux Staking #', tokenId_.toString(), '",',
            '"description": "Tux Staking",',
            '"image": "', _tokenImage(tokenId_), '",',
            '"attributes": [',
            abi.encodePacked(
                '{"trait_type": "id", "value": "', tokenId_.toString(), '"},',
                '{"trait_type": "stakeType", "value": "', _stakeType[tokenId_].toString(), '"},',
                '{"trait_type": "stakeTypeString", "value": "', _tokenTypeString(tokenId_), '"},',
                '{"trait_type": "stakeAmount", "value": "', _stakeAmount[tokenId_].toString(), '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "stakeStart", "value": "', _stakeStart[tokenId_].toString(), '"},',
                '{"trait_type": "stakePrice", "value": "', _stakePrice[tokenId_].toString(), '"},',
                '{"trait_type": "startingStakeAmount", "value": "', _startingStakeAmount[tokenId_].toString(), '"},',
                '{"trait_type": "dividendsCompounded", "value": "', _dividendsCompounded[tokenId_].toString(), '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "dividendsClaimed", "value": "', _dividendsClaimed[tokenId_].toString(), '"},',
                '{"trait_type": "dividendDebt", "value": "', _dividendDebt[tokenId_].toString(), '"},',
                '{"trait_type": "tuxRefundAvailable", "value": "', _tuxRefundAvailable[tokenId_].toString(), '"},',
                '{"trait_type": "rcValue", "value": "', _rcValue[tokenId_].toString(), '"},'
                '{"trait_type": "rcRewardAvailable", "value": "', _rcRewardAvailable[tokenId_].toString(), '"}'
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
     * Token type string internal.
     * @param tokenId_ Token ID.
     * @return string Token type.
     */
    function _tokenTypeString(uint256 tokenId_) internal view returns (string memory)
    {
        string memory _type_ = 'White Carpet';
        if(_stakeType[tokenId_] == 2) _type_ = 'Red Carpet';
        if(_stakeType[tokenId_] == 3) _type_ = 'Dead';
        return _type_;
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
     * Token TUX value internal.
     * @param tokenId_ Token ID.
     * @return uint256 Token value.
     */
    function _tokenTuxValue(uint256 tokenId_) internal view returns (uint256)
    {
        if(_stakeType[tokenId_] == 1) return _stakeAmount[tokenId_];
        return 0;
    }

    /**
     * Token USDC value internal.
     * @param tokenId_ Token ID.
     * @return uint256 Token value.
     */
    function _tokenUsdcValue(uint256 tokenId_) internal view returns (uint256)
    {
        if(_stakeType[tokenId_] == 3) return 0;
        uint256 _value_ = _stakeAmount[tokenId_] * _stakePrice[tokenId_] / 1e18;
        if(_value_ > maxRcReward) return maxRcReward;
        return _value_;
    }

    /**
     * Token age internal.
     * @param tokenId_ Token ID.
     * @return uint256 Token age.
     */
    function _tokenAge(uint256 tokenId_) internal view returns (uint256)
    {
        if(_stakeType[tokenId_] == 3) return 0;
        return block.timestamp - _stakeStart[tokenId_];
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
        _stakeType[_tokenIdTracker] = 1;
        _stakeAmount[_tokenIdTracker] = amount_;
        _startingStakeAmount[_tokenIdTracker] = amount_;
        _stakeStart[_tokenIdTracker] = block.timestamp;
        _stakePrice[_tokenIdTracker] = _currentTuxPrice();
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
        if(_stakeType[tokenId_] != 1) revert STAKING_invalidTokenId();
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
        if(_stakeType[tokenId_] != 1 && _stakeType[tokenId_] != 2) revert STAKING_invalidTokenId();
        if(ownerOf(tokenId_) != msg.sender) revert STAKING_invalidTokenId();
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        if(_availableDividends_ <= 0 && _tuxRefundAvailable[tokenId_] <= 0 && _rcRewardAvailable[tokenId_] <= 0) revert STAKING_noDividends();
        if(_availableDividends_ > 0) {
            _dividendDebt[tokenId_] += _availableDividends_;
            _dividendsClaimed[tokenId_] += _availableDividends_;
            if(!_tux.transfer(msg.sender, _availableDividends_)) revert STAKING_transferFailed();
        }
        if(_tuxRefundAvailable[tokenId_] > 0) {
            _tuxRefundAvailable[tokenId_] = 0;
            if(!_tux.transfer(msg.sender, _tuxRefundAvailable[tokenId_])) revert STAKING_transferFailed();
        }
        if(_rcRewardAvailable[tokenId_] > 0) {
            uint256 _stakeAmount_ = _stakeAmount[tokenId_];
            totalWcStaked -= _stakeAmount_;
            uint256 _rcReward_ = _rcRewardAvailable[tokenId_];
            rcClaimed += _rcReward_;
            rcPending -= _rcReward_;
            _killToken(tokenId_);
            if(!_usdc.transfer(msg.sender, _rcReward_)) revert STAKING_transferFailed();
        }
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
        if(_stakeType[tokenId_] != 1) revert STAKING_invalidTokenId();
        uint256 _stakeAmount_ = _stakeAmount[tokenId_];
        _killToken(tokenId_);
        totalWcStaked -= _stakeAmount_;
        if(!_tux.transfer(msg.sender, _stakeAmount_)) revert STAKING_transferFailed();
    }

    /**
     * Kill token.
     * @param tokenId_ Token ID.
     */
    function _killToken(uint256 tokenId_) internal
    {
        _stakeType[tokenId_] = 3;
        delete _stakeAmount[tokenId_];
        delete _stakeStart[tokenId_];
        delete _stakePrice[tokenId_];
        delete _startingStakeAmount[tokenId_];
        delete _dividendsCompounded[tokenId_];
        delete _dividendsClaimed[tokenId_];
        delete _dividendDebt[tokenId_];
        delete _tuxRefundAvailable[tokenId_];
        delete _rcValue[tokenId_];
        delete _rcRewardAvailable[tokenId_];
        _transfer(ownerOf(tokenId_), deadAddress, tokenId_);
    }

    /**
     * Update rewards.
     */
    function updateRewards() external
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
        _taxHandler.distribute();
        _updateWcRewards();
        _updateLastRcRewarded();
        _updateLastRcEntered();
    }

    /**
     * Update WC rewards.
     * @dev This functions distributes TUX tokens to WC stakers.
     */
    function _updateWcRewards() internal
    {
        // New rewards will be the number of extra TUX in the contract.
        uint256 _newRewards_ = _tux.balanceOf(address(this)) - totalWcStaked - _tuxRefunds;
        if(_newRewards_ <= 0) return;
        totalDividends += _newRewards_;
        // Calculate dividends per share.
        _dividendsPerShare += (_newRewards_ * 1e18) / totalWcStaked;
    }

    /**
     * Update last RC rewarded.
     * @dev This function calculates new rewards that are ready to be claimed
     *      and updates the last RC rewarded.
     */
    function _updateLastRcRewarded() internal
    {
        // Get USDC balance and calculate what the new rewards are.
        uint256 _usdcBalance_ = _usdc.balanceOf(address(this));
        uint256 _available_ = _usdcBalance_ - (rcRewarded - rcClaimed);
        // Loop through RC stakes and reward any that are ready.
        for(uint256 i = lastRcRewarded + 1; i <= lastRcEntered; i ++) {
            if(_stakeType[i] != 2) continue;
            uint256 _tokenValue_ = _rcValue[i];
            // If there is not enough rewards, or the token hasn't reached 365 days yet, return.
            if(_tokenValue_ > _available_ && _tokenAge(i) < 365 days) return;
            // Update the total rc rewarded.
            rcRewarded += _tokenValue_;
            // Subtrack rewards from available.
            _available_ -= _tokenValue_;
            // Subtract rewards from the pending amount.
            rcPending -= _tokenValue_;
            // Update the last RC rewarded.
            lastRcRewarded = i;
            // Update the token data.
            _rcRewardAvailable[i] = _tokenValue_;
        }
    }

    /**
     * Update last RC entered.
     * @dev This function gets the available collateral and converts
     *      WC stakes into RC stakes until there is not enough collateral.
     */
    function _updateLastRcEntered() internal
    {
        // Get collateral vault balance.
        uint256 _collateralBalance_ = _usdc.balanceOf(address(_collateralVault));
        // If there is not enough collateral, return.
        if(rcPending >= _collateralBalance_) return;
        // Calculate available collateral.
        uint256 _available_ = _collateralBalance_ - rcPending;
        // Loop through the next WC stakes and see if they fit in the available collateral.
        for(uint256 i = lastRcEntered + 1; i <= _tokenIdTracker; i ++) {
            if(_stakeType[i] != 1) continue;
            uint256 _tokenValue_ = _stakeAmount[i] * _stakePrice[i] / 1e18;
            // If value is greater than max RC reward, set value to max RC reward and calculate the TUX refund.
            uint256 _tuxRefund_;
            if(_tokenValue_ > maxRcReward) {
                _tokenValue_ = maxRcReward;
                _tuxRefund_ = _stakeAmount[i] - (maxRcReward * 1e18 / _stakePrice[i]);
            }
            if(_tokenValue_ > _available_) break;
            // Subtract value from available.
            _available_ -= _tokenValue_;
            // Update last RC entered.
            lastRcEntered = i;
            // Update RC pending.
            rcPending += _tokenValue_;
            // Burn TUX.
            _tux.transfer(deadAddress, _stakeAmount[i] * _burnPercent / 100);
            // Update stake data.
            totalWcStaked -= _stakeAmount[i];
            _tuxRefunds += _tuxRefund_;
            _stakeAmount[i] = 0;
            _rcValue[i] = _tokenValue_;
            _tuxRefundAvailable[i] = _tuxRefund_;
            _stakeType[i] = 2;
        }
    }

    /**
     * Available dividends.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function availableDividends(uint256 tokenId_) public view returns (uint256)
    {
        return _availableDividends(tokenId_);
    }

    /**
     * Available dividends internal.
     * @param tokenId_ Token ID.
     * @return uint256 Available dividends.
     */
    function _availableDividends(uint256 tokenId_) internal view returns (uint256)
    {
        if(_stakeType[tokenId_] != 1) return 0;
        if(_stakeAmount[tokenId_] == 0) return 0;
        return ((_stakeAmount[tokenId_] * _dividendsPerShare) / 1e18) - _dividendDebt[tokenId_];
    }

    /**
     * Current TUX price.
     * @return uint256 Price.
     */
    function _currentTuxPrice() internal view returns (uint256)
    {
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_tux);
        _path_[1] = address(_usdc);
        return _router.getAmountsOut(1e18, _path_)[1];
    }

    /**
     * Internal transfer override to update values.
     * @param from_ From address.
     * @param to_ To address.
     * @param tokenId_ Token ID.
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal override
    {
        super._transfer(from_, to_, tokenId_);
        // Update values.
        uint256 _stakeTax_ = _stakeAmount[tokenId_] * _transferTax / 100;
        _stakeAmount[tokenId_] -= _stakeTax_;
        uint256 _rcTax_ = _rcValue[tokenId_] * _transferTax / 100;
        _rcValue[tokenId_] -= _rcTax_;
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Set burn percent.
     * @param burnPercent_ Burn percent.
     */
    function setBurnPercent(uint256 burnPercent_) public onlyOwner
    {
        _burnPercent = burnPercent_;
    }

    /**
     * Set transfer tax.
     * @param transferTax_ Transfer tax.
     */
    function setTransferTax(uint256 transferTax_) public onlyOwner
    {
        _transferTax = transferTax_;
    }

    /**
     * Set max RC reward.
     * @param maxRcReward_ Max RC reward.
     */
    function setMaxRcReward(uint256 maxRcReward_) public onlyOwner
    {
        maxRcReward = maxRcReward_;
    }
}
