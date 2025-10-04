const hre = require("hardhat");

async function main() {
  console.log("Deploying Vepulse contract to VeChain...");

  // Get the deployer's address
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy the Vepulse contract
  const Vepulse = await hre.ethers.getContractFactory("Vepulse");
  const vepulse = await Vepulse.deploy();

  await vepulse.waitForDeployment();

  const address = await vepulse.getAddress();
  console.log("Vepulse contract deployed to:", address);

  // Save deployment information
  const deploymentInfo = {
    network: hre.network.name,
    contractAddress: address,
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
  };

  console.log("\nDeployment Info:");
  console.log(JSON.stringify(deploymentInfo, null, 2));

  console.log("\nVerification command (if needed):");
  console.log(`npx hardhat verify --network ${hre.network.name} ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
