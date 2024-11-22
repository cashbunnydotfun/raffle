// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDiamond {
    function initialize() external;
    function transferOwnership(address _newOwner) external;
    function owner() external view returns (address);
}
