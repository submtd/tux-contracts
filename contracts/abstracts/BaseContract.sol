// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IAddressBook.sol";
import "../interfaces/ICron.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseContract is Ownable
{
    /**
     * Address book.
     */
    IAddressBook public addressBook;

    /**
     * Cron.
     */
    ICron private _cron;

    /**
     * Set address book.
     * @param address_ Address book.
     */
    function setAddressBook(address address_) external onlyOwner
    {
        addressBook = IAddressBook(address_);
        _cron = ICron(addressBook.get("Cron"));
    }

    /**
     * Setup.
     * @dev This runs setup tasks. It's public and should not be destructive.
     */
    function setup() external virtual {}

    /**
     * Run cron modifier.
     */
    modifier runCron()
    {
        if(address(_cron) != address(0)) address(_cron).call(abi.encodePacked(_cron.run.selector));
        _;
    }
}
