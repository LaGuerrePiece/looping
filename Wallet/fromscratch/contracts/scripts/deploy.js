// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
  const Looping = await hre.ethers.getContractFactory("Looping");
  const looping = await Looping.deploy();

  await looping.deployed();
  console.log(`Looping deployed to ${looping.address}`);

  const usdcAddr = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const wethAddr  = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  
  let weth = await hre.ethers.getContractAt("IERC20", wethAddr);

  console.log("Impersonating account...")
  const addressWithTokens = "0x9bdB521a97E95177BF252C253E256A60C3e14447"
  const impersonatedSigner = await hre.ethers.getImpersonatedSigner(addressWithTokens);
  
  console.log("sending tx...")
  
  let unsignedTx = await weth.populateTransaction["transfer"](looping.address, "10000000000000000");
  console.log("unsignedTx:", unsignedTx)
  unsignedTx.from = "0x9bdB521a97E95177BF252C253E256A60C3e14447"

  console.log("Sending weth to contract...")
  const sendWethTx = await impersonatedSigner.sendTransaction(unsignedTx);
  console.log(sendWethTx.hash);
  await sendWethTx.wait();
  console.log("Done")

  console.log("Looping...")
  const loopingTx = await looping.connect(impersonatedSigner).loop("10000000000000000", wethAddr, usdcAddr, 110);
  console.log(loopingTx.hash);
  await loopingTx.wait();
  console.log("Done.")



}

async function main2() {
  console.log(await hre.ethers.provider.getNetwork())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
