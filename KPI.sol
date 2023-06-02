// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IKPI.sol";
import "./IEscrow.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

// KPI contract that interacts with the Chainlink network to fetch data from an external API
contract KPI is IKPI, ChainlinkClient, ConfirmedOwner {
    // Struct to store all the details of a specific KPI instance
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

    // Instance of the Escrow contract
    IEscrow public escrow;

    // Mapping to store KPIs with their respective kpiIds
    mapping(bytes32 => KPIInfo) public kpis;

    // Mapping to store an array of KPIs for each escrowId
    mapping(uint256 => bytes32[]) public escrowKPIs;

    // Using Chainlink for Chainlink.Request
    using Chainlink for Chainlink.Request;

    // Struct to store fulfillment details
    struct Fulfillment {
        uint256 pointValue;
        bool isFulfilled;
    }

    // Mapping to store fulfillment details for each requestId
    mapping(bytes32 => Fulfillment) public requestIdToFulfillment;

    // Chainlink job ID
    bytes32 private jobId;
    // Chainlink fee
    uint256 private fee;

    // The minimum time between fetches
    uint256 public minTimeBetweenFetches = 15 minutes;
    // The last time the KPI was fetched
    uint256 public lastFetchTime = 0;

    // Constructor to set the escrow contract address, the sender as the owner, the Chainlink token address, the Chainlink oracle address, the job ID, and the fee
    constructor(address _escrow, address _sender) ConfirmedOwner(_sender) {
        escrow = IEscrow(_escrow);
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 100; // 0,01 * 10**18 (Varies by network and job)
    } // constructor

    // Function to generate a unique KPI ID
    function _generateKPIId() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, msg.sender));
    } // _generateKPIId

    // Function to create a new KPI with the provided details, and stores it in the mapping
    function createKPIPoint(uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external override returns (bytes32) {
        // Ensure the escrow exists
        require(_escrowId < escrow.getNextEscrowId(), "Escrow does not exist.");
        require(!escrow.isEscrowFulfilled(_escrowId), "Escrow has already been fulfilled.");

        bytes32 kpiId = _generateKPIId();

        address _escrowContract = address(escrow);

        _kpiThreshold = _kpiThreshold  * 10**18;

        // Create a new KPI
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

        // Store the new KPI in the mapping
        kpis[kpiId] = newKPI;
        escrowKPIs[_escrowId].push(kpiId);

        // Emit the KPICreated event
        emit KPICreated(kpiId, _kpiThreshold, _kpiPath, _kpiUrl);

        return kpiId;
    } // end of createKPIPoint

    // Function to manually update the KPI value and checks if the KPI has been violated
    function setKPIPointValue(bytes32 _kpiId, uint256 _newValue) external override {
        KPIInfo storage kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        // Update the KPI value
        kpi.kpiValue = _newValue;
        kpi.kpiViolationStatus = _newValue >= kpi.kpiThreshold;
        if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        // Emit the KPIUpdated event
        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationStatus);
        emit KPIUpdated(_kpiId, _newValue, kpi.kpiViolationPaid);
    } // end of setKPIPointValue

    // Function to call the fetchKPIPointValue function with the KPI path and URL
    function callFetchKPIPointValue(bytes32 _kpiId) external {
        KPIInfo storage kpi = kpis[_kpiId];
        kpi.requestId = fetchKPIPointValue(kpi.kpiPath, kpi.kpiUrl);
    } // callFetchKPIPointValue

    // Function to get the fulfilled point value and update the KPI value and violation status
    function callGetfulfilledPointValue(bytes32 _kpiId) internal {
        KPIInfo storage kpi = kpis[_kpiId];
        kpi.kpiValue = requestIdToFulfillment[kpi.requestId].pointValue;

        kpi.kpiViolationStatus = kpi.kpiValue >= kpi.kpiThreshold;
        if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        // Emit the KPIUpdated event
        emit KPIUpdated(_kpiId, kpi.kpiValue, kpi.kpiViolationStatus);
        emit KPIUpdated(_kpiId, kpi.kpiValue, kpi.kpiViolationPaid);
    } // callGetfulfilledPointValue

    // Function to delete a KPI using the KPI ID
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

    // Function to return an array of KPI IDs for a given escrow ID
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory) {
        return escrowKPIs[_escrowId];
    } // getEscrowKPIs

    // Function to return the KPI details for a given KPI ID
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

    // Function to send a GET request to the specified URL using the Chainlink network and return the request ID
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
    } // fetchKPIPointValue

    // Function to update the point value and fulfillment status when the Chainlink network fulfills the request
    function fulfill(bytes32 _requestId, uint256 _pointValue) public recordChainlinkFulfillment(_requestId) {
        requestIdToFulfillment[_requestId].pointValue = _pointValue;
        requestIdToFulfillment[_requestId].isFulfilled = true;

        // Call callGetfulfilledPointValue after the KPI point value has been updated
        callGetfulfilledPointValue(_requestId);
        
        emit FetchKPIPointV(_requestId, _pointValue);
    } // fulfill

    // Function to withdraw LINK tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    } // withdrawLink
} // KPI
