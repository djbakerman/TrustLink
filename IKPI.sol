// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IKPI {
    // Events
    event KPICreated(bytes32 indexed kpiId, uint256 kpiThreshold, string kpiPath, string kpiUrl);
    event KPIUpdated(bytes32 indexed kpiId, uint256 newValue, bool kpiViolationStatus);
    event KPIUpdated(bytes32 indexed kpiId, uint256 newValue, bool kpiViolationPaid);
    event KPIDeleted(bytes32 indexed kpiId, uint256 escrowId);

    // Create a new KPI
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external returns (bytes32);

    // Update the KPI value and check if the KPI has been violated
    function fetchKPIPointValue(bytes32 _kpiId, uint256 _newValue) external;

    // Delete a KPI using the KPIId
    function deleteKPIPoint(bytes32 _kpiId) external;

    // Get the KPI details for the given kpiId
    function getKPILastValue(bytes32 _kpiId) external view returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        bool kpiViolationStatus
    );

    // Get KPIs associated with an escrow
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory);
}
