// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IEscrow.sol";
import "./KPIFactory.sol";

contract Escrow is IEscrow {
    struct EscrowInfo {
        address payable sender;
        address payable[] recipients;
        uint256 amount;
        uint256 negotiated_amount;
        bool isFulfilled;
        address kpiContract;
    }

    mapping(uint256 => EscrowInfo) public escrows;
    uint256 public nextEscrowId;

    KPIFactory public kpiFactory;

    constructor(address _kpiFactoryAddress) {
        kpiFactory = KPIFactory(_kpiFactoryAddress);
    }

    mapping(uint256 => mapping(address => bool)) public recipientAgreements;

    modifier allRecipientsAgreed(uint256 _escrowId) {
        EscrowInfo storage escrow = escrows[_escrowId];
        for (uint256 i = 0; i < escrow.recipients.length; i++) {
            require(recipientAgreements[_escrowId][escrow.recipients[i]], "All recipients must agree before fulfilling the escrow.");
        }
        _;
    }

    function createEscrow(address[] memory _recipients, uint256 _amount) public payable returns (uint256) {
        require(msg.value == _amount, "Amount sent does not match the specified amount.");
        require(_recipients.length > 0, "At least one recipient is required.");

        EscrowInfo memory newEscrow = EscrowInfo({
            sender: payable(msg.sender),
            recipients: _toPayableArray(_recipients),
            amount: msg.value,
            negotiated_amount: 0,
            isFulfilled: false,
            kpiContract: address(0)
        });

        for (uint256 i = 0; i < newEscrow.recipients.length; i++) {
            recipientAgreements[nextEscrowId][newEscrow.recipients[i]] = false;
        }
        
        escrows[nextEscrowId] = newEscrow;
        emit EscrowCreated(nextEscrowId, msg.sender, msg.value);
        for (uint i = 0; i < _recipients.length; i++) {
            emit RecipientAdded(nextEscrowId, _recipients[i]);
        }

        nextEscrowId++;
        return nextEscrowId - 1;
    }

    function _toPayableArray(address[] memory _addresses) private pure returns (address payable[] memory) {
        address payable[] memory payableArray = new address payable[](_addresses.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            payableArray[i] = payable(_addresses[i]);
        }
        return payableArray;
    }

    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) public allRecipientsAgreed(_escrowId) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(msg.sender == escrow.sender || isRecipient(msg.sender, escrow.recipients), "Only the sender or recipient can negotiate the escrow.");
        require(_negotiatedAmount <= escrow.amount, "Negotiated amount must be less than or equal to the escrow amount.");

        escrow.negotiated_amount = _negotiatedAmount;
    }

    function fulfillEscrow(uint256 _escrowId) public allRecipientsAgreed(_escrowId) returns (bool) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];

        require(!escrow.isFulfilled, "Escrow is already fulfilled.");

        require(msg.sender == escrow.kpiContract || msg.sender == escrow.sender || isRecipient(msg.sender, escrow.recipients), "Only sender or recipients can execute this function.");
        
        uint256 finalAmount = escrow.negotiated_amount > 0 ? escrow.negotiated_amount : escrow.amount;
        if (escrow.negotiated_amount > 0) {
            address payable sender = payable(escrow.sender);
            sender.transfer(escrow.amount - escrow.negotiated_amount);
        }


        distributeAmount(escrow.recipients, finalAmount);

        escrow.isFulfilled = true;
        emit EscrowFulfilled(_escrowId);

        return true;
    }

    function distributeAmount(address payable[] storage _recipients, uint256 _totalAmount) private {
        uint256 numRecipients = _recipients.length;
        uint256 amountPerRecipient = _totalAmount / numRecipients;

        for (uint256 i = 0; i < numRecipients; i++) {
            _recipients[i].transfer(amountPerRecipient);
        }
    }

    function isRecipient(address _address, address payable[] storage _recipients) private view returns (bool) {
        for (uint256 i = 0; i < _recipients.length; i++) {
            if (_address == _recipients[i]) {
                return true;
            }
        }
        return false;
    }

    function isEscrowFulfilled(uint256 _escrowId) external view override returns (bool) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];
        return escrow.isFulfilled;
    }

    function setRecipientAgrees(uint256 _escrowId, bool _agrees) public {
        EscrowInfo storage escrow = escrows[_escrowId];
        require(isRecipient(msg.sender, escrow.recipients), "Only recipients can set their agreement status.");
        recipientAgreements[_escrowId][msg.sender] = _agrees;
        emit RecipientAgreementChanged(_escrowId, msg.sender, _agrees);
    }

    function getRecipientAgrees(uint256 _escrowId, address _recipient) public view returns (bool) {
        return recipientAgreements[_escrowId][_recipient];
    }

    function getNextEscrowId() external view override returns (uint256) {
        return nextEscrowId;
    }

    function getOrCreateKPIForEscrow(uint256 _escrowId) public returns (address) {
        require(_escrowId < nextEscrowId, "Invalid escrow ID.");
        EscrowInfo storage escrow = escrows[_escrowId];
        require(!escrow.isFulfilled, "Escrow is already fulfilled.");
        require(isRecipient(msg.sender, escrow.recipients) || msg.sender == escrow.sender || msg.sender == address(this) || msg.sender == escrow.kpiContract, "Only sender or recipients can execute this function.");
        address _escrowContractAddress = address(this);

        if (escrow.kpiContract == address(0)) {
            address kpiContractAddress = kpiFactory.getOrCreateKPIForEscrow(_escrowId, _escrowContractAddress);
            escrow.kpiContract = kpiContractAddress;
        }
        return escrow.kpiContract;
    }

    function areAllRecipientsAgreed(uint256 _escrowId) public view returns (bool) {
        EscrowInfo storage escrow = escrows[_escrowId];
        for (uint256 i = 0; i < escrow.recipients.length; i++) {
            if (!recipientAgreements[_escrowId][escrow.recipients[i]]) {
                return false;
            }
        }
        return true;
    }
}
