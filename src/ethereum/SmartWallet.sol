// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {console} from "forge-std/Script.sol";

contract SmartWallet is Ownable, IAccount {
    error SmartWallet__InvalidNonce();
    error SmartWallet__InvalidCaller();
    error SmartWallet__InvalidSignature();
    error SmartWallet__FailedToSendFundsToEntryPoint();
    error SmartWallet__FailedToWithdrawFunds();
    error SmartWallet__FailedToExecuteTransaction();

    using ECDSA for bytes32;

    // EntryPoint contract that handles the bundling of UserOperations
    IEntryPoint private immutable i_entryPoint;
    // Storage for the nonce
    uint256 private _nonce;

    event FundsReceived(address indexed from, uint256 amount);
    event TransactionExecuted(address indexed target, uint256 value, bytes data);

    constructor(address _entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(_entryPoint);
    }

    modifier onlyEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert SmartWallet__InvalidCaller();
        }
        _;
    }

    modifier onlyEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert SmartWallet__InvalidCaller();
        }
        _;
    }

    // This function is required by EIP-4337 and is called by the EntryPoint contract
    // to validate the UserOperation's signature and nonce.
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryPoint
        returns (uint256 validationData)
    {
        // Verify the nonce is correct (simple example, assuming the contract stores a nonce)
        if (userOp.nonce != getNonce()) {
            console.log(getNonce());
            revert SmartWallet__InvalidNonce();
        }

        _validateSignature(userOpHash, userOp);
        // Increment the nonce after successful validation
        // _nonce++;

        _payForGas(missingAccountFunds);

        // If all checks pass, return success

        return SIG_VALIDATION_SUCCESS;
    }

    function _validateSignature(bytes32 userOpHash, PackedUserOperation calldata userOp) internal view {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        (address signer,,) = digest.tryRecover(userOp.signature);
        if (signer != owner() || signer == address(0)) {
            revert SmartWallet__InvalidSignature();
        }
    }

    function _payForGas(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            // Send the missing funds directly to the EntryPoint contract
            (bool success,) = payable(address(i_entryPoint)).call{value: missingAccountFunds}("");
            if (!success) {
                revert SmartWallet__FailedToSendFundsToEntryPoint();
            }
        }
    }

    // This function allows the owner to execute transactions directly through the wallet
    function executeTransaction(address target, uint256 value, bytes calldata data) external onlyEntryPointOrOwner {
        (bool success,) = target.call{value: value}(data);
        if (!success) {
            revert SmartWallet__FailedToExecuteTransaction();
        }

        emit TransactionExecuted(target, value, data);
    }

    // Function to receive funds into the wallet
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    // Fallback function to handle unexpected ETH
    fallback() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    // Withdraw funds from the wallet
    function withdraw(uint256 amount) external onlyOwner {
        (bool success,) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert SmartWallet__FailedToWithdrawFunds();
        }
    }

    function getNonce() public view returns (uint256) {
        return _nonce;
    }

    function getEntryPoint() public view returns (IEntryPoint) {
        return i_entryPoint;
    }
}
