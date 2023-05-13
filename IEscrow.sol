// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IEscrow {
    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 amount);
    event RecipientAdded(uint256 indexed escrowId, address indexed recipient);
    event EscrowFulfilled(uint256 indexed escrowId);
    event RecipientAgreementChanged(uint256 indexed escrowId, address indexed recipient, bool agrees);
    event KPIContractAddressSet(address indexed sender, address kpiContractAddress);

    // Create a new escrow contract with the provided recipients and amount
    function createEscrowContract(address[] memory _recipients, uint256 _amount) external payable returns (uint256);

    // Fulfill the escrow, releasing the negotiated or full amount to the recipients
    function fulfillEscrow(uint256 _escrowId) external returns (bool);

    // Negotiate the amount to be released from the escrow
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) external;

    // Check if the escrow is fulfilled
    function isFulfilled(uint256 _escrowId) external view returns (bool);

    // Get the next escrow ID
    function getNextEscrowId() external view returns (uint256);

    // Set the KPI contract address for a sender
    function setKPIContractAddress(address _kpiContractAddress) external;

    // Get the KPI contract address for a sender
    function getKPIContractAddress() external view returns (address);

    // Get the recipients of the specified escrow
    function getEscrowRecipients(uint256 _escrowId) external view returns (address[] memory);

    // Set the recipient's agreement status for a specific escrow
    function setRecipientAgrees(uint256 _escrowId, bool _agrees) external;

    // Get the recipient's agreement status for a specific escrow
    function getRecipientAgrees(uint256 _escrowId, address _recipient) external view returns (bool);

    // List all recipient statuses for a specific escrow
    function listAllRecipientStatus(uint256 _escrowId) external view returns (address[] memory, bool[] memory);

    // Check if all recipients have agreed for a specific escrow
    function areAllRecipientsAgreed(uint256 _escrowId) external view returns (bool);

    // Get the current balance of the escrow contract
    function getContractBalance() external view returns (uint256);
}
