// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./KPI.sol";

contract KPIFactory {
    mapping(address => mapping(uint256 => address)) public kpiContracts;

    function getOrCreateKPIForEscrow(uint256 _escrowId, address _escrowAddress) public returns (address) {
        if (kpiContracts[_escrowAddress][_escrowId] == address(0)) {
            KPI newKPI = new KPI(_escrowId, _escrowAddress);
            kpiContracts[_escrowAddress][_escrowId] = address(newKPI);

            // Emit the event when a new KPI contract is created
            emit KPIContractCreated(_escrowId, _escrowAddress, address(newKPI));

            return address(newKPI);
        } else {
            return kpiContracts[_escrowAddress][_escrowId];
        }
    }
}
