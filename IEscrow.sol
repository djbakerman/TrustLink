// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

// The IEscrow interface contains the event declarations and function signatures
// for the external view functions in the Escrow.sol contract.
interface IEscrow {
    // Event emitted when a new escrow is created.
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 amount);

    // Event emitted when a recipient is added to an escrow.
    event RecipientAdded(uint256 indexed escrowId, address indexed recipient);

    // Event emitted when an escrow is fulfilled.
    event EscrowFulfilled(uint256 indexed escrowId);

    // Event emitted when a KPI contract address is set for a sender.
    event KPIContractAddressSet(address indexed sender, address indexed kpiContractAddress);

    // Event emitted when a recipient changes their agreement status.
    event RecipientAgreementChanged(uint256 indexed escrowId, address indexed recipient, bool agrees);

    // Checks if the specified escrow is fulfilled.
    function isFulfilled(uint256 escrowId) external view returns (bool);

    // Returns the next escrow ID.
    function getNextEscrowId() external view returns (uint256);
}
