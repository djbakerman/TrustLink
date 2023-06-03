// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

// This is the interface for the KPI contract
interface IKPI {
    // Event emitted when a new KPI is created
    event KPICreated(bytes32 indexed kpiId, uint256 kpiThreshold, string kpiPath, string kpiUrl);
    // Event emitted when a KPI is updated
    event KPIUpdated(bytes32 indexed kpiId, uint256 newValue, bool violationStatus);
    // Event emitted when a KPI is deleted
    event KPIDeleted(bytes32 indexed kpiId, uint256 escrowId);
    // Event emitted when a KPI point value is fetched
    event FetchKPIPointV(bytes32 indexed requestId, uint256 pointValue);

    // Creates a new KPI point with the given details
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external returns (bytes32);

    // Manually sets the value of a KPI point and checks if the KPI has been violated
    function setKPIPointValue(bytes32 _kpiId, uint256 _newValue) external;

    // Calls the function to fetch the value of a KPI point
    function callFetchKPIPointValue(bytes32 _kpiId) external;

    // Deletes a KPI point using its ID
    function deleteKPIPoint(bytes32 _kpiId) external;

    // Returns the array of KPIs for a given escrow ID
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory);

    // Gets the last value and details of a KPI using its ID
    function getKPILastValue(bytes32 _kpiId) external view returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        string memory kpiUrl,
        bool kpiViolationStatus,
        bool kpiViolationPaid
    );

    // Allows the contract owner to withdraw LINK tokens
    function withdrawLink() external;
} // IKPI
