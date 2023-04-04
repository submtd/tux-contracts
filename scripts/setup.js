const hre = require("hardhat");
require("dotenv").config();

const addressBookAddress = process.env.ADDRESSBOOK;

const contracts = require("./contracts");

async function main() {
    const keys = Object.keys(contracts);
    const addressBook = await hre.ethers.getContractAt("AddressBook", addressBookAddress);
    // Setup contracts.
    for (const key of keys) {
        console.log("Setting up " + key + "...");
        contracts[key].contract = await hre.ethers.getContractAt(key, await addressBook.get(key));
        await runContractMethod(contracts[key].contract, "setup");
    }
}

async function runContractMethod(contract, method, ...args) {
    const tx = await contract[method](...args);
    await tx.wait();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
