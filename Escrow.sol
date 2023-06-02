// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IEscrow.sol";
import "./KPIFactory.sol";

// Main contract for handling escrow transactions
contract Escrow is IEscrow {
    // Struct for storing escrow information
    struct EscrowInfo {
        address payable sender; // Address of the sender
        address payable[] recipients; // Array of recipient addresses
        uint256 amount; // Amount in the escrow
        uint256 negotiated_amount; // Negotiated amount in the escrow
        bool isFulfilled; // Flag to check if the escrow is fulfilled
        address kpiContract; // Address of the KPI contract
    }

    // Mapping to store escrow information against escrow ID
    mapping(uint256 => EscrowInfo) public escrows;
    // Variable to store the next escrow ID
    uint256 public nextEscrowId;

    // Instance of the KPIFactory contract
    KPIFactory public kpiFactory;

    // Constructor to initialize the KPIFactory contract
    constructor(address _kpiFactoryAddress) {
        kpiFactory = KPIFactory(_kpiFactoryAddress);
    } // constructor

    // Mapping to store recipient agreements against escrow ID
    mapping(uint256 => mapping(address => bool)) public recipientAgreements;

    // Modifier to check if all recipients have agreed
    modifier allRecipientsAgreed(uint256 _escrowId) {
        EscrowInfo storage escrow = escrows[_escrowId];
        // Loop through all recipients and check their agreement status
        for (uint256 i = 0; i < escrow.recipients.length; i++) {
            require(recipientAgreements[_escrowId][escrow.recipients[i]], "All recipients must agree before fulfilling the escrow.");
        }
        _;
    } // allRecipientsAgreed

    // Function to create a new escrow
    function createEscrow(address[] memory _recipients, uint256 _amount) public payable returns (uint256) {
        // Check if the sent amount matches the specified amount
        require(msg.value == _amount, "Amount sent does not match the specified amount.");
        // Check if there is at least one recipient
        require(_recipients.length > 0, "At least one recipient is required.");

        // Create a new escrow
        EscrowInfo memory newEscrow = EscrowInfo({
            sender: payable(msg.sender),
            recipients: _toPayableArray(_recipients),
            amount: msg.value,
            negotiated_amount: 0,
            isFulfilled: false,
            kpiContract: address(0)
        });

        // Set the agreement status of all recipients to false
        for (uint256 i = 0; i < newEscrow.recipients.length; i++) {
            recipientAgreements[nextEscrowId][newEscrow.recipients[i]] = false;
        }
        
        // Store the new escrow in the mapping
        escrows[nextEscrowId] = newEscrow;
        // Emit an event for the creation of the escrow
        emit EscrowCreated(nextEscrowId, msg.sender, msg.value);
        // Emit an event for each recipient added
        for (uint i = 0; i < _recipients.length; i++) {
            emit RecipientAdded(nextEscrowId, _recipients[i]);
        }

        // Increment the escrow ID
        nextEscrowId++;
        return nextEscrowId - 1;
    } //createEscrow

    // Helper function to convert an array of addresses to payable addresses
    function _toPayableArray(address[] memory _addresses) private pure returns (address payable[] memory) {
        // Create a new array of payable addresses
        address payable[] memory payableArray = new address payable[](_addresses.length);
        // Loop through the input array and convert each address to a payable address
        for (uint256 i = 0; i < _addresses.length; i++) {
            payableArray[i] = payable(_addresses[i]);
        }
        return payableArray;
    } // _toPayableArray

    // Function to negotiate the amount in the escrow
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) public allRecipientsAgreed(_escrowId) {
        // Check if the escrow ID is valid
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];

        // Check if the escrow is already fulfilled
        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        // Check if the sender is the sender or a recipient of the escrow
        require(msg.sender == escrow.sender || isRecipient(msg.sender, escrow.recipients), "Only the sender or recipient can negotiate the escrow.");
        // Check if the negotiated amount is less than or equal to the escrow amount
        require(_negotiatedAmount <= escrow.amount, "Negotiated amount must be less than or equal to the escrow amount.");

        // Set the negotiated amount in the escrow
        escrow.negotiated_amount = _negotiatedAmount;
    } // negotiateEscrow

    // Function to fulfill the escrow
    function fulfillEscrow(uint256 _escrowId) public allRecipientsAgreed(_escrowId) returns (bool) {
        // Check if the escrow ID is valid
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];

        // Check if the escrow is already fulfilled
        require(!escrow.isFulfilled, "Escrow is already fulfilled.");

        // Check if the sender is the sender, a recipient, or the KPI contract of the escrow
        require(msg.sender == escrow.kpiContract || msg.sender == escrow.sender || isRecipient(msg.sender, escrow.recipients), "Only sender or recipients can execute this function.");
        
        // Determine the final amount to distribute
        uint256 finalAmount = escrow.negotiated_amount > 0 ? escrow.negotiated_amount : escrow.amount;
        // If a negotiation took place, transfer the remaining amount back to the sender
        if (escrow.negotiated_amount > 0) {
            address payable sender = payable(escrow.sender);
            sender.transfer(escrow.amount - escrow.negotiated_amount);
        }

        // Distribute the final amount among the recipients
        distributeAmount(escrow.recipients, finalAmount);

        // Mark the escrow as fulfilled
        escrow.isFulfilled = true;
        // Emit an event for the fulfillment of the escrow
        emit EscrowFulfilled(_escrowId);

        return true;
    } // fulfillEscrow

    // Helper function to distribute the amount among recipients
    function distributeAmount(address payable[] storage _recipients, uint256 _totalAmount) private {
        // Calculate theamount to distribute to each recipient
        uint256 numRecipients = _recipients.length;
        uint256 amountPerRecipient = _totalAmount / numRecipients;

        // Loop through the recipients and transfer the amount
        for (uint256 i = 0; i < numRecipients; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }
    } // distributeAmount

    // Helper function to check if an address is a recipient
    function isRecipient(address _address, address payable[] storage _recipients) private view returns (bool) {
        // Loop through the recipients and check if the address is a recipient
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_address == _recipients[i]) {
                return true;
            }
        }
        return false;
    } // isRecipient

    // Function to check if an escrow is fulfilled
    function isEscrowFulfilled(uint256 _escrowId) external view override returns (bool) {
        // Check if the escrow ID is valid
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];
        // Return the fulfillment status of the escrow
        return escrow.isFulfilled;
    } // isEscrowFulfilled

    // Function to set the agreement status of a recipient
    function setRecipientAgrees(uint256 _escrowId, bool _agrees) public {
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];
        // Check if the sender is a recipient of the escrow
        require(isRecipient(msg.sender, escrow.recipients), "Only recipients can set their agreement status.");
        // Set the agreement status of the recipient
        recipientAgreements[_escrowId][msg.sender] = _agrees;
        // Emit an event for the change in agreement status
        emit RecipientAgreementChanged(_escrowId, msg.sender, _agrees);
    } // setRecipientAgrees

    // Function to get the agreement status of a recipient
    function getRecipientAgrees(uint256 _escrowId, address _recipient) public view returns (bool) {
        // Return the agreement status of the recipient
        return recipientAgreements[_escrowId][_recipient];
    } // getRecipientAgrees

    // Function to get the next escrow ID
    function getNextEscrowId() external view override returns (uint256) {
        // Return the next escrow ID
        return nextEscrowId;
    } // getNextEscrowId

    // Function to get or create a KPI for an escrow
    function getOrCreateKPIForEscrow(uint256 _escrowId) public returns (address) {
        // Check if the escrow ID is valid
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];
        // Check if the escrow is already fulfilled
        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        // Check if the sender is the sender, a recipient, the contract itself, or the KPI contract of the escrow
        require(isRecipient(msg.sender, escrow.recipients) || msg.sender == escrow.sender || msg.sender == address(this) || msg.sender == escrow.kpiContract, "Only sender or recipients can execute this function.");
        address_escrowContractAddress = address(this);

        // If the KPI contract does not exist, create a new one
        if (escrow.kpiContract == address(0)) {
            address kpiContractAddress = kpiFactory.getOrCreateKPIForEscrow(_escrowId, _escrowContractAddress, msg.sender);
            escrow.kpiContract = kpiContractAddress;
        }
        // Return the address of the KPI contract
        return escrow.kpiContract;
    } // getOrCreateKPIForEscrow

    // Function to check if all recipients have agreed
    function areAllRecipientsAgreed(uint256 _escrowId) public view returns (bool) {
        // Get the escrow from the mapping
        EscrowInfo storage escrow = escrows[_escrowId];
        // Loop through all recipients and check their agreement status
        for (uint256 i = 0; i < escrow.recipients.length; i++) {
            if (!recipientAgreements[_escrowId][escrow.recipients[i]]) {
                return false;
            }
        }
        // Return true if all recipients have agreed
        return true;
    } // areAllRecipientsAgreed
} // Escrow
