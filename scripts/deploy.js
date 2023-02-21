const hre = require("hardhat");

const contracts = [];

async function main() {
    // Deploy AddressBook.
    const addressbook = await hre.run("deployContract", { contract: "AddressBook" });
    await runContractMethod(addressbook, "set", "router", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
    await runContractMethod(addressbook, "set", "factory", "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f");
    contracts.push({ name: "AddressBook", contract: addressbook, address: addressbook.address });
    console.log("ADDRESSBOOK=" + addressbook.address);
    // Deploy Charity Vault.
    const charityvault = await hre.run("deployContract", { contract: "CharityVault" });
    await runContractMethod(charityvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "charityVault", charityvault.address);
    contracts.push({ name: "CharityVault", contract: charityvault, address: charityvault.address });
    console.log("CHARITY_VAULT=" + charityvault.address);
    // Deploy Collateral Vault.
    const collateralvault = await hre.run("deployContract", { contract: "CollateralVault" });
    await runContractMethod(collateralvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "collateralVault", collateralvault.address);
    contracts.push({ name: "CollateralVault", contract: collateralvault, address: collateralvault.address });
    console.log("COLLATERAL_VAULT=" + collateralvault.address);
    // Deploy DeployLiquidity.
    const deployliquidity = await hre.run("deployContract", { contract: "DeployLiquidity" });
    await runContractMethod(deployliquidity, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "deployLiquidity", deployliquidity.address);
    contracts.push({ name: "DeployLiquidity", contract: deployliquidity, address: deployliquidity.address });
    console.log("DEPLOY_LIQUIDITY=" + deployliquidity.address);
    // Deploy Dev Vault.
    const devvault = await hre.run("deployContract", { contract: "DevVault" });
    await runContractMethod(devvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "devVault", devvault.address);
    contracts.push({ name: "DevVault", contract: devvault, address: devvault.address });
    console.log("DEV_VAULT=" + devvault.address);
    // Deploy Fake USDC.
    const usdc = await hre.run("deployContract", { contract: "FakeUsdc" });
    await runContractMethod(usdc, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "usdc", usdc.address);
    await runContractMethod(usdc, "mint", deployliquidity.address, "250000000000000000000000000");
    await runContractMethod(usdc, "mint", await hre.ethers.provider.getSigner().getAddress(), "1000000000000000000000");
    contracts.push({ name: "FakeUsdc", contract: usdc, address: usdc.address });
    console.log("USDC=" + usdc.address);
    // Deploy Investor Vault
    const investorvault = await hre.run("deployContract", { contract: "InvestorVault" });
    await runContractMethod(investorvault, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "investorVault", investorvault.address);
    contracts.push({ name: "InvestorVault", contract: investorvault, address: investorvault.address });
    console.log("INVESTOR_VAULT=" + investorvault.address);
    // Deploy Staking.
    const staking = await hre.run("deployContract", { contract: "Staking" });
    await runContractMethod(staking, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "staking", staking.address);
    contracts.push({ name: "Staking", contract: staking, address: staking.address });
    console.log("STAKING=" + staking.address);
    // Deploy Tax Handler.
    const taxhandler = await hre.run("deployContract", { contract: "TaxHandler" });
    await runContractMethod(taxhandler, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "taxHandler", taxhandler.address);
    contracts.push({ name: "TaxHandler", contract: taxhandler, address: taxhandler.address });
    console.log("TAX_HANDLER=" + taxhandler.address);
    // Deploy TUX.
    const tux = await hre.run("deployContract", { contract: "Tux" });
    await runContractMethod(tux, "setAddressBook", addressbook.address);
    await runContractMethod(addressbook, "set", "tux", tux.address);
    await runContractMethod(tux, "mint", deployliquidity.address, "2500000000000000000000000000");
    contracts.push({ name: "Tux", contract: tux, address: tux.address });
    console.log("TUX=" + tux.address);
    // Setup all contracts.
    contracts.forEach(async (contract) => {
        console.log("Setting up " + contract.name + "...");
        await runContractMethod(contract.contract, "setup");
    });
    //await runContractMethod(charityvault, "setup");
    //await runContractMethod(collateralvault, "setup");
    //await runContractMethod(deployliquidity, "setup");
    //await runContractMethod(devvault, "setup");
    //await runContractMethod(usdc, "setup");
    //await runContractMethod(investorvault, "setup");
    //await runContractMethod(staking, "setup");
    //await runContractMethod(taxhandler, "setup");
    //await runContractMethod(tux, "setup");
    // Deploy liquidity.
    console.log("Deploying liquidity...");
    await runContractMethod(deployliquidity, "deploy");
    // Verify all contracts.
    contracts.forEach(async (contract) => {
        console.log("verifying " + contract.name + "...");
        await hre.run("verify:verify", { address: contract.address });
    });
    //console.log("Verifying addressbook...");
    //await hre.run("verify:verify", { address: addressbook.address });
    //console.log("Verifying charityvault...");
    //await hre.run("verify:verify", { address: charityvault.address });
    //console.log("Verifying collateralvault...");
    //await hre.run("verify:verify", { address: collateralvault.address });
    //console.log("Verifying deployliquidity...");
    //await hre.run("verify:verify", { address: deployliquidity.address });
    //console.log("Verifying devvault...");
    //await hre.run("verify:verify", { address: devvault.address });
    //console.log("Verifying usdc...");
    //await hre.run("verify:verify", { address: usdc.address });
    //console.log("Verifying investorvault...");
    //await hre.run("verify:verify", { address: investorvault.address });
    //console.log("Verifying staking...");
    //await hre.run("verify:verify", { address: staking.address });
    //console.log("Verifying taxhandler...");
    //await hre.run("verify:verify", { address: taxhandler.address });
    //console.log("Verifying tux...");
    //await hre.run("verify:verify", { address: tux.address });
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
