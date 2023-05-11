// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IEscrow.sol";
import "./Escrow.sol";

// The EscrowFactory contract is a factory contract that deploys instances of the Escrow contract.
contract EscrowFactory {
    // A mapping to store all deployed Escrow contracts with their respective sender addresses.
    mapping(address => address[]) public escrowContracts;

    // Event emitted when a new Escrow contract is created
    event EscrowContractCreated(address indexed sender, address escrowAddress);

    // Creates a new Escrow contract with the provided recipients and amount and stores its address in the mapping.
    function createEscrowContract(address[] memory _recipients, uint256 _amount) public payable returns (address) {
        require(msg.value == _amount, "Amount sent does not match the specified amount.");
        require(_recipients.length > 0, "At least one recipient is required.");

        // Deploy a new Escrow contract
        Escrow newEscrow = new Escrow{value: msg.value}(_recipients, _amount, msg.sender);

        // Store the deployed Escrow contract address in the mapping
        escrowContracts[msg.sender].push(address(newEscrow));

        emit EscrowContractCreated(msg.sender, address(newEscrow));

        return address(newEscrow);
    }

    // Returns the list of deployed Escrow contracts for a specific sender address
    function getDeployedEscrows(address _sender) public view returns (address[] memory) {
        return escrowContracts[_sender];
    }
}
