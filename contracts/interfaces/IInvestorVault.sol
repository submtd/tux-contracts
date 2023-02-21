// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IInvestorVault {
    function addressBook (  ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function totalInvested (  ) external view returns ( uint256 );
    function totalOutstanding (  ) external view returns ( uint256 );
    function totalRepaid (  ) external view returns ( uint256 );
    function totalWithdrawn (  ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
}
