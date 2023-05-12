// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

// IKPIFactory is an interface to define the required functions for the KPIFactory contract.
interface IKPIFactory {
    // Creates a new KPI contract instance for the sender.
    function createKPIContract() external returns (address);

    // Event emitted when a new KPI contract is created.
    event KPICreated(address indexed kpiAddress, address indexed creator);
}
