import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // Configure payment token: use env var if set, otherwise deploy mock for local testing
  const configuredToken = process.env.PAYMENT_TOKEN_ADDRESS;
  let tokenAddr: string;
  if (configuredToken && configuredToken.length > 0) {
    tokenAddr = configuredToken;
    console.log("Payment token (env):", tokenAddr);
  } else {
    const Mock = await ethers.getContractFactory("MockStablecoin");
    const mock = await Mock.deploy();
    await mock.waitForDeployment();
    tokenAddr = await mock.getAddress();
    console.log("Mock token:", tokenAddr);
  }

  const Registry = await ethers.getContractFactory("EligibilityRegistry");
  const registry = await Registry.deploy(deployer.address);
  await registry.waitForDeployment();
  console.log("Registry:", await registry.getAddress());

  // Annual cap alignment: set DECIMALS via env; default 18
  const decimals = Number(process.env.PAYMENT_TOKEN_DECIMALS || 18);
  const annualCap = ethers.parseUnits("20000000", decimals.toString());
  const periodLength = 365 * 24 * 60 * 60; // 365 days
  const Limiter = await ethers.getContractFactory("CompensationLimiter");
  const limiter = await Limiter.deploy(deployer.address, annualCap, periodLength);
  await limiter.waitForDeployment();
  console.log("Limiter:", await limiter.getAddress());

  const minIntervalSeconds = 7 * 24 * 60 * 60; // weekly
  const Pool = await ethers.getContractFactory("RedistributionPool");
  const pool = await Pool.deploy(deployer.address, tokenAddr, await registry.getAddress(), minIntervalSeconds);
  await pool.waitForDeployment();
  console.log("Pool:", await pool.getAddress());

  const Payroll = await ethers.getContractFactory("RedistributivePayroll");
  const payroll = await Payroll.deploy(
    deployer.address,
    tokenAddr,
    await registry.getAddress(),
    await limiter.getAddress(),
    await pool.getAddress()
  );
  await payroll.waitForDeployment();
  console.log("Payroll:", await payroll.getAddress());

  // Grant caller role for limiter to payroll
  await (await limiter.grantRole(ethers.id("CALLER_ROLE"), await payroll.getAddress())).wait();

  // Grant employer role to deployer for quick test
  await (await payroll.setEmployer(deployer.address, true)).wait();

  // Seed deployer with mock funds only if mock was deployed
  if (!configuredToken) {
    const Mock = await ethers.getContractAt("MockStablecoin", tokenAddr);
    await (await Mock.mint(deployer.address, ethers.parseUnits("100000000", decimals))).wait();
  }

  console.log("Deployment complete.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


