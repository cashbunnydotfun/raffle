// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IERC173 Interface
/// @dev Interface for ERC-173 Contract Ownership Standard as defined in EIP-173.
///      ERC-173 provides a standard interface for ownership of contracts.
///      Note: The ERC-165 identifier for this interface is 0x7f5828d0.
///      This interface is compliant with ERC-165 for interface detection.
interface IERC173 { /* is ERC165 */
    /// @notice Emitted when ownership of a contract is transferred.
    /// @param previousOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Retrieves the address of the current owner.
    /// @dev Owner is the address that can transfer ownership to a new address.
    /// @return owner_ The current owner's address of the contract.
    function owner() external view returns (address owner_);

    /// @notice Transfers ownership of the contract to a new account (`_newOwner`).
    /// @dev Can only be called by the current owner.
    ///      Set `_newOwner` to the zero address to renounce any ownership, making the contract ownerless.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) external;
}
