// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import "@openzeppelin/hardhat-upgrades";
import {readConfig, writeConfig} from "./helper";

async function main() {
  let chainID = await getChainId();
  console.log("chainID ", chainID);
  let signers = await ethers.getSigners()
  let deployer = signers[0]
  const factory = await ethers.getContractFactory("Arbitrator", deployer);

  let assetOracle = "0x5117b046517ffA18d4d9897090D0537fF62A844A";
  let registerWhiteListContract = "0x3909be751B1f3174102b29A75469B58E6DD1a311";

  let contract = await upgrades.deployProxy(factory,
      [
        assetOracle,
        registerWhiteListContract
      ],
      {
        initializer:  "initialize",
        unsafeAllowLinkedLibraries: true,
  });
  await writeConfig(network.name, network.name, "ARBITRATOR", contract.address);

  await contract.deployed();

  console.log("contract deployed ", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
