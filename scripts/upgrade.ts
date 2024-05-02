// @ts-ignore
import { network, ethers, upgrades, getChainId } from 'hardhat'
import {readConfig} from "./helper";


async function main() {
    let chainId = await getChainId();
    console.log("chainId is :" + chainId, " network ", network.name);

    const [ deployer ] = await ethers.getSigners();
    console.log("Deployer address", deployer.address);

    const contractAddress = await readConfig(network.name, "ARBITRATOR");

    console.log("contractAddress ", contractAddress);

    const contractFactory = await ethers.getContractFactory("Arbitrator");
    const newContract = await upgrades.upgradeProxy(contractAddress, contractFactory);

    const contract = await newContract.deployed();
    console.log("upgrade address ", contract.address);

    console.log('completed.');

}

main();
