// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SmartWallet} from "src/ethereum/SmartWallet.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    // Make sure you trust this user - don't run this on Mainnet!
    address constant RANDOM_APPROVER =
        0x9EA9b0cc1919def1A3CfAEF4F7A66eE3c36F86fC;
    address USEROP_BUNDLER = makeAddr("bundler");

    function run() public {
        HelperConfig helperConfig = new HelperConfig();
        address dest = helperConfig.getConfig().usdc;
        uint256 value = 0;
        address smartWalletAddress = DevOpsTools.get_most_recent_deployment(
            "SmartWallet",
            block.chainid
        );

        bytes memory functionData = abi.encodeWithSelector(
            IERC20.approve.selector,
            RANDOM_APPROVER,
            1e18
        );
        bytes memory executeCalldata = abi.encodeWithSelector(
            SmartWallet.executeTransaction.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory userOp = generateSignedUserOperation(
            executeCalldata,
            helperConfig.getConfig(),
            smartWalletAddress
        );
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = userOp;

        vm.startBroadcast(USEROP_BUNDLER);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(
            ops,
            payable(USEROP_BUNDLER)
        );
        vm.stopBroadcast();
    }

    function generateSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address smartWallet
    ) public view returns (PackedUserOperation memory) {
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(smartWallet) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(
            callData,
            smartWallet,
            nonce
        );

        // 2. Get the userOp Hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(
            userOp
        );
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        // 3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }
        userOp.signature = abi.encodePacked(r, s, v); // Note the order of the signature
        return userOp;
    }

    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    ) internal pure returns (PackedUserOperation memory) {
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return
            PackedUserOperation({
                sender: sender,
                nonce: nonce,
                initCode: hex"",
                callData: callData,
                accountGasLimits: bytes32(
                    (uint256(verificationGasLimit) << 128) | callGasLimit
                ), //shifts verificationGasLimit to the left by 128 bits and adds callGasLimit to the right
                preVerificationGas: verificationGasLimit,
                gasFees: bytes32(
                    (uint256(maxPriorityFeePerGas) << 128) | maxFeePerGas
                ), //shifts maxPriorityFeePerGas to the left by 128 bits and adds maxFeePerGas to the right
                paymasterAndData: hex"",
                signature: hex""
            });
    }
}
