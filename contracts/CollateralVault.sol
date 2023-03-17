// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";

error COLLATERALVAULT_notSetup();
error COLLATERALVAULT_unauthorized();

contract CollateralVault is BaseContract
{
    /**
     * External contracts.
     */
    address private _staking;
    IERC20 private _usdc;

    /**
     * Setup.
     */
    function setup() external override
    {
        _staking = addressBook.get("Staking");
        _usdc = IERC20(addressBook.get("Usdc"));
    }

    /**
     * Withdraw.
     * @param _amount Amount to withdraw.
     */
    function withdraw(uint256 _amount) external
    {
        if(_staking == address(0)) revert COLLATERALVAULT_notSetup();
        if(msg.sender != _staking) revert COLLATERALVAULT_unauthorized();
        // Only ever transfer to the staking contract.
        _usdc.transfer(_staking, _amount);
    }
}
