// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IKPI.sol";
import "./IEscrow.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract KPI is IKPI,ChainlinkClient, ConfirmedOwner {
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
        bytes32 requestId;
    }

    IEscrow public escrow;

    // A mapping to store KPIs with their respective kpiIds.
    mapping(bytes32 => KPIInfo) public kpis;

    // A mapping to store an array of KPIs for each escrowId.
    mapping(uint256 => bytes32[]) public escrowKPIs;

    using Chainlink for Chainlink.Request;

    struct Fulfillment {
        uint256 pointValue;
        bool isFulfilled;
    }

    mapping(bytes32 => Fulfillment) public requestIdToFulfillment;

    bytes32 private jobId;
    uint256 private fee;

    constructor(address _escrow) ConfirmedOwner(msg.sender) {
        escrow = IEscrow(_escrow);
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 100; // 0,01 * 10**18 (Varies by network and job)
    }

    // Generates a unique KPI ID
    function _generateKPIId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender));
    }

    // Creates a new KPI with the provided details, and stores it in the mapping.
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external override returns (bytes32) {
        // Ensure the escrow exists
        require(_escrowId < escrow.getNextEscrowId(), "Escrow does not exist.");
        require(!escrow.isEscrowFulfilled(_escrowId), "Escrow has already been fulfilled.");

        bytes32 kpiId = _generateKPIId();

        address _escrowContract = address(escrow);

        _kpiThreshold = _kpiThreshold  * 10**18;

        KPIInfo memory newKPI = KPIInfo({
            kpiId: kpiId,
            kpiThreshold: _kpiThreshold,
            kpiValue: 0,
            kpiPath: _kpiPath,
            kpiUrl: _kpiUrl,
            kpiViolationStatus: false,
            kpiViolationPaid: false,
            escrowContract: _escrowContract,
            escrowId: _escrowId,
            requestId: 0
        });

        kpis[kpiId] = newKPI;
        escrowKPIs[_escrowId].push(kpiId);

        // Emit the KPICreated event
        emit KPICreated(kpiId, _kpiThreshold, _kpiPath, _kpiUrl);

        return kpiId;
    } // end of createKPIPoint


    // Manually updates the KPI value and checks if the KPI has been violated.
    function setKPIPointValue(bytes32 _kpiId, uint256 _newValue) external override {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        kpi.kpiValue = _newValue;
        kpi.kpiViolationStatus = _newValue >= kpi.kpiThreshold;
        if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationStatus);
        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationPaid);
    } // end of setKPIPointValue

    function callFetchKPIPointValue(bytes32 _kpiId) external {
        KPIInfo storage kpi = kpis[_kpiId];
        kpi.requestId = fetchKPIPointValue(kpi.kpiPath, kpi.kpiUrl);
    }

    function callGetfulfilledPointValue(bytes32 _kpiId) external {
        KPIInfo storage kpi = kpis[_kpiId];
        kpi.kpiValue = this.getfulfilledPointValue(kpi.requestId);

        kpi.kpiViolationStatus = kpi.kpiValue >= kpi.kpiThreshold;
        if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        emit KPIUpdated(_kpiId, kpi.kpiValue, kpi.kpiViolationStatus);
        emit KPIUpdated(_kpiId, kpi.kpiValue, kpi.kpiViolationPaid);
    }

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
        string memory kpiUrl,
        bool kpiViolationStatus,
        bool kpiViolationPaid
    ) {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        kpiThreshold = kpi.kpiThreshold;
        kpiValue = kpi.kpiValue;
        kpiPath = kpi.kpiPath;
        kpiUrl = kpi.kpiUrl;
        kpiViolationStatus = kpi.kpiViolationStatus;
        kpiViolationPaid = kpi.kpiViolationPaid;
    } // end of getKPILastValue

    function fetchKPIPointValue(string memory _kpiPath, string memory _kpiUrl) private returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add(
            "get",
            _kpiUrl
        );

        req.add("path", _kpiPath); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10 ** 18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function fulfill(bytes32 _requestId, uint256 _pointValue) public recordChainlinkFulfillment(_requestId) {
        requestIdToFulfillment[_requestId].pointValue = _pointValue;
        requestIdToFulfillment[_requestId].isFulfilled = true;
        
        emit FetchKPIPointV(_requestId, _pointValue);
    }

    function getfulfilledPointValue(bytes32 requestId) external view returns (uint256) {
        require(requestIdToFulfillment[requestId].isFulfilled, "Not yet fulfilled");
        return requestIdToFulfillment[requestId].pointValue;
    }

    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
