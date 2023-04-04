// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../interfaces/ICronable.sol";

contract MockCronJob is ICronable {
    uint256 public callCount;

    constructor() {
        callCount = 0;
    }

    function cron() external override {
        callCount += 1;
    }
}
