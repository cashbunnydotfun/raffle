// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDiamondLoupe Interface
 * @dev Interface for DiamondLoupe based on EIP-2535 Diamonds.
 *      Author: Nick Mudge (nick(at)perfectabstractions.com | https://twitter.com/mudgen)
 *      EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 *      This interface provides functionalities to inspect a Diamond's facets and their functions.
 *      A loupe is a small magnifying glass used to look at diamonds, symbolizing the inspection capability.
 */
interface IDiamondLoupe {
    /// @notice Struct representing a Facet.
    /// @param facetAddress The address of the facet.
    /// @param functionSelectors The function selectors (bytes4) implemented by the facet.
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their function selectors for the Diamond.
    /// @dev This function can be used by tools to inspect the Diamond.
    /// @return facets_ An array of Facet structs, each containing a facet address and its function selectors.
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets the function selectors provided by a specific facet.
    /// @dev This function is helpful to understand the specific functionality of a single facet.
    /// @param _facet The address of the facet to inspect.
    /// @return facetFunctionSelectors_ An array of function selectors (bytes4) implemented by the given facet.
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Gets all the facet addresses that are used in the Diamond.
    /// @return facetAddresses_ An array of addresses of all facets used by the Diamond.
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Finds the facet address associated with a specific function selector.
    /// @dev Returns address(0) if the facet with the given selector is not found.
    /// @param _functionSelector The function selector to query.
    /// @return facetAddress_ The address of the facet that implements the given selector, or address(0) if not found.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
