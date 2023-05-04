// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository
//working version

pragma solidity ^0.8.0;

interface KPIInterface {
    function setKPI(bytes32 _kpiID, uint256 _threshold) external;
    function setKPIURL(bytes32 _kpiID, string calldata _url) external;
    function checkKPI(bytes32 _kpiID) external returns (bool);
}
