const hre = require("hardhat");

const contracts = {
    AddressBook: {},
    CharityVault: {},
    CollateralVault: {},
    DeployLiquidity: {},
    DevVault: {},
    InvestorVault: {},
    Staking: {},
    TaxHandler: {},
    Tux: {},
    Usdc: {},
};

async function main() {
    await hre.run("compile");
    const keys = Object.keys(contracts);
    // Deploy contracts.
    for (const key of keys) {
        console.log("Deploying " + key + "...");
        contracts[key].contract = await hre.run("deployContract", { contract: key });
    }
    // Set global addresses.
    console.log("Setting global addresses...");
    await runContractMethod(contracts.AddressBook.contract, "set", "Router", "0x7954ad9326Ef5e9bcA7510A04b4F65b18ce54F1F");
    await runContractMethod(contracts.AddressBook.contract, "set", "Factory", "0x4661C9F334790B8c215587FCe7c8942B4FC2F5B5");
    // Set addressbook entries.
    for (const key of keys) {
        console.log("Setting " + key + " in AddressBook...");
        await runContractMethod(contracts.AddressBook.contract, "set", key, contracts[key].contract.address);
        await runContractMethod(contracts[key].contract, "setAddressBook", contracts.AddressBook.contract.address);
    }
    // Mint USDC
    console.log("Minting USDC...");
    await runContractMethod(contracts.Usdc.contract, "mintTo", contracts.DeployLiquidity.contract.address, "250000000000000000000000000");
    // Mint TUX
    console.log("Minting TUX...");
    await runContractMethod(contracts.Tux.contract, "mint", contracts.DeployLiquidity.contract.address, "2500000000000000000000000000");
    // Deploy liquidity
    console.log("Deploying liquidity...");
    await runContractMethod(contracts.DeployLiquidity.contract, "deploy");
    // Setup all contracts
    for (const key of keys) {
        console.log("Setting up " + key + "...");
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
