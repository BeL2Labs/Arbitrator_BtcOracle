// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import {readConfig} from "./helper";

async function main() {
    let chainID = await getChainId();
    console.log("chainID==", chainID)

    let accounts = await ethers.getSigners()
    let account = accounts[0]
    console.log("account", account.address)
    let contractAddress = await readConfig(network.name,"ARBITRATOR");
    const contractFactory = await ethers.getContractFactory('Arbitrator',account)
    let contract  = await contractFactory.connect(account).attach(contractAddress);
    let whiteList = "0x3909be751B1f3174102b29A75469B58E6DD1a311"
    if (network.name == "stage") {
        whiteList = "0xF3748F86D901aDca1C4310F844206C17634B48d5";
    }
    let tx = await contract.setRegisterWhiteList(whiteList);
    console.log(" setRegisterWhiteList =", tx.hash);
    await tx.wait();
    let submitter = await contract.registerWhiteListContract();
    console.log("submitterAddress=", submitter);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
