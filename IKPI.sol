// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

// IKPI is an interface to define the required functions for the KPI contract.
interface IKPI {
    // Creates a new KPI with the provided details, associates it with the given escrow, and stores it in the mapping.
    // Returns the generated KPI ID.
    function createKPIPoint(
        uint256 _escrowId,
        uint256 _kpiThreshold,
        string calldata _kpiPath,
        string calldata _kpiUrl
    ) external returns (bytes32);

    // Fetches the KPI value, updates the violation status, and fulfills the escrow if the KPI has been violated.
    function fetchKPIPointValue(bytes32 _kpiId, uint256 _newValue) external;

    // Gets the KPI details for the given kpiId, including the threshold, current value, path, and violation status.
    function getKPILastValue(bytes32 _kpiId) external view returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        bool kpiViolationStatus
    );

    // Deletes a KPI using the KPIId and removes it from the associated escrow.
    function deleteKPIPoint(bytes32 _kpiId) external;

    // Gets the KPIs associated with a specific escrowId.
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory);

    // Event emitted when a new KPI is created, includes the KPI ID, threshold, path, and URL.
    event KPICreated(bytes32 indexed kpiId, uint256 kpiThreshold, string kpiPath, string kpiUrl);
    
    // Event emitted when a KPI is updated with a new value, includes the KPI ID, value, and violation status.
    event KPIUpdated(bytes32 indexed kpiId, uint256 kpiValue, bool kpiViolationStatus);
    
    // Event emitted when a KPI is deleted, includes the KPI ID and the associated escrow ID.
    event KPIDeleted(bytes32 indexed kpiId, uint256 indexed escrowId);
}
