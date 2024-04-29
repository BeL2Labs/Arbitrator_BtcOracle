// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IArbitrator.sol";

contract Arbitrator is IArbitrator, AccessControl, ReentrancyGuard {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public arbitrationRequestDuration = 72 hours;
    uint256 public minStakeAmount = 1000 * 10**18; // 1000 USD

    mapping(address => bool) public agreementContractWhitelist;
    mapping(address => bool) public tokenWhitelist;
    mapping(address => bool) public isWhitelisted;
    mapping(bytes32 => uint256) public arbitrationRequestTime;
    mapping(bytes32 => ArbitrationStatus) public arbitrationStatus;

    AggregatorV3Interface public chainlinkOracle;

    struct ArbitratorInfo {
        uint256 commitPeriod;
        uint256 registeredAt;
        bytes32 btcPublicKey;
        address stakedToken;
        uint256 stakedAmount;
    }
    mapping(address => ArbitratorInfo) public arbitratorInfo;

    enum ArbitrationStatus { Pending, Completed }

    event ArbitratorRegistered(address indexed arbitrator, uint256 commitPeriod, bytes32 btcPublicKey, address stakedToken, uint256 stakedAmount);
    event ArbitrationResultSubmitted(bytes signedBtcTx);
    event ArbitratorExited(address indexed arbitrator, address stakedToken, uint256 stakedAmount);
    event ArbitrationRequested(bytes btcTxToSign, bytes32 queryId);
    event ArbitratorReported(address[] arbitrators, address indexed reporter);
    event MinStakeAmountUpdated(uint256 newAmount);
    event WhitelistStatusUpdated(address arbitrator, bool status);

    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function registerArbitrator(uint256 _commitPeriod, bytes32 _btcPublicKey, address _token, uint256 _amount) external override {
        require(_commitPeriod > 0, "Commitment period must be greater than 0");
        require(tokenWhitelist[_token], "Token not whitelisted");
        require(arbitratorInfo[msg.sender].registeredAt == 0, "Arbitrator already registered");

        uint256 usdValue = getUsdValue(_token, _amount);
        require(usdValue >= minStakeAmount, "Staked amount must be greater than minimum stake amount");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        arbitratorInfo[msg.sender] = ArbitratorInfo({
            commitPeriod: _commitPeriod,
            registeredAt: block.timestamp,
            btcPublicKey: _btcPublicKey,
            stakedToken: _token,
            stakedAmount: _amount
        });

        emit ArbitratorRegistered(msg.sender, _commitPeriod, _btcPublicKey, _token, _amount);
    }

    function submitArbitrationResult(bytes calldata _signedBtcTx) external override {
        ArbitratorInfo storage info = arbitratorInfo[msg.sender];
        require(info.registeredAt > 0, "Arbitrator not registered");
        require(block.timestamp <= info.registeredAt + info.commitPeriod, "Arbitrator commitment period ended");

        // TODO: 验证_signedBtcTx是否是有效的仲裁结果交易

        emit ArbitrationResultSubmitted(_signedBtcTx);
    }

    function exitArbitrator() external override {
        ArbitratorInfo storage info = arbitratorInfo[msg.sender];
        require(info.registeredAt > 0, "Arbitrator not registered");
        require(block.timestamp > info.registeredAt + info.commitPeriod, "Arbitrator still in commitment period");

        address stakedToken = info.stakedToken;
        uint256 stakedAmount = info.stakedAmount;
        delete arbitratorInfo[msg.sender];
        IERC20(stakedToken).transfer(msg.sender, stakedAmount);

        emit ArbitratorExited(msg.sender, stakedToken, stakedAmount);
    }

    function requestArbitration(bytes calldata _btcTxToSign, bytes32 _queryId) external payable override {
        require(agreementContractWhitelist[msg.sender], "Agreement contract not whitelisted");
        require(msg.value > 0, "Arbitration fee must be greater than 0");

        arbitrationRequestTime[_queryId] = block.timestamp;
        arbitrationStatus[_queryId] = ArbitrationStatus.Pending;

        emit ArbitrationRequested(_btcTxToSign, _queryId);
    }

    function reportArbitrator(address[] calldata _arbitrators, bytes calldata _evidence) external override {
        for (uint256 i = 0; i < _arbitrators.length; i++) {
            address arbitrator = _arbitrators[i];
            ArbitratorInfo storage info = arbitratorInfo[arbitrator];
            require(info.registeredAt > 0, "Reported address is not a registered arbitrator");

            // TODO: 验证_evidence,确认仲裁人签名了非仲裁交易

            // 如果举报成立,没收仲裁人的质押代币并奖励给举报人
            IERC20(info.stakedToken).transfer(msg.sender, info.stakedAmount);
            delete arbitratorInfo[arbitrator];
        }

        emit ArbitratorReported(_arbitrators, msg.sender);
    }

    function setAgreementContractWhitelist(address _agreementContract, bool _isWhitelisted) external override onlyRole(ADMIN_ROLE) {
        agreementContractWhitelist[_agreementContract] = _isWhitelisted;
    }

    function setArbitrationRequestDuration(uint256 _duration) external override onlyRole(ADMIN_ROLE) {
        arbitrationRequestDuration = _duration;
    }

    function setTokenWhitelist(address _token, bool _isWhitelisted) external override onlyRole(ADMIN_ROLE) {
        tokenWhitelist[_token] = _isWhitelisted;
    }

    function setMinStakeAmount(uint256 newAmount) external override onlyRole(ADMIN_ROLE) {
        minStakeAmount = newAmount;
        emit MinStakeAmountUpdated(newAmount);
    }

    function updateWhitelistStatus(address arbitrator, bool status) external override onlyRole(ADMIN_ROLE) {
        isWhitelisted[arbitrator] = status;
        emit WhitelistStatusUpdated(arbitrator, status);
    }

    function setChainlinkOracle(address _oracle) external override onlyRole(ADMIN_ROLE) {
        chainlinkOracle = AggregatorV3Interface(_oracle);
    }

    function getArbitratorInfo(address _arbitrator) external view override returns (ArbitratorInfo memory) {
        return arbitratorInfo[_arbitrator];
    }

    function getArbitrationStatus(bytes32 _queryId) external view override returns (ArbitrationStatus) {
        return arbitrationStatus[_queryId];
    }

    function getUsdValue(address _token, uint256 _amount) internal view returns (uint256) {
        (, int256 price, , ,) = chainlinkOracle.latestRoundData();
        uint256 decimals = uint256(chainlinkOracle.decimals());
        return _amount * uint256(price) / 10**decimals;
    }
