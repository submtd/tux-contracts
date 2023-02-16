// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tux is BaseContract, ERC20
{
    constructor() ERC20("Tux", "TUX") {}

    /**
     * Mint function.
     * @param receiver_ Address to mint to.
     * @param amount_ Amount to mint.
     */
    function mint(address receiver_, uint256 amount_) external onlyOwner
    {
        _mint(receiver_, amount_);
    }
}
