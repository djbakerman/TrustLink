// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./Escrow.sol";

contract EscrowFactory {
    mapping(address => Escrow) public escrowAccounts;
    uint256 public nextAccountId;

    event UserEscrowCreated(address indexed user, address indexed escrow);

    function getOrCreateEscrowAccount() public returns (Escrow) {
        Escrow userEscrow = escrowAccounts[msg.sender];
        if (address(userEscrow) == address(0)) {
            userEscrow = new Escrow();
            escrowAccounts[msg.sender] = userEscrow;
            emit UserEscrowCreated(msg.sender, address(userEscrow));
            nextAccountId++;
        }
        return userEscrow;
    }

    function getNumberEscrowAccounts() public view returns (uint256) {
        return (nextAccountId);
    }
}
