// @ts-ignore
import {ethers, upgrades, getChainId, network} from 'hardhat'
import "@openzeppelin/hardhat-upgrades";
import {BigNumber} from "ethers";

describe(`Arbitrator Test `, () => {
  let contract: any;
  let signers = [];
  it("Deploy", async function () {
    let chainID = await getChainId();
    console.log("chainID ", chainID);
    signers = await ethers.getSigners()
    let deployer = signers[0]
    const factory = await ethers.getContractFactory("Arbitrator", deployer);
    contract = await upgrades.deployProxy(factory,
        [
        ],
        {
          initializer:  "initialize",
          unsafeAllowLinkedLibraries: true,
        });

    await contract.deployed();
    console.log("contract deployed ", contract.address);
  });

})
