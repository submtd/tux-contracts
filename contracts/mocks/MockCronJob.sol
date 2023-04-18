// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MockCronJob
{
    uint256 public callCount;

    constructor() {
        callCount = 0;
    }

    function cron() external {
        callCount += 1;
    }
}
