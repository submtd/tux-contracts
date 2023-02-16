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
        IERC20 usdc = IERC20(addressBook.get("usdc"));
        IERC20 tux = IERC20(addressBook.get("tux"));
        IUniswapV2Router02 router = IUniswapV2Router02(addressBook.get("router"));
        usdc.approve(address(router), usdc.balanceOf(address(this)));
        tux.approve(address(router), tux.balanceOf(address(this)));
        router.addLiquidity(
            address(usdc),
            address(tux),
            usdc.balanceOf(address(this)),
            tux.balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );
    }
}
