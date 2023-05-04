// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./KPIInterface.sol";
import "./ChainlinkOracleInterface.sol";

// KPI contract that implements the KPIInterface and interacts with the ChainlinkOracle
contract KPI is KPIInterface {
    // Struct to store KPI information, including the threshold and the URL to fetch data
    struct KPIInfo {
        uint256 threshold;
        string url;
    }

    // Mapping to store KPIs with their unique identifier (KPI ID)
    mapping(bytes32 => KPIInfo) public kpis;
    // Reference to the Chainlink Oracle contract
    ChainlinkOracleInterface public oracle;

    // Constructor that initializes the Chainlink Oracle contract address
    constructor(address _oracleAddress) {
        oracle = ChainlinkOracleInterface(_oracleAddress);
    }

    // Function to set the KPI threshold for a given KPI ID
    function setKPI(bytes32 _kpiID, uint256 _threshold) external override {
        kpis[_kpiID].threshold = _threshold;
    }

    // Function to set the URL used to fetch data for a given KPI ID
    function setKPIURL(bytes32 _kpiID, string calldata _url) external override {
        kpis[_kpiID].url = _url;
    }

    // Function to check if a KPI has been violated by fetching data from the Chainlink Oracle
    // Returns true if the KPI is violated, false otherwise
    function checkKPI(bytes32 _kpiID) external override returns (bool) {
        KPIInfo storage kpi = kpis[_kpiID];
        uint256 result = oracle.requestData(kpi.url);
        return result <= kpi.threshold;
    }
} // KPI
