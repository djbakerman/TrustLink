// SPDX-License-Identifier: LicenseRef-Proprietary
// see LICENSE in the source repository

pragma solidity ^0.8.0;

interface IEscrow {
    event EscrowCreated(uint256 indexed escrowId, address indexed sender, uint256 amount);
    event EscrowFulfilled(uint256 indexed escrowId);
    event RecipientAdded(uint256 indexed escrowId, address indexed recipient);
    event RecipientAgreementChanged(uint256 indexed escrowId, address indexed recipient, bool agrees);

    function createEscrow(address[] memory _recipients, uint256 _amount) external payable returns (uint256);
    function negotiateEscrow(uint256 _escrowId, uint256 _negotiatedAmount) external;
    function fulfillEscrow(uint256 _escrowId) external returns (bool);
    function setRecipientAgrees(uint256 _escrowId, bool _agrees) external;
    function getRecipientAgrees(uint256 _escrowId, address _recipient) external view returns (bool);
    function areAllRecipientsAgreed(uint256 _escrowId) external view returns (bool);
}
