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
    let usdt = "0x0daddd286487f3a03Ea9A1b693585fD46cdCcF9F";
    if (chainID == 21) {
        usdt = "0x892A0c0951091A8a072A4b652926D4A8875F9bcB";
    }

    let tx = await contract.setTokenWhitelist(usdt, true);
    console.log("setTokenWhitelist =", tx.hash);
    let receipt = await tx.wait();
    console.log("receipt=", receipt);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
