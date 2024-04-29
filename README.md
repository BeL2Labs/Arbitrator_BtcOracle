# Arbitrator

Arbitrator is a decentralized arbitration contract for resolving disputes in blockchain-based agreements. It provides a framework for registering arbitrators, requesting arbitration, and submitting arbitration results.

## Features

- Arbitrator registration with staking functionality
- Arbitration request mechanism
- Submission of arbitration results
- Arbitrator exit and stake withdrawal
- Arbitrator reporting and slashing mechanism
- Access control for admin functions
- Chainlink oracle integration for token price feeds

## Installation

To use the Arbitrator contract in your project, follow these steps:

1. Install the required dependencies:

   ```bash
   npm install @openzeppelin/contracts @chainlink/contracts
   ```

2. Import the Arbitrator contract into your Solidity file:

   ```solidity
   import "./Arbitrator.sol";
   ```

3. Deploy the Arbitrator contract and interact with it using your preferred development environment (e.g., Truffle, Hardhat).

## Usage

1. Deploy the Arbitrator contract with the necessary constructor arguments.
2. Register arbitrators using the `registerArbitrator` function, providing the required parameters such as commitment period, BTC public key, staked token, and staked amount.
3. Request arbitration using the `requestArbitration` function, specifying the BTC transaction to sign and the query ID.
4. Arbitrators can submit arbitration results using the `submitArbitrationResult` function, providing the signed BTC transaction.
5. Arbitrators can exit and withdraw their stake using the `exitArbitrator` function, subject to the specified commitment period.
6. Users can report misbehaving arbitrators using the `reportArbitrator` function, providing evidence of non-arbitration transactions signed by the arbitrator.

## Admin Functions

The Arbitrator contract includes several admin functions that can only be accessed by accounts with the ADMIN_ROLE:

- `setAgreementContractWhitelist`: Add or remove agreement contracts from the whitelist.
- `setArbitrationRequestDuration`: Set the duration for arbitration requests.
- `setTokenWhitelist`: Add or remove tokens from the whitelist for staking.
- `setMinStakeAmount`: Set the minimum stake amount required for arbitrators.
- `updateWhitelistStatus`: Update the whitelist status of an arbitrator.
- `setChainlinkOracle`: Set the address of the Chainlink price feed oracle.

## License

This project is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License (CC-BY-NC-4.0). See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## Disclaimer

The Arbitrator contract is provided as-is, without any warranties or guarantees. Use it at your own risk. The authors and contributors are not responsible for any damages or losses incurred while using this contract.

## Acknowledgements

The Arbitrator contract builds upon the work of the OpenZeppelin and Chainlink communities. We express our gratitude for their contributions to the ecosystem.
