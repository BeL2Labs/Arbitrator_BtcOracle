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
//uint256 _commitPeriod, bytes calldata _btcPublicKey, address _token, uint256 _amount

    let registerWhiteListContract = await contract.registerWhiteListContract();
    console.log("registerWhiteListContract ", registerWhiteListContract)

    let _commitPeriod = 90 * 3600 * 24;

    const privateKeys = network.config.accounts;
    const signerPrivate = privateKeys[1];
    let privateKeyHex = signerPrivate.substr(2);
    console.log("private key ", privateKeyHex);
    const pubKey = publicKeyCreate(Buffer.from(privateKeyHex, "hex"), true);
    let publicKeyBytes = Buffer.from(pubKey, 'hex');

    let usdt = "0x0daddd286487f3a03Ea9A1b693585fD46cdCcF9F";
    if(chainID == 21) {
        usdt = "0x892A0c0951091A8a072A4b652926D4A8875F9bcB";
    }

    // publicKeyBytes = "0x03454e2be5c77729c986d692f023f25dc9b5b7887960bbf5176511d8a4cc3e38ed";
    console.log("public key ", publicKeyBytes.toString("hex"))
    let amount = BigNumber.from("1000000000000000000");
    amount = amount.mul(10);//10 * 1e18;
    let tx = await contract.registerArbitrator(_commitPeriod, publicKeyBytes, usdt, amount);
    console.log("register arbitrator =", tx.hash);
    let receipt = await  tx.wait();
    console.log("receipt=", receipt);

    let arbitratorPbk = await contract.getArbitratorPublicKey();
    console.log("arbitratorPbk ", arbitratorPbk);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
