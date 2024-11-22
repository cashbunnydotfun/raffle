// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function getFunctionSelectors() external pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = bytes4(keccak256("owner()"));
        selectors[1] = bytes4(keccak256("transferOwnership(address)"));

        // Add more if there are more functions.
        return selectors;
    }
}
