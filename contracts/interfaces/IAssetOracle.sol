// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAssetOracle {
    function assetPrices(address asset) external view returns(uint256);
}
