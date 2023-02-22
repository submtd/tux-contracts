// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Tux is BaseContract, ERC20
{
    constructor() ERC20("Tux", "TUX") {}

    /**
     * External contracts.
     */
    address private _pair;
    address private _taxHandler;
    address private _deployLiquidity;
    address private _staking;

    /**
     * Properties.
     */
    uint256 tax = 500; // 5%
    mapping(address => bool) private _taxExempt;

    /**
     * Setup.
     */
    function setup() external override
    {
        IUniswapV2Factory _factory_ = IUniswapV2Factory(addressBook.get("Factory"));
        _pair = _factory_.getPair(addressBook.get("Usdc"), address(this));
        _taxHandler = addressBook.get("TaxHandler");
        _deployLiquidity = addressBook.get("DeployLiquidity");
        _staking = addressBook.get("Staking");
        _taxExempt[address(this)] = true;
        _taxExempt[_taxHandler] = true;
        _taxExempt[_deployLiquidity] = true;
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
        // If to or from is tax exempt, just transfer.
        if (_taxExempt[from_] || _taxExempt[to_]) return super._transfer(from_, to_, amount_);
        // Otherwise, tax it.
        uint256 taxAmount_ = amount_ * tax / 10000;
        uint256 sendAmount_ = amount_ - taxAmount_;
        super._transfer(from_, _taxHandler, taxAmount_);
        super._transfer(from_, to_, sendAmount_);
    }

    /**
     * Transfer from.
     * @param from_ Address to transfer from.
     * @param to_ Address to transfer to.
     * @param amount_ Amount to transfer.
     * @return bool True if successful.
     * @dev Allow staking contract to transfer from.
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public override returns (bool) {
        if(msg.sender != _staking) return super.transferFrom(from_, to_, amount_);
        super._transfer(from_, to_, amount_);
        return true;
    }
}
