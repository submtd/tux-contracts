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
    IInvestorVault public investorVault;
    IUniswapV2Router02 public router;
    IERC20 public usdc;
    IERC20 public tux;

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

    /**
     * Setup.
     */
    function setup() external override
    {
        charityReceiver = addressBook.get("charityVault");
        collateralReceiver = addressBook.get("collateralVault");
        devReceiver = addressBook.get("devVault");
        investorReceiver = addressBook.get("investorVault");
        rewardsReceiver = addressBook.get("staking");
        investorVault = IInvestorVault(investorReceiver);
        router = IUniswapV2Router02(addressBook.get("router"));
        usdc = IERC20(addressBook.get("usdc"));
        tux = IERC20(addressBook.get("tux"));
    }

    /**
     * Distribute taxes.
     */
    function distribute() external
    {
        // Sell TUX
        address[] memory _path_ = new address[](2);
        _path_[0] = addressBook.get("tux");
        _path_[1] = addressBook.get("usdc");
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tux.balanceOf(address(this)),
            0,
            _path_,
            address(this),
            block.timestamp
        );
        // Get USDC balance.
        uint256 _usdcBalance_ = usdc.balanceOf(address(this));
        totalDistributed += _usdcBalance_;
        // Distribute taxes to charity.
        uint256 _charityTax_ = _usdcBalance_ * charityTax / 10000;
        usdc.transfer(charityReceiver, _charityTax_);
        // Distribute taxes to the dev wallet.
        uint256 _devTax_ = _usdcBalance_ * devTax / 10000;
        usdc.transfer(devReceiver, _devTax_);
        // Distribute taxes to the investor vault if applicable.
        uint256 _investorTax_ = 0;
        uint256 _investorOutstanding_ = investorVault.totalOutstanding();
        if(_investorOutstanding_ > 0)
        {
            _investorTax_ = _usdcBalance_ * investorTax / 10000;
            if(_investorTax_ > _investorOutstanding_) _investorTax_ = _investorOutstanding_;
        }
        if(_investorTax_ > 0) usdc.transfer(investorReceiver, _investorTax_);
        // Transfer remaining to rewards and collateral.
        uint256 _remainingBalance_ = _usdcBalance_ - _charityTax_ - _devTax_ - _investorTax_;
        uint256 _collateralTax_ = _remainingBalance_ / 2;
        usdc.transfer(collateralReceiver, _collateralTax_);
        usdc.transfer(rewardsReceiver, _remainingBalance_ - _collateralTax_);
    }
}
