// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

    enum ProofStatus {
        toBeVerified,
        verified,
        verifyFailed
    }

    struct RawTransaction {
        bytes rawData;
        bytes[] utxos;
        ProofStatus status;
    }

    enum AddrType {
        EMPTY,
        P2PK,
        P2PKH,
        P2MS,
        P2SH,
        P2WPKH,
        P2WSH,
        P2TR
    }
    struct Input {
        bytes32 txid;
        uint256 amount;
    }

    struct Output {
        AddrType txType;
        string addr;
        uint256 amount;
    }

    enum ProvingStatus {
        OK,
        InvalidScript
    }

interface IZKPOrder {
    function addTransaction(
        bytes memory rawData,
        bytes[] memory utxos,
        string memory prover,
        bytes memory script
    ) external returns (bytes32);


    function getOrderStatus(bytes32 hash) external view returns(ProofStatus);

    function getOrderDetails(bytes32 hash, string memory network) external view returns (
        bytes32,  //wtxid
        Input[] memory,
        Output[] memory,
        bytes memory, //script
        ProofStatus);

    function getProvingDetail(bytes32 hash, string memory network) external view returns (
        bytes32, //wtxid
        ProvingStatus,
        string memory //proverAddress
    );
}
