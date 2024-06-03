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
    let zkpOrdder = "0xB1f2Ce97276e776a9eF2dcD53849AdCEb21f96fF";
    if (chainID == 21) {
        zkpOrdder = "0x462FeA614D6Af68c8B72cB677EF0b66E33a0fB8A";
    }

    let tx = await contract.setZkpOrder(zkpOrdder);
    console.log("setZkpOrder =", tx.hash);
    let receipt = await tx.wait();
    console.log("receipt=", receipt);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
