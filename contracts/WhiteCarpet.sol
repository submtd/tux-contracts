// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Interfaces.
import "./interfaces/ICronable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

error ONLY_STAKING_NFT_ALLOWED();
error INVALID_STAKE_AMOUNT();
error TOKEN_ALREADY_STAKING();
error NO_DIVIDENDS_AVAILABLE();

contract WhiteCarpet is BaseContract, ICronable
{
    using SafeERC20 for IERC20Metadata;

    /**
     * Staking token data.
     */
    IERC20Metadata private _stakingToken;
    uint256 private _stakingTokenDecimals;

    /**
     * NFT contract
     */
    address private _stakingNft;

    /**
     * Global Stats.
     */
    uint256 private _totalStaked;
    uint256 private _unclaimed;
    uint256 private _lastDistribution;
    mapping(uint256 => uint256) _dividendsByDayPerShare;

    /**
     * Stakes.
     */
    mapping(uint256 => uint256) private _stakeAmount;
    mapping(uint256 => uint256) private _lastAction;

    /**
     * Setup.
     */
    function setup() external override
    {
        _stakingToken = IERC20Metadata(addressBook.get("Tux"));
        _stakingTokenDecimals = _stakingToken.decimals();
        _stakingNft = addressBook.get("Staking");
        _lastDistribution = _getStartOfDay(block.timestamp);
    }

    /**
     * Get start of day.
     * @param _timestamp Timestamp to get start of day for.
     * @return uint256 Start of day.
     */
    function _getStartOfDay(uint256 _timestamp) private view returns (uint256)
    {
        return _timestamp / 1 days * 1 days;
    }

    /**
     * Available dividends.
     * @param tokenId_ Token ID to get available dividends for.
     * @return uint256 Available dividends.
     */
    function _availableDividends(uint256 tokenId_) private view returns (uint256)
    {
        uint256 _today_ = _getStartOfDay(block.timestamp);
        if(_stakeAmount[tokenId_] == 0) return 0;
        uint256 _daysSinceLastAction_ = (_today_ - _lastAction[tokenId_]) / 1 days;
        if(_daysSinceLastAction_ == 0) return 0;
        uint256 _available_;
        for(uint8 i = 1; i <= _daysSinceLastAction_; i++)
        {
            uint256 _day_ = _today_ - i * 1 days;
            if(_dividendsByDayPerShare[_day_] == 0) continue;
            _available_ += _stakeAmount[tokenId_] * _dividendsByDayPerShare[_day_] / _stakingTokenDecimals;
        }
        return _available_;
    }

    /**
     * Stake.
     * @param tokenId_ Token ID to stake.
     * @param amount_ Amount to stake.
     */
    function stake(uint256 tokenId_, uint256 amount_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        if(amount_ == 0) revert INVALID_STAKE_AMOUNT();
        if(_stakeAmount[tokenId_] > 0) revert TOKEN_ALREADY_STAKING();
        _totalStaked += amount_;
        _stakeAmount[tokenId_] += amount_;
        _lastAction[tokenId_] = _getStartOfDay(block.timestamp);
    }

    /**
     * Unstake.
     * @param tokenId_ Token ID to unstake.
     * @param recipient_ Recipient to send TUX to.
     */
    function unstake(uint256 tokenId_, address recipient_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        if(_stakeAmount[tokenId_] == 0) revert INVALID_STAKE_AMOUNT();
        uint256 _amount_ = _stakeAmount[tokenId_];
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        _totalStaked -= _amount_;
        _unclaimed -= _availableDividends_;
        delete _stakeAmount[tokenId_];
        delete _lastAction[tokenId_];
        _stakingToken.safeTransfer(recipient_, _amount_ + _availableDividends_);
    }

    /**
     * Compound.
     * @param tokenId_ Token ID to compound.
     */
    function compound(uint256 tokenId_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        if(_availableDividends_ == 0) revert NO_DIVIDENDS_AVAILABLE();
        _lastAction[tokenId_] = _getStartOfDay(block.timestamp);
        _unclaimed -= _availableDividends_;
        _stakeAmount[tokenId_] += _availableDividends_;
    }

    /**
     * Claim.
     * @param tokenId_ Token ID to claim.
     * @param recipient_ Recipient to send TUX to.
     */
    function claim(uint256 tokenId_, address recipient_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        uint256 _availableDividends_ = _availableDividends(tokenId_);
        if(_availableDividends_ == 0) revert NO_DIVIDENDS_AVAILABLE();
        _lastAction[tokenId_] = _getStartOfDay(block.timestamp);
        _unclaimed -= _availableDividends_;
        _stakingToken.safeTransfer(recipient_, _availableDividends_);
    }

    /**
     * Stake getter.
     * @param tokenId_ Token ID to get stake for.
     * @return stakeAmount Stake amount.
     * @return lastAction Last action.
     * @return availableDividends Available dividends.
     */
    function getStake(uint256 tokenId_) external view returns (uint256 stakeAmount, uint256 lastAction, uint256 availableDividends)
    {
        return (_stakeAmount[tokenId_], _lastAction[tokenId_], _availableDividends(tokenId_));
    }

    /**
     * Cron.
     */
    function cron() external
    {
        uint256 _today_ = _getStartOfDay(block.timestamp);
        if(_lastDistribution == _today_) return;
        _lastDistribution = _today_;
        uint256 _dividends_ = _stakingToken.balanceOf(address(this)) - _totalStaked - _unclaimed;
        _unclaimed += _dividends_;
        _dividendsByDayPerShare[_today_] = _dividends_ * _stakingTokenDecimals / _totalStaked;
    }
}
