// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDiamondCut Interface
 * @dev Interface for DiamondCut contract based on EIP-2535 Diamonds.
 *      Author: Nick Mudge (nick(at)perfectabstractions.com | https://twitter.com/mudgen)
 *      EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 *      This interface allows for adding, replacing, or removing multiple functions in a Diamond.
 */
interface IDiamondCut {
    /// @notice Enum for specifying the action type for a facet function update.
    enum FacetCutAction {
        Add, // Add a new function to the Diamond
        Replace, // Replace an existing function in the Diamond
        Remove // Remove a function from the Diamond
    }
    // Add=0, Replace=1, Remove=2

    /// @notice Struct defining a FacetCut, which specifies updates to a Diamond's functions.
    /// @param facetAddress The address of the facet contract containing the function logic.
    /// @param action The action type (Add, Replace, Remove) for the function update.
    /// @param functionSelectors The array of function selectors (bytes4) being updated.
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Adds, replaces, or removes any number of functions on the Diamond, and optionally executes a delegatecall.
    /// @param _diamondCut An array of FacetCut structs detailing the updates to be made to the Diamond.
    /// @param _init The address of the contract or facet to execute _calldata on.
    /// @param _calldata Data for making a function call, including the function selector and its arguments.
    ///                  This is executed with delegatecall on the _init address.
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    /// @notice Emitted when a DiamondCut is performed, providing details of the changes.
    /// @param _diamondCut The array of FacetCut structs that were executed.
    /// @param _init The address of the contract or facet on which _calldata was executed.
    /// @param _calldata The calldata that was executed on the _init address.
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}
