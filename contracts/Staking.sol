// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// Interfaces.
import "./interfaces/ICollateralVault.sol";
import "./interfaces/ITaxHandler.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
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
    IERC20Metadata private _tux;
    IERC20Metadata private _usdc;
    IUniswapV2Router02 private _router;
    ITaxHandler private _taxHandler;
    address private _marketplace;

    /**
     * Properties.
     */
    uint256 private _burnPercent = 75;
    uint256 private _transferTax = 5;
    uint256 public maxRcReward;
    uint8 private _usdcDecimals;
    uint8 private _tuxDecimals;
    uint256 private _updateInterval = 1 minutes;
    uint256 private _maxRcAge = 365 days;

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
    mapping(uint256 => uint256) private _rcRewardAvailable;

    /**
     * RC/WC data.
     */
    uint256 public totalWcStaked;
    uint256 public totalRcStaked;
    uint256 public totalDividends;
    uint256 private _dividendsPerShare;
    uint256 private _tuxRefunds;
    uint256 private _lastUpdate;
    uint256 private _lastUpdated;
    uint256 public rcRewarded;
    uint256 public rcClaimed;
    uint256 public rcPending;
    uint256 public lastRcRewarded;
    uint256 public lastRcEntered;
    uint256 private _nextToEnter = 1;
    uint256 private _nextToReward = 1;

    /**
     * Setup.
     */
    function setup() external override
    {
        _collateralVault = ICollateralVault(addressBook.get("CollateralVault"));
        _usdc = IERC20Metadata(addressBook.get("Usdc"));
        _tux = IERC20Metadata(addressBook.get("Tux"));
        _router = IUniswapV2Router02(addressBook.get("Router"));
        _taxHandler = ITaxHandler(addressBook.get("TaxHandler"));
        _marketplace = addressBook.get("Marketplace");
        _usdcDecimals = _usdc.decimals();
        _tuxDecimals = _tux.decimals();
        maxRcReward = 10000 * (10 ** _usdcDecimals);
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
                '{"trait_type": "stakeAmount", "value": "', _stakeAmount[tokenId_].toString(), '"},',
                '{"trait_type": "stakeAge", "value": "', _tokenAge(tokenId_).toString(), '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "stakeStart", "value": "', _stakeStart[tokenId_].toString(), '"},',
                '{"trait_type": "stakePrice", "value": "', _stakePrice[tokenId_].toString(), '"},',
                '{"trait_type": "startingStakeAmount", "value": "', _startingStakeAmount[tokenId_].toString(), '"},',
                '{"trait_type": "availableDividends", "value": "', _availableDividends(tokenId_).toString(), '"},'
                '{"trait_type": "dividendsCompounded", "value": "', _dividendsCompounded[tokenId_].toString(), '"},'
            ),
            abi.encodePacked(
                '{"trait_type": "dividendsClaimed", "value": "', _dividendsClaimed[tokenId_].toString(), '"},',
                '{"trait_type": "dividendDebt", "value": "', _dividendDebt[tokenId_].toString(), '"},',
                '{"trait_type": "tuxRefundAvailable", "value": "', _tuxRefundAvailable[tokenId_].toString(), '"},',
                '{"trait_type": "rcValue", "value": "', _tokenUsdcValue(tokenId_).toString(), '"},'
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
        uint256 _value_ = _stakeAmount[tokenId_] * _stakePrice[tokenId_] / (10 ** _tuxDecimals);
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
        _dividendDebt[_tokenIdTracker] = (amount_ * _dividendsPerShare) / (10 ** _tuxDecimals);
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
        totalWcStaked += _availableDividends_;
        _dividendsCompounded[tokenId_] += _availableDividends_;
        _stakeAmount[tokenId_] += _availableDividends_;
        _dividendDebt[tokenId_] = (_stakeAmount[tokenId_] * _dividendsPerShare) / (10 ** _tuxDecimals);
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
        if(_lastUpdated == 0) {
            _taxHandler.distribute();
        }
        if(_lastUpdated == 1) {
            _updateWcRewards();
        }
        if(_lastUpdated == 2) {
            _addNextWcToRc();
        }
        if(_lastUpdated == 3) {
            _rewardNextRc();
        }
        _lastUpdated = (_lastUpdated + 1) % 4;
    }

    /**
     * Update WC rewards.
     * @dev This functions distributes TUX tokens to WC stakers.
     */
    function _updateWcRewards() public
    {
        // New rewards will be the number of extra TUX in the contract.
        uint256 _newRewards_ = _tux.balanceOf(address(this)) - totalWcStaked - _tuxRefunds;
        if(_newRewards_ <= 0) return;
        totalDividends += _newRewards_;
        // Calculate dividends per share.
        _dividendsPerShare += (_newRewards_ * (10 ** _tuxDecimals)) / totalWcStaked;
    }

    /**
     * Reward next RC.
     */
    function _rewardNextRc() public
    {
        if(_stakeType[_nextToReward] != 2) {
            if(_stakeType[_nextToReward] == 3) _nextToReward++;
            return;
        }
        // Get USDC balance and calculate what the new rewards are.
        uint256 _usdcBalance_ = _usdc.balanceOf(address(this));
        uint256 _available_ = _usdcBalance_ - (rcRewarded - rcClaimed);
        uint256 _tokenValue_ = _tokenUsdcValue(_nextToReward);
        // If there is not enough rewards, or the token hasn't reached 365 days yet, return.
        if(_tokenValue_ > _available_) {
            return;
            //if(_tokenAge(_nextToReward) < 365 days) return;
            // If the token is 365 days old, withdraw from the collateral vault.
            //_collateralVault.withdraw(_tokenValue_ - _available_);
        }
        // Update the total rc rewarded.
        rcRewarded += _tokenValue_;
        // Subtrack rewards from available.
        _available_ -= _tokenValue_;
        // Subtract rewards from the pending amount.
        rcPending -= _tokenValue_;
        // Update the last RC rewarded.
        lastRcRewarded = _nextToReward;
        // Update the token data.
        _rcRewardAvailable[_nextToReward] = _tokenValue_;
        // Increment next to reward.
        _nextToReward++;
    }

    /**
     * Add next WC to RC.
     */
    function _addNextWcToRc() public
    {
        // If next is > than latest token ID, return.
        if(_nextToEnter > _tokenIdTracker) return;
        // If next is not WC, return.
        if(_stakeType[_nextToEnter] != 1) {
            _nextToEnter++;
            return;
        }
        // Get collateral vault balance.
        uint256 _collateralBalance_ = _usdc.balanceOf(address(_collateralVault));
        // If there is not enough collateral, return.
        if(rcPending >= _collateralBalance_) return;
        // Calculate available collateral.
        uint256 _available_ = _collateralBalance_ - rcPending;
        // Calculate token value.
        uint256 _tokenValue_ = _stakeAmount[_nextToEnter] * _stakePrice[_nextToEnter] / (10 ** _usdcDecimals);
        // If value is greater than max RC reward, set value to max RC reward and calculate the TUX refund.
        uint256 _tuxRefund_;
        if(_tokenValue_ > maxRcReward) {
            _tokenValue_ = maxRcReward;
            _tuxRefund_ = _stakeAmount[_nextToEnter] - (maxRcReward * (10 ** _usdcDecimals) / _stakePrice[_nextToEnter]);
        }
        // If token value is greater than available collateral, return.
        if(_tokenValue_ > _available_) return;
        // Update last RC entered.
        lastRcEntered = _nextToEnter;
        // Update RC pending.
        rcPending += _tokenValue_;
        // Update stake start time.
        _stakeStart[_nextToEnter] = block.timestamp;
        // Burn TUX.
        _tux.transfer(deadAddress, _stakeAmount[_nextToEnter] * _burnPercent / 100);
        // Update stake data.
        totalWcStaked -= _stakeAmount[_nextToEnter];
        _tuxRefunds += _tuxRefund_;
        _tuxRefundAvailable[_nextToEnter] = _tuxRefund_;
        _stakeType[_nextToEnter] = 2;
        // Increment next to enter.
        _nextToEnter++;
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
        return ((_stakeAmount[tokenId_] * _dividendsPerShare) / (10 ** _tuxDecimals)) - _dividendDebt[tokenId_];
    }

    /**
     * Current TUX price.
     * @return uint256 Price.
     */
    function currentTuxPrice() external view returns (uint256)
    {
        return _currentTuxPrice();
    }

    /**
     * Current TUX price internal.
     * @return uint256 Price.
     */
    function _currentTuxPrice() internal view returns (uint256)
    {
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_tux);
        _path_[1] = address(_usdc);
        return _router.getAmountsOut((10 ** _tuxDecimals), _path_)[1];
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
        //if(to_ == _marketplace || from_ == _marketplace) return;
        // Update values.
        //uint256 _stakeTax_ = _stakeAmount[tokenId_] * _transferTax / 100;
        //_stakeAmount[tokenId_] -= _stakeTax_;
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

    /**
     * Set update interval.
     * @param updateInterval_ Update interval.
     */
    function setUpdateInterval(uint256 updateInterval_) public onlyOwner
    {
        _updateInterval = updateInterval_;
    }

    /**
     * Set max RC age.
     * @param maxRcAge_ Max RC age.
     */
    function setMaxRcAge(uint256 maxRcAge_) public onlyOwner
    {
        _maxRcAge = maxRcAge_;
    }
}
