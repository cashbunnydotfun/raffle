// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IERC165 Interface
/// @dev Interface for ERC-165 Standard Interface Detection as defined in the ERC-165 specification.
///      This interface allows for the detection of whether a contract implements another interface.
interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @dev Uses less than 30,000 gas.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    ///      An interfaceId is a bytes4 value defined as XOR of all function selectors in the interface.
    ///      It is a unique identifier for each interface.
    /// @return True if the contract implements the queried interface (`interfaceId`),
    ///         false otherwise. Also returns false if `interfaceId` is 0xffffffff.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
