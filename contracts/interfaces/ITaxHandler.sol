// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITaxHandler {
    function addressBook (  ) external view returns ( address );
    function charityReceiver (  ) external view returns ( address );
    function charityTax (  ) external view returns ( uint256 );
    function collateralReceiver (  ) external view returns ( address );
    function devReceiver (  ) external view returns ( address );
    function devTax (  ) external view returns ( uint256 );
    function distribute (  ) external;
    function investorReceiver (  ) external view returns ( address );
    function investorTax (  ) external view returns ( uint256 );
    function investorVault (  ) external view returns ( address );
    function owner (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function rewardsReceiver (  ) external view returns ( address );
    function router (  ) external view returns ( address );
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function totalDistributed (  ) external view returns ( uint256 );
    function transferOwnership ( address newOwner ) external;
    function tux (  ) external view returns ( address );
    function usdc (  ) external view returns ( address );
}
