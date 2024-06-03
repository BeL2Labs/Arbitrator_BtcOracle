// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.20;
import "./interfaces/IZKPOrder.sol";
/**
 * @title IArbitrator
 * @dev Interface for the arbitration contract, defining functions for arbitrator registration, submitting arbitration results, requesting arbitration, and more.
 */
interface IArbitrator {
    struct MerkleProofData {
        bytes32[] proof;
        bytes32 root;
        bytes32 leaf;
        bool[] flags;
    }
    struct ArbitratorInfo {
        address arbitrator;
        uint256 commitPeriod;
        uint256 registeredAt;
        bytes btcPublicKey;
        address stakedToken;
        uint256 stakedAmount;
    }

    struct ArbitrationData {
        bytes32 requestID;
        uint256 requestTime;
        bytes btcTxToSign;
        bytes btcTxSigned;
        bytes signature;
        bytes script;
        MerkleProofData merkleProof;
        bytes[] utxos;
        uint32 blockHeight;
        bytes32 wTxId;
        string prover;
        uint256 lockBtcTx;
        uint256 lockAmount;
    }

    /**
     * @dev Registers a new arbitrator.
     * @param _commitPeriod The commitment period of the arbitrator, in seconds.
     * @param _btcPublicKey The Bitcoin public key of the arbitrator.
     * @param _token The address of the ERC20 token used for staking.
     * @param _amount The amount of tokens to be staked.
     */
    function registerArbitrator(uint256 _commitPeriod, bytes memory _btcPublicKey, address _token, uint256 _amount) external;

    /**
    * @dev Get the first registerArbitrator public key
     */
    function getArbitratorPublicKey() external view returns(bytes memory);
    /**
     * @dev Submits an arbitration result.
     * @param _queryId The unique identifier of the arbitration request.
     * @param _signedBtcTx The signed Bitcoin transaction representing the arbitration result.
     * @param utxos The UTXOs.
     * @param blockHeight The Bitcoin block height.
     * @param merkleProof The Merkle proof.
     */
    function submitArbitrationResult(
        bytes32 _queryId,
        bytes memory _signedBtcTx,
        bytes[] memory utxos,
        uint32 blockHeight,
        MerkleProofData calldata merkleProof) external;

    /**
     * @dev Allows an arbitrator to exit and reclaim their staked tokens after their commitment period ends.
     */
    function exitArbitrator() external;

    /**
     * @dev Requests arbitration.
     * @param _btcTxToSign The Bitcoin transaction to be signed by the arbitrator.
     * @param _queryId The unique identifier of the arbitration request.
     */
    function requestArbitration(bytes memory _btcTxToSign, bytes memory _signature, bytes memory _script, bytes32 _queryId) external payable;

    /**
     * @dev Reports misbehaving arbitrators.
     * @param _arbitrators The list of arbitrator addresses to be reported.
     * @param _evidence The evidence supporting the report.
     */
    function reportArbitrator(address[] memory _arbitrators, bytes memory _evidence) external;

    /**
     * @dev Sets the whitelist status of an agreement contract. Only whitelisted contracts can request arbitration.
     * @param _agreementContract The address of the agreement contract.
     * @param _isWhitelisted The whitelist status to be set (true for whitelisted, false for not).
     */
    function setAgreementContractWhitelist(address _agreementContract, bool _isWhitelisted) external;

    /**
     * @dev Sets the duration of arbitration requests.
     * @param _duration The duration of arbitration requests, in seconds.
     */
    function setArbitrationRequestDuration(uint256 _duration) external;

    /**
     * @dev Sets the whitelist status of a token. Only whitelisted tokens can be used for staking.
     * @param _token The address of the token.
     * @param _isWhitelisted The whitelist status to be set (true for whitelisted, false for not).
     */
    function setTokenWhitelist(address _token, bool _isWhitelisted) external;

    /**
     * @dev Sets the address of the AssetOracle price oracle for fetching token prices.
     * @param _oracle The address of the AssetOracle price oracle.
     */
    function setAssetOracle(address _oracle) external;

