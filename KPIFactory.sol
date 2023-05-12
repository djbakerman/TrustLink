// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./KPI.sol";
import "./IEscrow.sol";

contract KPIFactory {
    IEscrow public escrow;
    
    // Mapping to store the KPI contract addresses for each sender address.
    mapping(address => address) public kpiContractAddresses;

    event KPICreated(address indexed kpiAddress, address indexed creator);

    constructor(address _escrow) {
        escrow = IEscrow(_escrow);
    }

    function createKPIContract() public returns (address) {
        require(kpiContractAddresses[msg.sender] == address(0), "KPI contract already exists for the sender.");
        KPI kpi = new KPI(address(escrow));
        kpiContractAddresses[msg.sender] = address(kpi);
        emit KPICreated(address(kpi), msg.sender);
        return address(kpi);
    }
}
