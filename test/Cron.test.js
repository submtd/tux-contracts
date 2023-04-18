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
    const transaction = await cron.connect(owner).addTask(mockCronJob.address, "cron()");
    await transaction.wait();

    taskId = 1;
  });

  it("should add a task", async function () {
    const task = await cron.getTask(taskId);
    expect(task.externalContract).to.equal(mockCronJob.address);
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
    await expect(cron.connect(nonOwner).addTask(mockCronJob.address, "cron()")).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("non-owner should not be able to remove tasks", async function () {
    await expect(cron.connect(nonOwner).removeTask(taskId)).to.be.revertedWith("Ownable: caller is not the owner");
  });
});
