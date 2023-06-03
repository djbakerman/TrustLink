// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./KPI.sol";

// This contract is a proxy for managing KPI contracts and their upkeep
contract KPIProxy is KeeperCompatibleInterface,ChainlinkClient, ConfirmedOwner {
    // Array to store all registered KPI contracts
    KPI[] public kpis;
    // The last time the KPIs were fetched
    uint256 public lastFetchTime;
    // The minimum time between fetches
    uint256 public minTimeBetweenFetches = 15 minutes;
    // Boolean to pause or unpause the contract
    bool public paused = false;

    using Chainlink for Chainlink.Request;

    // Constructor sets the owner of the contract
    constructor() ConfirmedOwner(msg.sender) {
    }

    // Function to register a new KPI contract
    function registerKPI(KPI kpi) external {
        kpis.push(kpi);
    }

    // Function to check if upkeep is needed
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // Pause the function if we don't want it running anymore
        if (paused) {
            return (false, "");
        }

        // Upkeep is needed if the time since the last fetch is greater than the minimum time between fetches
        upkeepNeeded = (block.timestamp - lastFetchTime) > minTimeBetweenFetches;
        performData = checkData; // Pass the checkData to performUpkeep
    }

    // Function to withdraw LINK tokens
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    // Function to pause the contract
    function pause() public onlyOwner {
        paused = true;
    }

    // Function to unpause the contract
    function unpause() public onlyOwner {
        paused = false;
    }

    // Function to perform upkeep
    function performUpkeep(bytes calldata /*performData*/) external override {
        // Loop over all registered KPI contracts and fetch each KPI value therein
        for (uint i = 0; i < kpis.length; i++) {
            KPI kpi = kpis[i];
            for (uint256 j = 0; j < kpi.getEscrowKPIs(i).length; j++) {
                bytes32 kpiId = kpi.getEscrowKPIs(i)[j];
                kpi.callFetchKPIPointValue(kpiId);
            }
        }

        // Update the lastFetchTime to the current timestamp
        lastFetchTime = block.timestamp;
    }
} // KPIProxy
