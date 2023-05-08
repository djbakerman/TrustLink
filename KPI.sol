// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IKPI.sol";
import "./IEscrow.sol";

contract KPI is IKPI {
    // KPIInfo struct contains all the details of a specific KPI instance.
    struct KPIInfo {
        bytes32 kpiId;
        uint256 kpiThreshold;
        uint256 kpiValue;
        string kpiPath;
        string kpiUrl;
        bool kpiViolationStatus;
        bool kpiViolationPaid;
        address escrowContract;
        uint256 escrowId;
    }

    IEscrow public escrow;

    // A mapping to store KPIs with their respective kpiIds.
    mapping(bytes32 => KPIInfo) public kpis;

    // A mapping to store an array of KPIs for each escrowId.
    mapping(uint256 => bytes32[]) public escrowKPIs;

    constructor(address _escrow) {
        escrow = IEscrow(_escrow);
    }

    // Generates a unique KPI ID
    function _generateKPIId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender));
    }

    // Creates a new KPI with the provided details, and stores it in the mapping.
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external override returns (bytes32) {
        // Ensure the escrow exists
        require(_escrowId < escrow.getNextEscrowId(), "Escrow does not exist.");
        require(!escrow.isFulfilled(_escrowId), "Escrow has already been fulfilled.");

        bytes32 kpiId = _generateKPIId();

        address _escrowContract = address(escrow);

        KPIInfo memory newKPI = KPIInfo({
            kpiId: kpiId,
            kpiThreshold: _kpiThreshold,
            kpiValue: 0,
            kpiPath: _kpiPath,
            kpiUrl: _kpiUrl,
            kpiViolationStatus: false,
            kpiViolationPaid: false,
            escrowContract: _escrowContract,
            escrowId: _escrowId
        });

        kpis[kpiId] = newKPI;
        escrowKPIs[_escrowId].push(kpiId);

        // Set the KPI contract address for the corresponding escrowId in the Escrow contract
        escrow.setKPIContractAddress(_escrowId, address(this));

        // Emit the KPICreated event
        emit KPICreated(kpiId, _kpiThreshold, _kpiPath, _kpiUrl);

        return kpiId;
    } // end of createKPIPoint

    // Updates the KPI value and checks if the KPI has been violated.
    function fetchKPIPointValue(bytes32 _kpiId, uint256 _newValue) external override {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        kpi.kpiValue = _newValue;
        kpi.kpiViolationStatus = _newValue >= kpi.kpiThreshold;
                if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationStatus);
        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationPaid);
    } // end of fetchKPIPointValue

    // Deletes a KPI using the KPIId.
    function deleteKPIPoint(bytes32 _kpiId) external {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        // Remove the KPI from the escrowKPIs mapping
        uint256 escrowId;
        bool escrowFound;
        for (uint256 i = 0; i < escrow.getNextEscrowId(); i++) {
            bytes32[] storage kpiIds = escrowKPIs[i];
            for (uint256 j = 0; j < kpiIds.length; j++) {
                if (kpiIds[j] == _kpiId) {
                    kpiIds[j] = kpiIds[kpiIds.length - 1];
                    kpiIds.pop();
                    escrowId = i;
                    escrowFound = true;
                    break;
                }
            }
            if (escrowFound) {
                break;
            }
        }

        require(escrowFound, "KPI not associated with any escrow.");

        // Delete the KPI from the kpis mapping
        delete kpis[_kpiId];

        emit KPIDeleted(_kpiId, escrowId);
    } // end of deleteKPIPoint

    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory) {
        return escrowKPIs[_escrowId];
    }

    // Gets the KPI details for the given kpiId.
    function getKPILastValue(bytes32 _kpiId) external view override returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        bool kpiViolationStatus
    ) {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        kpiThreshold = kpi.kpiThreshold;
        kpiValue = kpi.kpiValue;
        kpiPath = kpi.kpiPath;
        kpiViolationStatus = kpi.kpiViolationStatus;
    } // end of getKPILastValue
}
