// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IEscrow.sol";

// The Escrow contract is a simple escrow contract where the sender can create
// an escrow, and the sender and recipient can negotiate the amount to be released.
contract Escrow is IEscrow {
    // EscrowInfo struct contains all the details of a specific escrow instance.
    struct EscrowInfo {
        address payable sender;
        address payable[] recipients;
        uint256 amount;
        uint256 negotiated_amount;
        bool isFulfilled;
    }

    // A mapping to store all escrows with their respective IDs.
    mapping(uint256 => EscrowInfo) public escrows;
    uint256 public nextEscrowId;

    // A mapping of escrowId to KPI Contracs
    mapping(uint256 => address) public kpiContractAddresses;

    // Creates a new escrow with the provided recipients, amount, and KPIs, and stores it in the mapping.
    // Returns the escrow ID.
    function createEscrow(address[] memory _recipients, uint256 _amount) public payable returns (uint256) {
        require(msg.value == _amount, "Amount sent does not match the specified amount.");
        require(_recipients.length > 0, "At least one recipient is required.");

        // Create a new EscrowInfo struct and store it in the mapping
        EscrowInfo memory newEscrow = EscrowInfo({
            sender: payable(msg.sender),
            recipients: _toPayableArray(_recipients),
            amount: _amount,
            negotiated_amount: 0,
            isFulfilled: false
        });

        escrows[nextEscrowId] = newEscrow;
        emit EscrowCreated(nextEscrowId, msg.sender, _amount);
        for (uint i = 0; i < _recipients.length; i++) {
            emit RecipientAdded(nextEscrowId, _recipients[i]);
        }

        nextEscrowId++;
        return nextEscrowId - 1;
    } // end of createEscrow

    // Helper function to convert an address array to a payable address array
    function _toPayableArray(address[] memory _addresses) private pure returns (address payable[] memory) {
        address payable[] memory payableArray = new address payable[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            payableArray[i] = payable(_addresses[i]);
        }
        return payableArray;
    } // end of _toPayableArray

    // Allows the sender or recipient to negotiate the amount to be released from the escrow.
    // Updates the negotiated amount and distributes the funds accordingly.
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) public {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(msg.sender == escrow.sender || isRecipient(msg.sender, escrow.recipients), "Only the sender or recipient can negotiate the escrow.");
        require(_negotiatedAmount <= escrow.amount, "Negotiated amount must be less than or equal to the escrow amount.");

                // Update the negotiated amount and distribute the funds accordingly
        escrow.negotiated_amount = _negotiatedAmount;

        uint256 remaining_amount = escrow.amount - escrow.negotiated_amount;
        distributeAmount(escrow.recipients, escrow.negotiated_amount);
        escrow.sender.transfer(remaining_amount);

        escrow.isFulfilled = true;
        emit EscrowFulfilled(_escrowId);
    } // end of negotiateEscrow

    // Distributes the specified amount equally among the recipients
    function distributeAmount(address payable[] storage _recipients, uint256 _totalAmount) private {
        uint256 numRecipients = _recipients.length;
        uint256 amountPerRecipient = _totalAmount / numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }
    } // end of distributeAmount

    // Checks if the provided address is one of the recipients in the recipients array
    function isRecipient(address _address, address payable[] storage _recipients) private view returns (bool) {
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_address == _recipients[i]) {
                return true;
            }
        }
        return false;
    } // end of isRecipient

    // Allows the sender to fulfill the escrow, releasing the negotiated or full amount to the recipient.
    // Returns true if the escrow is successfully fulfilled.
    function fulfillEscrow(uint256 _escrowId) public returns (bool) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(msg.sender == escrow.sender || msg.sender == kpiContractAddresses[_escrowId], "Only the sender or the associated KPI contract can fulfill the escrow.");
    
        uint256 finalAmount = escrow.negotiated_amount > 0 ? escrow.negotiated_amount : escrow.amount;
        distributeAmount(escrow.recipients, finalAmount);

        escrow.isFulfilled = true;
        emit EscrowFulfilled(_escrowId);

        return true;
    } // end of fulfillEscrow

    // Returns the current balance of the escrow contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    } // end of getContractBalance

    // Check if the escrow is fulfilled
    function isFulfilled(uint256 _escrowId) external view override returns (bool) {
        require(_escrowId < nextEscrowId, "Escrow does not exist.");
        return escrows[_escrowId].isFulfilled;
    }

    function getNextEscrowId() public view override returns (uint256) {
        return nextEscrowId;
    }   // end of getNextEscrowId

    // Sets the KPI contract address associated with the specified escrow ID
    function setKPIContractAddress(uint256 _escrowId, address _kpiContractAddress) public {
        require(kpiContractAddresses[_escrowId] == address(0), "KPI contract address is already set for this escrow.");
        kpiContractAddresses[_escrowId] = _kpiContractAddress;

                // Emit the KPIContractAddressSet event
        emit KPIContractAddressSet(_escrowId, _kpiContractAddress);
    }

    // Returns the recipients of the specified escrow
    function getEscrowRecipients(uint256 _escrowId) public view returns (address[] memory) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];
        address[] memory recipients = new address[](escrow.recipients.length);

        for (uint256 i = 0; i < escrow.recipients.length; i++) {
            recipients[i] = escrow.recipients[i];
        }

        return recipients;
    } // end of getEscrowRecipients
} // end of Escrow
