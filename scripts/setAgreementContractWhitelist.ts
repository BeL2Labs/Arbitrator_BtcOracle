// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import {readConfig} from "./helper";
import {BigNumber} from "ethers";

async function main() {
    let chainID = await getChainId();
    console.log("chainID==", chainID)

    let accounts = await ethers.getSigners()
    let account = accounts[0]
    console.log("account", account.address)
    let contractAddress = await readConfig(network.name,"ARBITRATOR");
    const contractFactory = await ethers.getContractFactory('Arbitrator',account)
    let contract  = await contractFactory.connect(account).attach(contractAddress);
    let whiteList = "";
    if (network.name == "stage") {
        whiteList = "0x98568A3abB586B92294cDb4AD5b03E560BCADb06";
    }
    if (network.name == "testnet") {
        whiteList = "0x9b5f23a95A1627cd59791FA1950Dd1c9DEC41F69";
    }
    let tx = await contract.setAgreementContractWhitelist(whiteList, true);
    let receipt = await tx.wait();
    console.log("receipt=", receipt.logs);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
