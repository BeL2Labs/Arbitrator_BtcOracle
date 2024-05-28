// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IAssetOracle.sol";
import "./interfaces/IRegisterWhiteList.sol";
import "./IArbitrator.sol";
import {MyMath} from "./utils/MyMath.sol";

contract Arbitrator is IArbitrator, OwnableUpgradeable {
    uint256 public arbitrationRequestDuration;
    uint256 public minStakeAmount;
    address public assetOracle;
    address public registerWhiteListContract;

    mapping(address => bool) public agreementContractWhitelist;
    mapping(address => bool) public tokenWhitelist;

    mapping(address => ArbitratorInfo) public arbitratorInfo;
    address[] public arbitratorList;
    mapping(bytes32 => ArbitrationData) public arbitrationData;



    ///@custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(
        address _assetOracle,
        address _registerWhiteListContract
    ) initializer public virtual {
        __Ownable_init(msg.sender);
        assetOracle = _assetOracle;
        registerWhiteListContract = _registerWhiteListContract;
        arbitrationRequestDuration = 72 hours;
        minStakeAmount =  1000 * 1e18; //// 1000 USD
    }

    function registerArbitrator(uint256 _commitPeriod, bytes calldata _btcPublicKey, address _token, uint256 _amount) external override {
        require(_commitPeriod > 0, "Commitment period must be greater than 0");
        require(tokenWhitelist[_token], "Token not whitelisted");
        require(arbitratorInfo[msg.sender].registeredAt == 0, "Arbitrator already registered");
        require(IRegisterWhiteList(registerWhiteListContract).checkRole(msg.sender), "NoPermission");

//        uint256 usdValue = getUsdValue(_token, _amount);
//        require(usdValue >= minStakeAmount, "Staked amount must be greater than minimum stake amount");


        uint256 allow = IERC20(_token).allowance(msg.sender, address(this));
        require(allow >= _amount, "NoApprove");
        bool ok = IERC20Metadata(_token).transferFrom(msg.sender, address(this), _amount);
        require(ok, "TransferTokenFailed");

        arbitratorInfo[msg.sender] = ArbitratorInfo({
            arbitrator: msg.sender,
            commitPeriod: _commitPeriod,
            registeredAt: block.timestamp,
            btcPublicKey: _btcPublicKey,
            stakedToken: _token,
            stakedAmount: _amount
        });
        arbitratorList.push(msg.sender);

        emit ArbitratorRegistered(msg.sender, _commitPeriod, _btcPublicKey, _token, _amount);
    }

    function getArbitratorPublicKey() external view returns(bytes memory) {
        require(arbitratorList.length > 0, "NoRegister");
        return arbitratorInfo[arbitratorList[0]].btcPublicKey;
    }

    function removeArbitrator(address account) private {
        for (uint i = 0; i < arbitratorList.length; i++) {
            if (account == arbitratorList[i]) {
                delete arbitratorList[i];
                for (uint j = i; j < arbitratorList.length -1; j++) {
                    arbitratorList[j] = arbitratorList[j + 1];
                }
                arbitratorList.pop();
                return;
            }
        }
    }

    function exitArbitrator() external override {
        ArbitratorInfo storage info = arbitratorInfo[msg.sender];
        require(info.registeredAt > 0, "Arbitrator not registered");
        require(block.timestamp > info.registeredAt + info.commitPeriod, "Arbitrator still in commitment period");

        address stakedToken = info.stakedToken;
        uint256 stakedAmount = info.stakedAmount;
        delete arbitratorInfo[msg.sender];
        removeArbitrator(msg.sender);

        emit ArbitratorExited(msg.sender, stakedToken, stakedAmount);
    }

    function requestArbitration(bytes memory _btcTxToSign, bytes memory _signature, bytes memory _script, bytes32 _queryId) external payable override {
        require(agreementContractWhitelist[msg.sender], "Agreement contract not whitelisted");
        require(arbitrationData[_queryId].requestID == bytes32(0), "Requested");
        require(arbitrationData[_queryId].status != ArbitrationStatus.Completed, "Completed");
        //TODO add arbitration fee
//        require(msg.value > 0, "Arbitration fee must be greater than 0");

        arbitrationData[_queryId].requestID = _queryId;
        arbitrationData[_queryId].requestTime  = block.timestamp;
        arbitrationData[_queryId].status = ArbitrationStatus.Pending;
        arbitrationData[_queryId].btcTxToSign = _btcTxToSign;
        arbitrationData[_queryId].signature = _signature;
        arbitrationData[_queryId].script = _script;

        emit ArbitrationRequested(_btcTxToSign, _signature, _script, _queryId);
    }

    function submitArbitrationResult(
        bytes32 _queryId,
        bytes memory _signedBtcTx,
        bytes[] memory utxos,
        uint32 blockHeight,
        MerkleProofData calldata merkleProof
    ) external override {
        ArbitratorInfo storage info = arbitratorInfo[msg.sender];
        require(info.registeredAt > 0, "Arbitrator not registered");
        require(block.timestamp <= info.registeredAt + info.commitPeriod, "Arbitrator commitment period ended");

        require(arbitrationData[_queryId].requestTime > 0 &&  arbitrationData[_queryId].requestID > 0, "NoRequest");
        require(arbitrationData[_queryId].status == ArbitrationStatus.Pending, "NotPendingStatus");
        // TODO: 验证_signedBtcTx是否是有效的仲裁结果交易

        arbitrationData[_queryId].btcTxSigned = _signedBtcTx;
        arbitrationData[_queryId].status = ArbitrationStatus.Completed;
        arbitrationData[_queryId].merkleProof.root = merkleProof.root;
        arbitrationData[_queryId].merkleProof.proof = merkleProof.proof;
        arbitrationData[_queryId].merkleProof.leaf = merkleProof.leaf;
        arbitrationData[_queryId].merkleProof.flags = merkleProof.flags;
        arbitrationData[_queryId].utxos = utxos;
        arbitrationData[_queryId].blockHeight = blockHeight;
        emit ArbitrationResultSubmitted(_signedBtcTx, _queryId);
    }

    function reportArbitrator(address[] memory _arbitrators, bytes memory _evidence) external override {
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

    function setAgreementContractWhitelist(address _agreementContract, bool _isWhitelisted) external override onlyOwner {
        agreementContractWhitelist[_agreementContract] = _isWhitelisted;
        emit ContractWhiteListUpdate(_agreementContract, _isWhitelisted);
    }

    function setArbitrationRequestDuration(uint256 _duration) external override onlyOwner {
        arbitrationRequestDuration = _duration;
        emit SetArbitrationRequestDuration(_duration);
    }

    function setTokenWhitelist(address _token, bool _isWhitelisted) external override onlyOwner{
        tokenWhitelist[_token] = _isWhitelisted;
        emit SetTokenWhitelist(_token, _isWhitelisted);
    }

    function setMinStakeAmount(uint256 newAmount) external override onlyOwner {
        minStakeAmount = newAmount;
        emit MinStakeAmountUpdated(newAmount);
    }

    function setRegisterWhiteList(address whiteList) external onlyOwner {
        registerWhiteListContract = whiteList;
        emit SetRegisterWhiteList(whiteList);
    }

    function setAssetOracle(address _oracle) external override onlyOwner {
        assetOracle = _oracle;
        emit SetAssetOracle(_oracle);
    }

    function getArbitratorInfo(address _arbitrator) external view override returns (ArbitratorInfo memory) {
        return arbitratorInfo[_arbitrator];
    }

    function getArbitrationStatus(bytes32 _queryId) external view override returns (ArbitrationStatus) {
        return arbitrationData[_queryId].status;
    }

    function getUsdValue(address _token, uint256 _amount) internal view returns (uint256) {
        require(tokenWhitelist[_token], "NoWhitelisted");
        require(assetOracle != address(0), "NoAssetOracle");
        uint256 amount = getAdjustedAmount(_token, _amount);
        return IAssetOracle(assetOracle).assetPrices(_token) * amount;
    }

    function getAdjustedAmount(address _token, uint256 _tokenAmount) private view returns(uint256) {
        uint256 priceDecimal = 18;
        uint256 tokenDecimal = IERC20Metadata(_token).decimals();
        uint256 adjusted;
        uint256 amount;
        uint256 power;

        if (tokenDecimal < priceDecimal) {
            adjusted = priceDecimal - tokenDecimal;
            power = MyMath.safePower(10, adjusted);
            amount = _tokenAmount * power;
        } else if (tokenDecimal > priceDecimal) {
            adjusted = tokenDecimal - priceDecimal;
            power = MyMath.safePower(10, adjusted);
            amount = _tokenAmount / power;
        } else {
            amount = _tokenAmount;
        }
        return amount;
    }
}
