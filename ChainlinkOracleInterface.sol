// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface ChainlinkOracleInterface {
    function requestData(string calldata _url) external returns (uint256);
}
