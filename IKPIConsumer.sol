// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IKPIConsumer {
    function fetchKPIPointValue(string memory kpiPath, string memory kpiUrl) external returns (bytes32 requestId);
    function fulfill(bytes32 _requestId, uint256 _pointValue) external;
    function withdrawLink() external;
    function getfulfilledPointValue(bytes32 requestId) external returns (uint256);

    event FetchKPIPointV(bytes32 indexed requestId, uint256 pointValue);
}
