// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract InvestorVault is BaseContract
{
    /**
     * External contracts.
     */
    IERC20 private usdc;
    IERC20 private tux;

    /**
     * Stats.
     */
    uint256 public totalInvested;
    uint256 public totalWithdrawn;

    /**
     * Total repaid.
     * @return uint256 Total repaid.
     */
    function totalRepaid() public view returns (uint256)
    {
        return usdc.balanceOf(address(this)) + totalWithdrawn;
    }

    /**
     * Total outstanding.
     * @return uint256 Total outstanding.
     */
    function totalOutstanding() external view returns (uint256)
    {
        return totalInvested - totalRepaid();
    }

    /**
     * Setup.
     */
    function setup() external override
    {
        usdc = IERC20(addressBook.get("usdc"));
        tux = IERC20(addressBook.get("tux"));
    }
}
