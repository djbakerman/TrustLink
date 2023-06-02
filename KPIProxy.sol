// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./KPI.sol";

contract KPIProxy is KeeperCompatibleInterface {
    KPI[] public kpis;
    uint256 public lastFetchTime;
    uint256 public minTimeBetweenFetches = 15 minutes;

    function registerKPI(KPI kpi) external {
        kpis.push(kpi);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastFetchTime) > minTimeBetweenFetches;
        performData = checkData; // Pass the checkData to performUpkeep
    }

    function performUpkeep(bytes calldata performData) external override {
        // Loop over all registered KPI contracts and fetch their values
        for (uint i = 0; i < kpis.length; i++) {
            KPI kpi = kpis[i];
            for (uint256 j = 0; j < kpi.getEscrowKPIs(i).length; j++) {
                bytes32 kpiId = kpi.getEscrowKPIs(i)[j];
                (, , string memory kpiPath, string memory kpiUrl, , ) = kpi.getKPILastValue(kpiId);
                kpi.fetchKPIPointValue(kpiPath, kpiUrl);
            }
        }

        lastFetchTime = block.timestamp; // Update the lastFetchTime to the current timestamp
    }
}
