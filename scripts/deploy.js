const hre = require("hardhat");

async function main() {
  
  const VolenceFund = await hre.ethers.getContractFactory("VolenceFund");
  const volenceFund = await VolenceFund.deploy();

  await volenceFund.deployed();

  console.log(
    `volence contract deployed on ${volenceFund.address}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
