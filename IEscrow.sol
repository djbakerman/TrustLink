// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository
//working version

pragma solidity ^0.8.0;

// IEscrow is an interface to define the required functions for the Escrow contract.
interface IEscrow {
    // Creates a new escrow with the specified recipients and amount, and returns the escrow ID.
    function createEscrow(address[] calldata _recipients, uint256 _amount) external payable returns (uint256);

    function isFulfilled(uint256 _escrowId) external view returns (bool);
    
    function setKPIContractAddress(uint256 _escrowId, address _kpiContractAddress) external;

    // Allows the sender or recipient to negotiate the amount to be released from the escrow.
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) external;
    
    // Allows the sender to fulfill the escrow, releasing the negotiated or full amount to the recipients.
    function fulfillEscrow(uint256 _escrowId) external returns (bool);
    
    // Returns the current balance of the escrow contract.
    function getContractBalance() external view returns (uint256);
    
    // Returns the recipients of the specified escrow.
    function getEscrowRecipients(uint256 _escrowId) external view returns (address[] memory);

    // Returns the nextEscrowId of the specified escrow.
    function getNextEscrowId() external view returns (uint256);

    // Emitted when a new escrow is created.
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 amount);
    
    // Emitted when a recipient is added to an escrow.
    event RecipientAdded(uint256 indexed escrowId, address indexed recipient);
    
    // Emitted when an escrow is fulfilled.
    event EscrowFulfilled(uint256 indexed escrowId);

    // Add the new KPIContractAddressSet event
    event KPIContractAddressSet(uint256 indexed escrowId, address indexed kpiContractAddress);
}
