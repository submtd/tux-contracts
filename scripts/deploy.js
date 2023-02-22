const hre = require("hardhat");

const contracts = {
    AddressBook: {},
    //CharityVault: {},
    CollateralVault: {},
    DeployLiquidity: {},
    //DevVault: {},
    //InvestorVault: {},
    Staking: {},
    TaxHandler: {},
    Tux: {},
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
    await runContractMethod(contracts.AddressBook.contract, "set", "CharityVault", "0x37F16C99197A9702B2047c985C231fb74fad47dA");
    await runContractMethod(contracts.AddressBook.contract, "set", "DevVault", "0x37F16C99197A9702B2047c985C231fb74fad47dA");
    await runContractMethod(contracts.AddressBook.contract, "set", "InvestorVault", "0x37F16C99197A9702B2047c985C231fb74fad47dA");
    await runContractMethod(contracts.AddressBook.contract, "set", "Usdc", "0x49ED7056c5bC96c0f48D3161B4f6b8B5D380E567");
    await runContractMethod(contracts.AddressBook.contract, "set", "Router", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
    await runContractMethod(contracts.AddressBook.contract, "set", "Factory", "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f");
    // Set addressbook entries.
    for (const key of keys) {
        console.log("Setting " + key + " in AddressBook...");
        await runContractMethod(contracts.AddressBook.contract, "set", key, contracts[key].contract.address);
        await runContractMethod(contracts[key].contract, "setAddressBook", contracts.AddressBook.contract.address);
    }
    // Mint USDC
    console.log("Minting USDC...");
    const Usdc = await hre.ethers.getContractFactory("Usdc");
    const usdc = Usdc.attach("0x49ED7056c5bC96c0f48D3161B4f6b8B5D380E567");
    await runContractMethod(usdc, "mintTo", contracts.DeployLiquidity.contract.address, "250000000000000000000000000");
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

async function callContractMethod(contract, method, ...args) {
    return await contract[method](...args);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
