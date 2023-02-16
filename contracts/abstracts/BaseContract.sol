// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/IAddressBook.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseContract is Ownable
{
    /**
     * Address book.
     */
    IAddressBook public addressBook;

    /**
     * Set address book.
     * @param address_ Address book.
     */
    function setAddressBook(address address_) external onlyOwner
    {
        addressBook = IAddressBook(address_);
    }
}
