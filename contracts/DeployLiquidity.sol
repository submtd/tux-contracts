// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DeployLiquidity is BaseContract
{
    /**
     * Deploy.
     * @dev Creates the initial liquidity pool.
     */
    function deploy() external onlyOwner
    {
        IERC20 _usdc = IERC20(addressBook.get("Usdc"));
        IERC20 _tux = IERC20(addressBook.get("Tux"));
        IUniswapV2Router02 _router = IUniswapV2Router02(addressBook.get("Router"));
        _usdc.approve(address(_router), _usdc.balanceOf(address(this)));
        _tux.approve(address(_router), _tux.balanceOf(address(this)));
        _router.addLiquidity(
            address(_usdc),
            address(_tux),
            _usdc.balanceOf(address(this)),
            _tux.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}
