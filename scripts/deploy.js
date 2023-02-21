const hre = require("hardhat");

async function main() {
    // Deploy AddressBook.
    const addressbook = await hre.run("deployContract", { contract: "AddressBook" });
    await runContractMethod(addressbook, "set", "router", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
    await runContractMethod(addressbook, "set", "factory", "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f");
    console.log("ADDRESSBOOK=" + addressbook.address);
    // Deploy Charity Vault.
    const charityvault = await hre.run("deployContract", { contract: "CharityVault" });
    await runContractMethod(charityvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "charityVault", charityvault.address);
    console.log("CHARITY_VAULT=" + charityvault.address);
    // Deploy Collateral Vault.
    const collateralvault = await hre.run("deployContract", { contract: "CollateralVault" });
    await runContractMethod(collateralvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "collateralVault", collateralvault.address);
    console.log("COLLATERAL_VAULT=" + collateralvault.address);
    // Deploy DeployLiquidity.
    const deployliquidity = await hre.run("deployContract", { contract: "DeployLiquidity" });
    await runContractMethod(deployliquidity, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "deployLiquidity", deployliquidity.address);
    console.log("DEPLOY_LIQUIDITY=" + deployliquidity.address);
    // Deploy Dev Vault.
    const devvault = await hre.run("deployContract", { contract: "DevVault" });
    await runContractMethod(devvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "devVault", devvault.address);
    console.log("DEV_VAULT=" + devvault.address);
    // Deploy Fake USDC.
    const usdc = await hre.run("deployContract", { contract: "FakeUsdc" });
    await runContractMethod(usdc, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "usdc", usdc.address);
    await runContractMethod(usdc, "mint", deployliquidity.address, "250000000000000000000000000");
    await runContractMethod(usdc, "mint", await hre.ethers.provider.getSigner().getAddress(), "1000000000000000000000");
    console.log("USDC=" + usdc.address);
    // Deploy Investor Vault
    const investorvault = await hre.run("deployContract", { contract: "InvestorVault" });
    await runContractMethod(investorvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "investorVault", investorvault.address);
    console.log("INVESTOR_VAULT=" + investorvault.address);
    // Deploy Staking.
    const staking = await hre.run("deployContract", { contract: "Staking" });
    await runContractMethod(staking, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "staking", staking.address);
    console.log("STAKING=" + staking.address);
    // Deploy Tax Handler.
    const taxhandler = await hre.run("deployContract", { contract: "TaxHandler" });
    await runContractMethod(taxhandler, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "taxHandler", taxhandler.address);
    console.log("TAX_HANDLER=" + taxhandler.address);
    // Deploy TUX.
    const tux = await hre.run("deployContract", { contract: "Tux" });
    await runContractMethod(tux, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "tux", tux.address);
    await runContractMethod(tux, "mint", deployliquidity.address, "2500000000000000000000000000");
    console.log("TUX=" + tux.address);
    // Setup all contracts.
    await runContractMethod(charityvault, "setup");
    await runContractMethod(collateralvault, "setup");
    await runContractMethod(deployliquidity, "setup");
    await runContractMethod(devvault, "setup");
    await runContractMethod(usdc, "setup");
    await runContractMethod(investorvault, "setup");
    await runContractMethod(staking, "setup");
    await runContractMethod(taxhandler, "setup");
    await runContractMethod(tux, "setup");
    // Deploy liquidity.
    await runContractMethod(deployliquidity, "deploy");
    console.log("Liquidity deployed!");
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
