// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAddressBook {
    function get ( string memory name_ ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function set ( string memory name_, address address_ ) external;
    function transferOwnership ( address newOwner ) external;
    function unset ( string memory name_ ) external;
}
