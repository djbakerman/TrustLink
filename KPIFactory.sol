// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./KPI.sol";
import "./KPIProxy.sol";

// This contract is a factory for creating and managing KPI contracts
contract KPIFactory {
    // Mapping to store KPI contracts for each escrow
    mapping(address => mapping(uint256 => address)) public kpiContracts;
    // Address of the KPIProxy contract
    address public kpiProxyAddress;

    // Event emitted when a new KPI contract is created
    event KPIContractCreated(uint256 indexed escrowId, address indexed escrowAddress, address kpiContract);

    // Constructor sets the address of the KPIProxy contract
    constructor(address _kpiProxyAddress) {
        kpiProxyAddress = _kpiProxyAddress;
    }

    // Function to get or create a KPI contract for a given escrow
    function getOrCreateKPIForEscrow(uint256 _escrowId, address _escrowAddress, address _sender) public returns (address) {
        // If there is no KPI contract for the given escrow, create a new one
        if (kpiContracts[_escrowAddress][_escrowId] == address(0)) {
            KPI newKPI = new KPI(_escrowAddress, _sender);
            kpiContracts[_escrowAddress][_escrowId] = address(newKPI);

            // Register the new KPI contract with the KPIProxy contract
            KPIProxy(kpiProxyAddress).registerKPI(newKPI);

            // Emit the event when a new KPI contract is created
            emit KPIContractCreated(_escrowId, _escrowAddress, address(newKPI));

            return address(newKPI);
        } else {
            // If a KPI contract for the given escrow already exists, return its address
            return kpiContracts[_escrowAddress][_escrowId];
        }
    }
} // KPIFactory
