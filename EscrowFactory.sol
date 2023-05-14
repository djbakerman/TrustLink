// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./Escrow.sol";

contract EscrowFactory {
    mapping(address => Escrow) public userEscrows;
    uint256 public nextUserId;

    event UserEscrowCreated(address indexed user, address indexed escrow);

    function getOrCreateUserEscrow() public returns (Escrow) {
        Escrow userEscrow = userEscrows[msg.sender];
        if (address(userEscrow) == address(0)) {
            userEscrow = new Escrow();
            userEscrows[msg.sender] = userEscrow;
            emit UserEscrowCreated(msg.sender, address(userEscrow));
            nextUserId++;
        }
        return userEscrow;
    }

    function getNumberEscrowUsers() public view returns (uint256) {
        return (nextUserId);
    }
}
