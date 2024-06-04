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
  let registerWhiteListContract = "0x451D8c4FA7C19E294E23cf533C6e48ab2118b333";
  let zkpOrder = "0xB1f2Ce97276e776a9eF2dcD53849AdCEb21f96fF";
  let initToken = "0x0daddd286487f3a03Ea9A1b693585fD46cdCcF9F";
  if (network.name == "stage") {

  } else if (network.name == "testnet") {

  }

  let contract = await upgrades.deployProxy(factory,
      [
        assetOracle,
        registerWhiteListContract,
        zkpOrder,
        initToken
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
