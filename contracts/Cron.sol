// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstracts/BaseContract.sol";

contract Cron is BaseContract {
    struct Task {
        address externalContract;
        bytes4 methodSelector;
        uint256 last;
    }

    mapping(uint256 => Task) private _tasks;
    uint256 private _taskIdTracker;
    uint256 private _lastTaskRun;

    event TaskAdded(uint256 indexed taskId, address externalContract, bytes4 methodSelector);
    event TaskRemoved(uint256 indexed taskId, address externalContract, bytes4 methodSelector);
    event TaskRun(uint256 indexed taskId, address externalContract, bytes4 methodSelector);

    function setup() external override {
        addTask(addressBook.get("TaxHandler"), "distribute()");
        address _staking_ = addressBook.get("Staking");
        addTask(_staking_, "updateWhiteCarpetRewards()");
        addTask(_staking_, "addTokensToRedCarpet()");
        addTask(_staking_, "rewardRedCarpetTokens()");
    }

    function addTask(address externalContract_, string memory method_) public onlyOwner {
        _taskIdTracker++;
        _tasks[_taskIdTracker] = Task({
            externalContract: externalContract_,
            methodSelector: bytes4(keccak256(bytes(method_))),
            last: 0
        });
        emit TaskAdded(_taskIdTracker, externalContract_, _tasks[_taskIdTracker].methodSelector);
    }

    function removeTask(uint256 taskId_) external onlyOwner {
        require(_tasks[taskId_].externalContract != address(0), "Task does not exist.");
        emit TaskRemoved(taskId_, _tasks[taskId_].externalContract, _tasks[taskId_].methodSelector);
        delete _tasks[taskId_];
    }

    function getTask(uint256 taskId_) external view returns (Task memory) {
        return _tasks[taskId_];
    }

    function run() external {
        _lastTaskRun++;
        if (_tasks[_lastTaskRun].externalContract == address(0)) _lastTaskRun++;
        if (_lastTaskRun > _taskIdTracker) _lastTaskRun = 1;
        (bool success, ) = _tasks[_lastTaskRun].externalContract.call(abi.encodeWithSelector(_tasks[_lastTaskRun].methodSelector));
        require(success, "External call failed");
        _tasks[_lastTaskRun].last = block.timestamp;
        emit TaskRun(_lastTaskRun, _tasks[_lastTaskRun].externalContract, _tasks[_lastTaskRun].methodSelector);
    }
}
