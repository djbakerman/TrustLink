// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./Escrow.sol";

// This contract is a factory for creating and managing Escrow contracts
contract EscrowFactory {
    // Mapping to store the escrow accounts associated with each address
    mapping(address => Escrow) public escrowAccounts;
    // The next account ID to be assigned
    uint256 public nextAccountId;
    // The deployed address of the KPIFactory contract
    address public kpiFactoryAddress;

    // Event to be emitted when a new escrow is created
    event UserEscrowCreated(address indexed user, address indexed escrow);

    // Constructor sets the KPIFactory address
    constructor(address _kpiFactoryAddress) {
        kpiFactoryAddress = _kpiFactoryAddress;
    }

    // Function to get or create an escrow account for the sender
    function getOrCreateEscrowAccount() public returns (Escrow) {
        Escrow userEscrow = escrowAccounts[msg.sender];
        // If the user does not have an escrow account, create a new one
        if (address(userEscrow) == address(0)) {
            userEscrow = new Escrow(kpiFactoryAddress); // Pass the KPIFactory address to the Escrow constructor
            escrowAccounts[msg.sender] = userEscrow;
            emit UserEscrowCreated(msg.sender, address(userEscrow));
            nextAccountId++;
        }
        return userEscrow;
    }

    // Function to get the number of escrow accounts
    function getNumberEscrowAccounts() public view returns (uint256) {
        return (nextAccountId);
    }
} // EscrowFactory
