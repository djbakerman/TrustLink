// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IKPI {
    // Event declarations
    event KPICreated(bytes32 indexed kpiId, uint256 kpiThreshold, string kpiPath, string kpiUrl);
    event KPIUpdated(bytes32 indexed kpiId, uint256 newValue, bool violationStatus);
    event KPIDeleted(bytes32 indexed kpiId, uint256 escrowId);
    event FetchKPIPointV(bytes32 indexed requestId, uint256 pointValue);

    // Creates a new KPI with the provided details, and stores it in the mapping.
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external returns (bytes32);

    // Manually updates the KPI value and checks if the KPI has been violated.
    function setKPIPointValue(bytes32 _kpiId, uint256 _newValue) external;

    // Calls the function to fetch the KPI point value.
    function callFetchKPIPointValue(bytes32 _kpiId) external;

    // Calls the function to get the fulfilled point value.
    function callGetfulfilledPointValue(bytes32 _kpiId) external;

    // Deletes a KPI using the KPIId.
    function deleteKPIPoint(bytes32 _kpiId) external;

    // Returns the array of KPIs for the given escrowId.
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory);

    // Gets the KPI details for the given kpiId.
    function getKPILastValue(bytes32 _kpiId) external view returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        string memory kpiUrl,
        bool kpiViolationStatus,
        bool kpiViolationPaid
    );

    // Returns the fulfilled point value for the given requestId.
    function getfulfilledPointValue(bytes32 requestId) external view returns (uint256);

    // Allows the contract owner to withdraw LINK tokens.
    function withdrawLink() external;
}
