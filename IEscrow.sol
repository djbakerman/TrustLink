// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

// This is the interface for the Escrow contract
interface IEscrow {
    // Event emitted when a new escrow is created
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 amount);
    // Event emitted when an escrow is fulfilled
    event EscrowFulfilled(uint256 indexed escrowId);
    // Event emitted when a new recipient is added to an escrow
    event RecipientAdded(uint256 indexed escrowId, address indexed recipient);
    // Event emitted when a recipient changes their agreement status
    event RecipientAgreementChanged(uint256 indexed escrowId, address indexed recipient, bool agrees);

    // Creates a new escrow with the given recipients and amount
    function createEscrow(address[] memory _recipients, uint256 _amount) external payable returns (uint256);
    // Negotiates the amount of an existing escrow
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) external;
    // Fulfills an existing escrow
    function fulfillEscrow(uint256 _escrowId) external returns (bool);
    // Checks if an escrow is fulfilled
    function isEscrowFulfilled(uint256 _escrowId) external view returns (bool);
    // Sets the agreement status of a recipient for a given escrow
    function setRecipientAgrees(uint256 _escrowId, bool _agrees) external;
    // Gets the agreement status of a recipient for a given escrow
    function getRecipientAgrees(uint256 _escrowId, address _recipient) external view returns (bool);
    // Gets the next escrow ID
    function getNextEscrowId() external view returns (uint256);
    // Checks if all recipients of an escrow have agreed
    function areAllRecipientsAgreed(uint256 _escrowId) external view returns (bool);
    // Gets or creates a KPI for a given escrow
    function getOrCreateKPIForEscrow(uint256 _escrowId) external returns (address);
} // IEscrow
