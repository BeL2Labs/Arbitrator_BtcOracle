// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import {readConfig} from "./helper";
import {BigNumber} from "ethers";
import {publicKeyCreate} from 'secp256k1';

async function main() {
    let chainID = await getChainId();
    console.log("chainID==", chainID)

    let accounts = await ethers.getSigners()
    let account = accounts[1]
    console.log("account", account.address)
    let contractAddress = await readConfig(network.name,"ARBITRATOR");
    const contractFactory = await ethers.getContractFactory('Arbitrator',account)
    let contract  = await contractFactory.connect(account).attach(contractAddress);

    let orderContractAddress = "0x0fa5db7a7b56c368be1a646ca7f062376dfe858d";
    let proveNetwork = "mainnet"

    const addressAsBytes = ethers.utils.arrayify(orderContractAddress);
    const addressAsUint256 = ethers.BigNumber.from(addressAsBytes);
    const queryID = ethers.utils.hexZeroPad(addressAsUint256.toHexString(), 32);

    console.log("queryID", queryID, " addressAsBytes", addressAsUint256.toLocaleString())

    let data = await contract.getProvingDetail(queryID, proveNetwork);

    console.log("data == ", data, " ==", data[2]);

    let arbitratorData = await contract.getArbitrationData(queryID);

    let getArbitrationDetails = await contract.getArbitrationDetails(queryID,proveNetwork);
    console.log("getArbitrationDetails ", getArbitrationDetails)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
