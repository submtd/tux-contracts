// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";

contract AddressBook is BaseContract
{
    /**
     * Address book mapping.
     */
    mapping(string => address) private _addresses;

    /**
     * Set address.
     * @param name_ Address name.
     * @param address_ Address.
     * @dev Stores an address in the address book.
     */
    function set(string memory name_, address address_) external onlyOwner
    {
        _addresses[name_] = address_;
    }

    /**
     * Unset address.
     * @param name_ Address name.
     * @dev Removes an address from the address book.
     */
    function unset(string memory name_) external onlyOwner
    {
        delete _addresses[name_];
    }

    /**
     * Get address.
     * @param name_ Address name.
     * @return address Address.
     * @dev Returns an address stored in the address book.
     */
    function get(string memory name_) external view returns (address)
    {
        return _addresses[name_];
    }
}
