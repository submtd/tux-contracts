// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";
import "./interfaces/ICronable.sol";

contract Cron is BaseContract
{
    struct Task {
        ICronable externalContract;
        uint256 interval;
        uint256 offset;
        uint256 last;
    }

    uint256 private _taskIdTracker;
    mapping(uint256 => Task) private _tasks;

    event taskAdded(uint256 indexed taskId, address indexed externalContract, uint256 interval, uint256 offset);
    event taskRemoved(uint256 indexed taskId);
    event taskUpdated(uint256 indexed taskId, address indexed externalContract, uint256 interval, uint256 offset);
    event taskRun(uint256 indexed taskId, address indexed externalContract);

    /**
     * Setup.
     */
    function setup() external override
    {
        //addTask(addressBook.get("TaxHandler"), 10 minutes, 2);
        //addTask(addressBook.get("WhiteCarpet"), 1 days, 1);
        //addTask(addressBook.get("RedCarpet"), 10 minutes, 4);
    }

    /**
     * Add task.
     * @param externalContract_ The external contract.
     * @param interval_ The interval.
     * @param offset_ The offset.
     */
    function addTask(address externalContract_, uint256 interval_, uint256 offset_) public onlyOwner
    {
        _taskIdTracker++;
        _tasks[_taskIdTracker] = Task({
            externalContract: ICronable(externalContract_),
            interval: interval_,
            offset: offset_,
            last: 0
        });
        emit taskAdded(_taskIdTracker, externalContract_, interval_, offset_);
    }

    /**
     * Get task.
     * @param taskId_ The task id.
     */
    function getTask(uint256 taskId_) external view returns (Task memory)
    {
        return _tasks[taskId_];
    }

    /**
     * Remove task.
     * @param taskId_ The task id.
     */
    function removeTask(uint256 taskId_) external onlyOwner
    {
        delete _tasks[taskId_];
        emit taskRemoved(taskId_);
    }

    /**
     * Update task.
     * @param taskId_ The task id.
     * @param externalContract_ The external contract.
     * @param interval_ The interval.
     * @param offset_ The offset.
     */
    function updateTask(uint256 taskId_, address externalContract_, uint256 interval_, uint256 offset_) external onlyOwner
    {
        _tasks[taskId_] = Task({
            externalContract: ICronable(externalContract_),
            interval: interval_,
            offset: offset_,
            last: _tasks[taskId_].last
        });
        emit taskUpdated(taskId_, externalContract_, interval_, offset_);
    }

    /**
     * Run.
     */
    function run() external
    {
        for(uint256 i = 1; i <= _taskIdTracker; i++) {
            Task memory task = _tasks[i];
            if(task.externalContract == ICronable(address(0))) continue;
            if(block.timestamp < task.last + task.interval + task.offset) continue;
            address(task.externalContract).call(abi.encodePacked(task.externalContract.cron.selector));
            _tasks[i].last = ((block.timestamp / task.interval) * task.interval) + task.offset;
            emit taskRun(i, address(task.externalContract));
        }
    }
}
