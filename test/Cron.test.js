const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Cron", function () {
  let cron, mockCronJob, owner, nonOwner, taskId;

  beforeEach(async function () {
    const Cron = await ethers.getContractFactory("Cron");
    const MockCronJob = await ethers.getContractFactory("MockCronJob");

    [owner, nonOwner] = await ethers.getSigners();
    cron = await Cron.deploy();
    mockCronJob = await MockCronJob.deploy();
    await cron.deployed();
    await mockCronJob.deployed();

    // Add a task as the owner.
    const transaction = await cron.connect(owner).addTask(mockCronJob.address, 60, 0);
    await transaction.wait();

    taskId = 1;
  });

  it("should add a task", async function () {
    const task = await cron.getTask(taskId);
    expect(task.externalContract).to.equal(mockCronJob.address);
    expect(task.interval).to.equal(60);
    expect(task.offset).to.equal(0);
  });

  it("should update a task", async function () {
    await cron.connect(owner).updateTask(taskId, mockCronJob.address, 120, 30);
    const updatedTask = await cron.getTask(taskId);
    expect(updatedTask.externalContract).to.equal(mockCronJob.address);
    expect(updatedTask.interval).to.equal(120);
    expect(updatedTask.offset).to.equal(30);
  });

  it("should remove a task", async function () {
    await cron.connect(owner).removeTask(taskId);
    const removedTask = await cron.getTask(taskId);
    expect(removedTask.externalContract).to.equal("0x0000000000000000000000000000000000000000");
  });

  it("should run tasks", async function () {
    await cron.run();
    const callCount = await mockCronJob.callCount();
    expect(callCount).to.equal(1);
  });

  it("non-owner should not be able to add tasks", async function () {
    await expect(cron.connect(nonOwner).addTask(mockCronJob.address, 120, 30)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("non-owner should not be able to update tasks", async function () {
    await expect(cron.connect(nonOwner).updateTask(taskId, mockCronJob.address, 120, 30)).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("non-owner should not be able to remove tasks", async function () {
    await expect(cron.connect(nonOwner).removeTask(taskId)).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
