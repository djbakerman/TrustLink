// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository
//working version

pragma solidity ^0.8.0;

// The Escrow contract is a simple escrow contract where the sender can create
// an escrow, and the sender and recipient can negotiate the amount to be released.
contract Escrow {
    // EscrowInfo struct contains all the details of a specific escrow instance.
    struct EscrowInfo {
        address payable sender;
        address payable recipient;
        uint256 amount;
        uint256 negotiated_amount;
        bool isFulfilled;
    }

    // A mapping to store all escrows with their respective IDs.
    mapping(uint256 => EscrowInfo) public escrows;
    uint256 public nextEscrowId;

    // Creates a new escrow with the provided recipient and amount, and stores it in the mapping.
    function createEscrow(address _recipient, uint256 _amount) public payable returns (uint256) {
        require(msg.value == _amount, "Amount sent does not match the specified amount.");

        EscrowInfo memory newEscrow = EscrowInfo({
            sender: payable(msg.sender),
            recipient: payable(_recipient),
            amount: _amount,
            negotiated_amount: 0,
            isFulfilled: false
        });

        escrows[nextEscrowId] = newEscrow;
        emit EscrowCreated(nextEscrowId, msg.sender, _recipient, _amount);

        nextEscrowId++;
        return nextEscrowId - 1;
    }

    // Allows the sender or recipient to negotiate the amount to be released from the escrow.
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) public {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(msg.sender == escrow.sender || msg.sender == escrow.recipient, "Only the sender or recipient can negotiate the escrow.");
        require(_negotiatedAmount <= escrow.amount, "Negotiated amount must be less than or equal to the escrow amount.");

        escrow.negotiated_amount = _negotiatedAmount;

        uint256 remaining_amount = escrow.amount - escrow.negotiated_amount;
        escrow.recipient.transfer(escrow.negotiated_amount);
        escrow.sender.transfer(remaining_amount);

        escrow.isFulfilled = true;
        emit EscrowFulfilled(_escrowId);
    }

    // Allows the sender to fulfill the escrow, releasing the negotiated or full amount to the recipient.
    function fulfillEscrow(uint256 _escrowId) public {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(msg.sender == escrow.sender, "Only the sender can fulfill the escrow.");
        
        uint256 finalAmount = escrow.negotiated_amount > 0 ? escrow.negotiated_amount : escrow.amount;
        escrow.recipient.transfer(finalAmount);

        escrow.isFulfilled = true;
        emit EscrowFulfilled(_escrowId);
    }

    // Returns the current balance of the escrow contract.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Event triggered when an escrow is created.
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, address indexed recipient, uint256 amount);

    // Event triggered when an escrow is fulfilled.
    event EscrowFulfilled(uint256 indexed escrowId);
}

