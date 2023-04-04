// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// Interfaces.
import "./interfaces/ICollateralVault.sol";
import "./interfaces/ICronable.sol";
import "./interfaces/ICollateralVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

error ONLY_STAKING_NFT_ALLOWED();

contract RedCarpet is BaseContract, ICronable
{
    using SafeERC20 for IERC20Metadata;

    /**
     * External contracts.
     */
    address private _stakingNft;
    ICollateralVault private _collateralVault;
    IERC20Metadata private _paymentToken;

    /**
     * Properties.
     */
    uint256 private _maxStakeAge = 365 days;

    /**
     * Stats.
     */
    struct Stats {
        uint256 entered;
        uint256 rewarded;
        uint256 redeemed;
        uint256 lastEntered;
        uint256 lastRewarded;
        uint256 lastRedeemed;
    }
    Stats private _stats;

    /**
     * Stakes.
     */
    mapping(uint256 => uint256) private _value;
    mapping(uint256 => uint256) private _entryDate;
    mapping(uint256 => uint256) private _rewardDate;
    mapping(uint256 => uint256) private _redeemDate;

    /**
     * Setup.
     */
    function setup() external override
    {
        _stakingNft = addressBook.get("Staking");
        _collateralVault = ICollateralVault(addressBook.get("CollateralVault"));
        _paymentToken = IERC20Metadata(addressBook.get("Usdc"));
    }

    /**
     * Get stats.
     * @return Stats Contract stats.
     */
    function getStats() external view returns (Stats memory)
    {
        return _stats;
    }

    /**
     * Enter.
     * @param tokenId_ Token ID.
     * @param amount_ Amount to enter.
     */
    function enter(uint256 tokenId_, uint256 amount_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        _value[tokenId_] = amount_;
        _entryDate[tokenId_] = block.timestamp;
        //_stats.waiting += amount_;
    }

    /**
     * Redeem.
     * @param tokenId_ Token ID.
     */
    function redeem(uint256 tokenId_, address recipient_) external
    {
        if(msg.sender != _stakingNft) revert ONLY_STAKING_NFT_ALLOWED();
        uint256 _balance_ = _paymentToken.balanceOf(address(this));
        uint256 _value_ = _value[tokenId_];
        if(_balance_ < _value_) _collateralVault.withdraw(_value_ - _balance_);
        delete _value[tokenId_];
        delete _entryDate[tokenId_];
        //_pending -= _value_;
        //_redeemed += _value_;
        //_lastRedeemed = tokenId_;
        _paymentToken.safeTransfer(recipient_, _value_);
    }

    /**
     * Cron.
     */
    function cron() external
    {}
}
