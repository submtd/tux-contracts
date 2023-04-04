// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Interfaces.
import "./interfaces/ITaxHandler.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Tux is BaseContract, ERC20
{
    constructor() ERC20("Tux", "TUX") {}

    /**
     * External contracts.
     */
    address private _pair;
    ITaxHandler private _taxHandler;
    address private _deployLiquidity;
    address private _staking;

    /**
     * Properties.
     */
    uint256 public tax = 500; // 5%
    uint256 private _lastTaxDistribution;
    uint256 private _taxDistributionInterval = 10 minutes;

    /**
     * Setup.
     */
    function setup() external override
    {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("Factory"));
        _pair = _factory_.getPair(addressBook.get("Usdc"), address(this));
        _taxHandler = ITaxHandler(addressBook.get("TaxHandler"));
        _deployLiquidity = addressBook.get("DeployLiquidity");
        _staking = addressBook.get("Staking");
    }

    /**
     * Mint function.
     * @param receiver_ Address to mint to.
     * @param amount_ Amount to mint.
     */
    function mint(address receiver_, uint256 amount_) external onlyOwner
    {
        _mint(receiver_, amount_);
    }

    /**
     * Transfer override.
     * @param from_ Address to transfer from.
     * @param to_ Address to transfer to.
     * @param amount_ Amount to transfer.
     * @dev Determine if it's a buy or sell, and tax accordingly.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 amount_
    ) internal override {
        // If it's not a buy or sell, just transfer.
        if (to_ != _pair && from_ != _pair) return super._transfer(from_, to_, amount_);
        // If it's a transfer to or from TaxHandler, just transfer.
        if (to_ == address(_taxHandler) || from_ == address(_taxHandler)) return super._transfer(from_, to_, amount_);
        // If it's a transfer to or from DeployLiquidity, just transfer.
        if (to_ == _deployLiquidity || from_ == _deployLiquidity) return super._transfer(from_, to_, amount_);
        // Otherwise, tax it.
        uint256 taxAmount_ = amount_ * tax / 10000;
        uint256 sendAmount_ = amount_ - taxAmount_;
        super._transfer(from_, address(_taxHandler), taxAmount_);
        // Finally, transfer the amount.
        super._transfer(from_, to_, sendAmount_);
    }
}
