const hre = require("hardhat");
let tx;

async function main() {
    // Deploy AddressBook.
    const AddressBook = await hre.ethers.getContractFactory("AddressBook");
    const addressbook = await AddressBook.deploy();
    await addressbook.deployed();
    tx = await addressbook.set("router", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D");
    await tx.wait();
    console.log("ADDRESS_BOOK=" + addressbook.address);
    // Deploy DeployLiquidity.
    const DeployLiquidity = await hre.ethers.getContractFactory("DeployLiquidity");
    const deployliquidity = await DeployLiquidity.deploy();
    await deployliquidity.deployed();
    tx = await deployliquidity.setAddressBook(addressbook.address);
    await tx.wait();
    tx = await addressbook.set("deployLiquidity", deployliquidity.address);
    await tx.wait();
    console.log("DEPLOY_LIQUIDITY=" + deployliquidity.address);
    // Deploy collateral vault.
    const CollateralVault = await hre.ethers.getContractFactory("CollateralVault");
    const collateralvault = await CollateralVault.deploy();
    await collateralvault.deployed();
    tx = await collateralvault.setAddressBook(addressbook.address);
    await tx.wait();
    tx = await addressbook.set("collateralVault", collateralvault.address);
    await tx.wait();
    console.log("COLLATERAL_VAULT=" + collateralvault.address);
    tx = await addressbook.set("collateralVault", collateralvault.address);
    await tx.wait();
    // Deploy fake USDC.
    const USDC = await hre.ethers.getContractFactory("FakeUsdc");
    const usdc = await USDC.deploy();
    await usdc.deployed();
    tx = await usdc.setAddressBook(addressbook.address);
    await tx.wait();
    tx = await addressbook.set("usdc", usdc.address);
    await tx.wait();
    // mint 250m to deployliquidity.
    tx = await usdc.mint(deployliquidity.address, "250000000000000000000000000");
    await tx.wait();
    // mint 1000 to sender.
    tx = await usdc.mint(await hre.ethers.provider.getSigner().getAddress(), "1000000000000000000000");
    console.log("USDC=" + usdc.address);
    // Deploy TUX.
    const Tux = await hre.ethers.getContractFactory("Tux");
    const tux = await Tux.deploy();
    await tux.deployed();
    tx = await tux.setAddressBook(addressbook.address);
    await tx.wait();
    tx = await addressbook.set("tux", tux.address);
    await tx.wait();
    // mint 2.5b to deployliquidity.
    tx = await tux.mint(deployliquidity.address, "2500000000000000000000000000");
    await tx.wait();
    console.log("TUX=" + tux.address);
    // Deploy staking.
    const Staking = await hre.ethers.getContractFactory("Staking");
    const staking = await Staking.deploy();
    await staking.deployed();
    tx = await staking.setAddressBook(addressbook.address);
    await tx.wait();
    tx = await addressbook.set("staking", staking.address);
    await tx.wait();
    console.log("STAKING=" + staking.address);
    // Deploy liquidity.
    tx = await deployliquidity.deploy();
    await tx.wait();
    console.log("Liquidity deployed!");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
