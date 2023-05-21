// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "./IKPIConsumer.sol";

contract KPIConsumer is IKPIConsumer, ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    struct Fulfillment {
        uint256 pointValue;
        bool isFulfilled;
    }

    mapping(bytes32 => Fulfillment) public requestIdToFulfillment;

    bytes32 private jobId;
    uint256 private fee;

    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        setChainlinkOracle(0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 100; // 0,01 * 10**18 (Varies by network and job)
    }

    function fetchKPIPointValue(string memory _kpiPath, string memory _kpiUrl) public returns (bytes32 requestId) {
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
