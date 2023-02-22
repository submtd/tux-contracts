// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "./interfaces/IInvestorVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TaxHandler is BaseContract
{
    /**
     * External addresses.
     */
    address public charityReceiver;
    address public collateralReceiver;
    address public devReceiver;
    address public investorReceiver;
    address public rewardsReceiver;

    /**
     * External contracts.
     */
    IInvestorVault private _investorVault;
    IUniswapV2Router02 private _router;
    IERC20 private _usdc;
    IERC20 private _tux;

    /**
     * Taxes.
     */
    uint256 public charityTax = 2000;
    uint256 public devTax = 2000;
    uint256 public investorTax = 2000;
    // remaining gets split evenly between rewards and collateral

    /**
     * Stats.
     */
    uint256 public totalDistributed;
    uint256 public lastDistributed;

    /**
     * Setup.
     */
    function setup() external override
    {
        charityReceiver = addressBook.get("CharityVault");
        collateralReceiver = addressBook.get("CollateralVault");
        devReceiver = addressBook.get("DevVault");
        investorReceiver = addressBook.get("InvestorVault");
        rewardsReceiver = addressBook.get("Staking");
        _investorVault = IInvestorVault(investorReceiver);
        _router = IUniswapV2Router02(addressBook.get("Router"));
        _usdc = IERC20(addressBook.get("Usdc"));
        _tux = IERC20(addressBook.get("Tux"));
    }

    /**
     * Distribute taxes.
     */
    function distribute() external
    {
        if(block.timestamp - lastDistributed < 1 hours) return;
        lastDistributed = (block.timestamp / 1 hours) * 1 hours;
        // Sell TUX
        uint256 _tuxBalance_ = _tux.balanceOf(address(this));
        if(_tuxBalance_ <= 0) return;
        _tux.approve(address(_router), _tuxBalance_);
        address[] memory _path_ = new address[](2);
        _path_[0] = address(_tux);
        _path_[1] = address(_usdc);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _tuxBalance_,
            0,
            _path_,
            address(this),
            block.timestamp
        );
        // Get USDC balance.
        uint256 _usdcBalance_ = _usdc.balanceOf(address(this));
        totalDistributed += _usdcBalance_;
        // Distribute taxes to charity.
        uint256 _charityTax_ = _usdcBalance_ * charityTax / 10000;
        _usdc.transfer(charityReceiver, _charityTax_);
        // Distribute taxes to the dev wallet.
        uint256 _devTax_ = _usdcBalance_ * devTax / 10000;
        _usdc.transfer(devReceiver, _devTax_);
        // Distribute taxes to the investor vault if applicable.
        uint256 _investorTax_ = 0;
        uint256 _investorOutstanding_ = _investorVault.totalOutstanding();
        if(_investorOutstanding_ > 0)
        {
            _investorTax_ = _usdcBalance_ * investorTax / 10000;
            if(_investorTax_ > _investorOutstanding_) _investorTax_ = _investorOutstanding_;
        }
        if(_investorTax_ > 0) _usdc.transfer(investorReceiver, _investorTax_);
        // Transfer remaining to rewards and collateral.
        uint256 _remainingBalance_ = _usdcBalance_ - _charityTax_ - _devTax_ - _investorTax_;
        uint256 _collateralTax_ = _remainingBalance_ / 2;
        _usdc.transfer(collateralReceiver, _collateralTax_);
        _usdc.transfer(rewardsReceiver, _remainingBalance_ - _collateralTax_);
    }
}
