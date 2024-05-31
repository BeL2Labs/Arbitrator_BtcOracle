// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import {readConfig} from "./helper";
import {BigNumber} from "ethers";
import {publicKeyCreate} from 'secp256k1';

async function main() {
    let chainID = await getChainId();
    console.log("chainID==", chainID)

    let accounts = await ethers.getSigners()
    let account = accounts[0]
    console.log("account", account.address)
    let contractAddress = await readConfig(network.name,"ARBITRATOR");
    const contractFactory = await ethers.getContractFactory('Arbitrator',account)
    let contract  = await contractFactory.connect(account).attach(contractAddress);

    let arbitratorPbk = await contract.getArbitratorPublicKey();
    console.log("arbitratorPbk ", arbitratorPbk);

    let getArbitratorInfo = await contract.getArbitratorInfo(account.address);
    console.log("getArbitratorInfo ", getArbitratorInfo);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
