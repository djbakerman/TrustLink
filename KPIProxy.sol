// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./KPI.sol";

contract KPIProxy is KeeperCompatibleInterface,ChainlinkClient, ConfirmedOwner {
    KPI[] public kpis;
    uint256 public lastFetchTime;
    uint256 public minTimeBetweenFetches = 15 minutes;
    bool public paused = false;

    using Chainlink for Chainlink.Request;

    constructor() ConfirmedOwner(msg.sender) {
    }

    function registerKPI(KPI kpi) external {
        kpis.push(kpi);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        //pause the function if we don't want it running anymore
        if (paused) {
            return (false, "");
        }

        upkeepNeeded = (block.timestamp - lastFetchTime) > minTimeBetweenFetches;
        performData = checkData; // Pass the checkData to performUpkeep
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
    // Loop over all registered KPI contracts and fetch each kpi values therein
    for (uint i = 0; i < kpis.length; i++) {
        KPI kpi = kpis[i];
        for (uint256 j = 0; j < kpi.getEscrowKPIs(i).length; j++) {
            bytes32 kpiId = kpi.getEscrowKPIs(i)[j];
            kpi.callFetchKPIPointValue(kpiId);
        }
    }

    lastFetchTime = block.timestamp; // Update the lastFetchTime to the current timestamp
}
}
