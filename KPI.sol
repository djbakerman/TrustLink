// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "./IKPI.sol";
import "./IEscrow.sol";
import "./KPIProxy.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

// KPI contract that interacts with the Chainlink network to fetch data from an external API
contract KPI is IKPI, KeeperCompatibleInterface, ChainlinkClient, ConfirmedOwner {
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
        uint256 timestamp;
    }

    // Upkeep ID
    uint256 public upkeepID;

    // Instance of the Keeper Registrar contract
    KeeperRegistrarInterface public registrar;

    // Boolean to pause or unpause the contract
    bool public paused = false;

    // Instance of the Escrow contract
    IEscrow public escrow;

    // Mapping to store KPIs with their respective kpiIds
    mapping(bytes32 => KPIInfo) public kpis;

    // Mapping to store an array of KPIs for each escrowId
    mapping(uint256 => bytes32[]) public escrowKPIs;

    // Let's keep track of KPIs are active and valid
    mapping(bytes32 => bool) public validKpiIds;

    // Using Chainlink for Chainlink.Request
    using Chainlink for Chainlink.Request;

    // Add a new mapping to store the association between requestId and kpiId
    mapping(bytes32 => bytes32) public requestIdToKpiId;

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
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        // using sepolia testnet for the hackathon
        registrar = KeeperRegistrarInterface(0x9a811502d843E5a03913d5A2cfb646c11463467A);
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
            timestamp: 0
        });

        // Store the new KPI in the mapping
        kpis[kpiId] = newKPI;
        validKpiIds[kpiId] = true; // Mark the KPI ID as valid
        escrowKPIs[_escrowId].push(kpiId);

        // Emit the KPICreated event
        emit KPICreatedOrUpdated(kpiId, _kpiThreshold, _kpiPath, _kpiUrl);

        return kpiId;
    } // createKPIPoint

    // Function to update a KPI with the provided details
    function updateKPIPoint(bytes32 _kpiId, uint256 _escrowId, uint256 _kpiThreshold, string calldata _kpiPath, string calldata _kpiUrl) external override {
        // Ensure the KPI exists
        require(validKpiIds[_kpiId], "KPI does not exist.");

        // Ensure the escrow exists and has not been fulfilled
        require(_escrowId < escrow.getNextEscrowId(), "Escrow does not exist.");
        require(!escrow.isEscrowFulfilled(_escrowId), "Escrow has already been fulfilled.");

        KPIInfo storage kpiToUpdate = kpis[_kpiId];

        _kpiThreshold = _kpiThreshold  * 10**18;

        // Update the KPI fields
        kpiToUpdate.escrowId = _escrowId;
        kpiToUpdate.kpiThreshold = _kpiThreshold;
        kpiToUpdate.kpiPath = _kpiPath;
        kpiToUpdate.kpiUrl = _kpiUrl;

        // Emit an event for the KPI update
        emit KPICreatedOrUpdated(_kpiId, _kpiThreshold, _kpiPath, _kpiUrl);
    } // updateKPIPoint

    // Function to delete a KPI using the KPI ID
    function deleteKPIPoint(bytes32 _kpiId) external {
        // Ensure the KPI exists
        require(validKpiIds[_kpiId], "KPI does not exist.");

        // Get the escrowId from the KPI
        uint256 escrowId = kpis[_kpiId].escrowId;

        // Remove the KPI ID from the escrow's list of KPIs
        bytes32[] storage kpiIds = escrowKPIs[escrowId];
        for (uint256 i = 0; i < kpiIds.length; i++) {
            if (kpiIds[i] == _kpiId) {
                kpiIds[i] = kpiIds[kpiIds.length - 1];
                kpiIds.pop();
                break;
            }
        }

        // Delete the KPI from the mapping
        delete kpis[_kpiId];
        delete validKpiIds[_kpiId];

        // Emit an event for the KPI deletion
        emit KPIDeleted(_kpiId, escrowId);
    } // deleteKPIPoint

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

        // Emit the KPIPointUpdated event
        emit KPIPointUpdated(_kpiId, _newValue, kpi.kpiViolationStatus, kpi.kpiViolationPaid);

    } // end of setKPIPointValue

    // Function to call the fetchKPIPointValue function with the KPI path and URL
    function callFetchKPIPointValue(bytes32 _kpiId) public {
        KPIInfo memory kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");
        require(!kpi.kpiViolationStatus, "KPI is in violation, create a new KPI.");

        fetchKPIPointValue(kpi.kpiPath, kpi.kpiUrl, _kpiId);
    } // callFetchKPIPointValue

    // Function to get the fulfilled point value and update the KPI value and violation status
    function callGetfulfilledPointValue(bytes32 _kpiId, uint256 _pointValue) internal {
        KPIInfo storage kpi = kpis[_kpiId];
        kpi.kpiValue = _pointValue;
        kpi.timestamp = block.timestamp;

        kpi.kpiViolationStatus = kpi.kpiValue >= kpi.kpiThreshold;
        if (kpi.kpiViolationStatus) {
            kpi.kpiViolationPaid = escrow.fulfillEscrow(kpi.escrowId);
        }

        // Emit the KPIPointUpdated event
        emit KPIPointUpdated(_kpiId, kpi.kpiValue, kpi.kpiViolationStatus, kpi.kpiViolationPaid);

    } // callGetfulfilledPointValue

    // Function to return an array of KPI IDs for a given escrow ID
    function getEscrowKPIs(uint256 _escrowId) external view returns (bytes32[] memory) {
        return escrowKPIs[_escrowId];
    } // getEscrowKPIs

    // Function to return the KPI details for a given KPI ID
    function getKPILastValue(bytes32 _kpiId) public view override returns (
        uint256 kpiThreshold,
        uint256 kpiValue,
        string memory kpiPath,
        string memory kpiUrl,
        bool kpiViolationStatus,
        bool kpiViolationPaid,
        uint256 timestamp
    ) {
        KPIInfo memory kpi = kpis[_kpiId];
        require(kpi.kpiId != 0, "KPI does not exist.");

        kpiThreshold = kpi.kpiThreshold;
        kpiValue = kpi.kpiValue;
        kpiPath = kpi.kpiPath;
        kpiUrl = kpi.kpiUrl;
        kpiViolationStatus = kpi.kpiViolationStatus;
        kpiViolationPaid = kpi.kpiViolationPaid;
        timestamp = kpi.timestamp;
    } // end of getKPILastValue

    // Function to send a GET request to the specified URL using the Chainlink network and return the request ID
    function fetchKPIPointValue(string memory _kpiPath, string memory _kpiUrl, bytes32 _kpiId) private returns (bytes32 requestId) {
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
        requestId =  sendChainlinkRequest(req, fee);

        // Store the kpiId associated with the requestId
        requestIdToKpiId[requestId] = _kpiId;

        return requestId;
    } // fetchKPIPointValue

    // Function to update the point value and fulfillment status when the Chainlink network fulfills the request
    function fulfill(bytes32 _requestId, uint256 _pointValue) public recordChainlinkFulfillment(_requestId) {

        // Retrieve the kpiId using the requestId
        bytes32 kpiId = requestIdToKpiId[_requestId];

        // Call callGetfulfilledPointValue after the KPI point value has been updated
        callGetfulfilledPointValue(kpiId, _pointValue);

        // old school peeps still do garbage collection
        delete requestIdToKpiId[_requestId];
        
        emit FetchKPIPointV(kpiId, _requestId, _pointValue);
    } // fulfill

    // Function to withdraw LINK tokens from the contract
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    } // withdrawLink

    // Function to pause the contract
    function pause() public onlyOwner {
        paused = true;
    }

    // Function to unpause the contract
    function unpause() public onlyOwner {
        paused = false;
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

    // Function to perform upkeep
    function performUpkeep(bytes calldata /* performData */) external override {
        require(!paused, "Contract is paused.");

        // Get the next escrow ID
        uint256 nextEscrowId = escrow.getNextEscrowId();

        // Iterate over all escrows
        for (uint256 i = 0; i < nextEscrowId; i++) {
            // Get the KPI IDs associated with the current escrow
            bytes32[] memory kpiIds = escrowKPIs[i];

            // Iterate over all KPI IDs
            for (uint256 j = 0; j < kpiIds.length; j++) {
                // Get the current KPI ID
                bytes32 kpiId = kpiIds[j];

                // Check if the KPI is valid
                if (validKpiIds[kpiId]) {
                    // Fetch the KPI point value
                    callFetchKPIPointValue(kpiId);
                }
            }
        }

        // Update the last fetch time
        lastFetchTime = block.timestamp;
    } //performUpkeep

    // Function to register upkeep and store the upkeep ID
    function registerUpkeep() public onlyOwner {
        // LINK must be approved for transfer - done once with an infinite approval
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        link.approve(address(registrar), type(uint256).max); // Infinite approval

        // Statically assigned values
        RegistrationParams memory params = RegistrationParams({
            name: "TrustLink",
            encryptedEmail: "0x", // This should be encrypted in a real use case
            upkeepContract: address(this), // The address of the contract that requires upkeep
            gasLimit: 2000000, // The gas limit for the upkeep operation
            adminAddress: msg.sender, // The address of the admin
            checkData: "0x", // Any data that the checkUpkeep function requires
            offchainConfig: "0x", // Any off-chain configuration data
            amount: 5000000000000000000 // Needed 5 LINK minimum
        });

        upkeepID = registrar.registerUpkeep(params);
    } //registerUpkeep

} // KPI
