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

    let tx = await contract.setAgreementContractWhitelist("0x20c14ce780cDa71A0A030C9Ae731B38Cf87f44F4", true);
    let receipt = await tx.wait();
    console.log("receipt=", receipt.logs);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