    /**
     * @dev Retrieves the information of an arbitrator.
     * @param _arbitrator The address of the arbitrator.
     * @return The arbitrator's information, including commitment period, registration time, Bitcoin public key, staked token address, and staked amount.
     */
    function getArbitratorInfo(address _arbitrator) external view returns (ArbitratorInfo memory);

    /**
     * @dev Retrieves the status of an arbitration request.
     * @param _queryId The unique identifier of the arbitration request.
     * @return The status of the arbitration request.
     */
    function getArbitrationStatus(bytes32 _queryId, string memory network) external view returns (ProofStatus);

    function getArbitrationDetails(bytes32 _queryId, string memory network) external view returns (
        bytes32,  //wtxid
        Input[] memory,
        Output[] memory,
        bytes memory, //script
        ProofStatus
    );

    function getProvingDetail(bytes32 _queryId, string memory network) external view returns (
        bytes32, //wtxid
        ProvingStatus,
        string memory //proverAddress
    );

    /**
     * @dev Emitted when a new arbitrator is registered.
     * @param arbitrator The address of the registered arbitrator.
     * @param commitPeriod The commitment period of the arbitrator.
     * @param btcPublicKey The Bitcoin public key of the arbitrator.
     * @param stakedToken The address of the token staked by the arbitrator.
     * @param stakedAmount The amount of tokens staked by the arbitrator.
     */
    event ArbitratorRegistered(address indexed arbitrator, uint256 commitPeriod, bytes btcPublicKey, address stakedToken, uint256 stakedAmount);

    /**
     * @dev Emitted when an arbitration result is submitted.
     * @param signedBtcTx The signed Bitcoin transaction representing the arbitration result.
     */
    event ArbitrationResultSubmitted(bytes signedBtcTx, bytes32 queryId);

    /**
     * @dev Emitted when an arbitrator exits and reclaims their staked tokens.
     * @param arbitrator The address of the exiting arbitrator.
     * @param stakedToken The address of the token staked by the arbitrator.
     * @param stakedAmount The amount of tokens reclaimed by the arbitrator.
     */
    event ArbitratorExited(address indexed arbitrator, address stakedToken, uint256 stakedAmount);

    /**
     * @dev Emitted when arbitration is requested.
     * @param btcTxToSign The Bitcoin transaction to be signed by the arbitrator.
     * @param queryId The unique identifier of the arbitration request.
     */
    event ArbitrationRequested(bytes btcTxToSign, bytes signature, bytes script, bytes32 queryId);

    /**
     * @dev Emitted when arbitrators are reported for misbehavior.
     * @param arbitrators The list of reported arbitrator addresses.
     * @param reporter The address of the reporter.
     */
    event ArbitratorReported(address[] arbitrators, address indexed reporter);

    /**
     * @dev Emitted when the minimum stake amount is updated.
     * @param newAmount The new minimum stake amount.
     */
    event MinStakeAmountUpdated(uint256 indexed newAmount);

    /**
     * @dev Emitted when the whitelist status of an arbitrator is updated.
     * @param arbitrator The address of the arbitrator.
     * @param status The new whitelist status of the arbitrator.
     */
    event WhitelistStatusUpdated(address indexed arbitrator, bool indexed status);

    event ContractWhiteListUpdate(address indexed contractAddress, bool indexed status);

    event SetArbitrationRequestDuration(uint256 indexed duration);

    event SetTokenWhitelist(address indexed _token, bool indexed _isWhitelisted);

    event SetAssetOracle(address indexed oracle);

    event SetRegisterWhiteList(address indexed whiteList);
    event SetZkpOrder(address indexed zkpOrder);


    /**
     * @dev Sets the minimum stake amount required for arbitrators.
     * @param newAmount The new minimum stake amount.
     */
    function setMinStakeAmount(uint256 newAmount) external;

    function setRegisterWhiteList(address whiteList) external;

    function setZkpOrder(address zkpOrderAddress) external;

    function getArbitrationData(bytes32 queryID) external view returns(ArbitrationData memory);
}
