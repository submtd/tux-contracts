// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICronable {
    function cron ( uint256 index_ ) external;
}
