// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFacet {
    function getFunctionSelectors() external returns (bytes4[] memory);
}
