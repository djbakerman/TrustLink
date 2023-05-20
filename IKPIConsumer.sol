// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IKPIConsumer {
    function fetchKPIPointValue() external returns (bytes32 requestId);
    function fulfill(bytes32 _requestId, uint256 _pointValue) external;
    function withdrawLink() external;
    function pointValue() external view returns (uint256);
}
