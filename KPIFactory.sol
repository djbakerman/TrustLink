// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./KPI.sol";
import "./KPIProxy.sol";

contract KPIFactory {
    mapping(address => mapping(uint256 => address)) public kpiContracts;
    address public kpiProxyAddress;

    event KPIContractCreated(uint256 indexed escrowId, address indexed escrowAddress, address kpiContract);

    constructor(address _kpiProxyAddress) {
        kpiProxyAddress = _kpiProxyAddress;
    }

    function getOrCreateKPIForEscrow(uint256 _escrowId, address _escrowAddress, address _sender) public returns (address) {
        if (kpiContracts[_escrowAddress][_escrowId] == address(0)) {
            KPI newKPI = new KPI(_escrowAddress, _sender);
            kpiContracts[_escrowAddress][_escrowId] = address(newKPI);

            // Register the new KPI contract with the KPIProxy contract
            KPIProxy(kpiProxyAddress).registerKPI(newKPI);

            // Emit the event when a new KPI contract is created
            emit KPIContractCreated(_escrowId, _escrowAddress, address(newKPI));

            return address(newKPI);
        } else {
            return kpiContracts[_escrowAddress][_escrowId];
        }
    }
}
