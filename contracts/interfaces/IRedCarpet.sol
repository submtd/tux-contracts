// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRedCarpet {
    function addressBook (  ) external view returns ( address );
    function distribute (  ) external;
    function owner (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function transferOwnership ( address newOwner ) external;
}
