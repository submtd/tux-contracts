// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Usdc is BaseContract, ERC20
{
    constructor() ERC20("USDC", "USDC") {}

    /**
     * Public mint function.
     * @param receiver_ Address to mint to.
     * @param amount_ Amount to mint.
     */
    function mintTo(address receiver_, uint256 amount_) external
    {
        _mint(receiver_, amount_);
    }

    /**
     * Mint without parameters.
     */
    function mint() external
    {
        _mint(msg.sender, 1000e18);
    }
}
