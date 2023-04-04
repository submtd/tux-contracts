// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICron {
    struct Task {
        address externalContract;
        uint256 interval;
        uint256 offset;
        uint256 lastRun;
    }
    function addTask ( address externalContract_, uint256 interval_, uint256 offset_ ) external;
    function addressBook (  ) external view returns ( address );
    function getTask ( uint256 taskId_ ) external view returns ( Task memory );
    function owner (  ) external view returns ( address );
    function removeTask ( uint256 taskId_ ) external;
    function renounceOwnership (  ) external;
    function run (  ) external;
    function setAddressBook ( address address_ ) external;
    function setup (  ) external;
    function transferOwnership ( address newOwner ) external;
    function updateTask ( uint256 taskId_, address externalContract_, uint256 interval_, uint256 offset_ ) external;
}
