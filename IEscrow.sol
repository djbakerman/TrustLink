// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository
//working version

pragma solidity ^0.8.0;

interface IEscrow {
    function createEscrow(address _recipient, uint256 _amount) external payable returns (uint256);
    function getContractBalance() external view returns (uint256);
}
