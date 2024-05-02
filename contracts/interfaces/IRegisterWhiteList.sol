// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRegisterWhiteList {
    event SubmitterAdded(address indexed account);
    event SubmitterRemoved(address indexed account);

    function addSubmitter(address account) external;
    function removeSubmitter(address account) external;

    function checkRole(address account) external view returns(bool);
}
