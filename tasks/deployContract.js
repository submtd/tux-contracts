const { task } = require("hardhat/config");

task("deployContract", "Deploy a contract")
    .addParam("contract", "The name of the contract to deploy")
    .setAction(async (taskArgs, hre) => {
        const Contract = await hre.ethers.getContractFactory(taskArgs.contract);
        const contract = await Contract.deploy();
        await contract.deployed();
        console.log(taskArgs.contract + " deployed to:", contract.address);
        return contract;
    });
