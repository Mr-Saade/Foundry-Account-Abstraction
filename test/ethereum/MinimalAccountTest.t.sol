// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SmartWallet} from "src/ethereum/SmartWallet.sol";
import {SmartWalletDeploy} from "script/SmartWalletDeploy.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SmartWalletTest is Test, ZkSyncChainChecker {
    using MessageHashUtils for bytes32;

    HelperConfig helperConfig;
    SmartWallet smartWallet;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address randomuser = makeAddr("randomUser");

    uint256 constant AMOUNT = 1e18;
    uint256 constant MISSING_ACCOUNT_FUNDS = 1e18;
    uint256 constant DEAL_AMOUNT = 2 ether;

    function setUp() public skipZkSync {
        SmartWalletDeploy smartWalletDeploy = new SmartWalletDeploy();
        (helperConfig, smartWallet) = smartWalletDeploy.deploySmartWallet();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
        vm.deal(address(smartWallet), 2 ether);
    }

    // USDC Mint
    // msg.sender -> SmartWallet
    // approve some amount
    // USDC contract
    // come from the entrypoint
    function testOwnerCanExecuteCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(smartWallet)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        // Act
        vm.prank(smartWallet.owner());
        smartWallet.executeTransaction(dest, value, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(smartWallet)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(smartWallet)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        // Act
        vm.prank(randomuser);
        vm.expectRevert(SmartWallet.SmartWallet__InvalidCaller.selector);
        smartWallet.executeTransaction(dest, value, functionData);
    }

    function testRecoverSignedOp() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(smartWallet)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(smartWallet.executeTransaction.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCallData, helperConfig.getConfig(), address(smartWallet)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        (address actualSigner,,) = ECDSA.tryRecover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // Assert
        assertEq(actualSigner, smartWallet.owner());
    }

    // 1. Sign user ops
    // 2. Call validate userops
    // 3. Assert the return is correct
    function testValidationOfUserOps() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(smartWallet)), 0);
        address dest = address(usdc);
        uint256 value = 0;

        console.log("Balance of smartWallet", usdc.balanceOf(address(smartWallet)));
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(smartWallet.executeTransaction.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCallData, helperConfig.getConfig(), address(smartWallet)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = smartWallet.validateUserOp(packedUserOp, userOperationHash, MISSING_ACCOUNT_FUNDS);

        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public skipZkSync {
        // Arrange
        assertEq(usdc.balanceOf(address(smartWallet)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(smartWallet.executeTransaction.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(
            executeCallData, helperConfig.getConfig(), address(smartWallet)
        );

        vm.deal(address(smartWallet), DEAL_AMOUNT);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        // Act
        vm.prank(randomuser); //simulating the bundler
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(randomuser));

        // Assert
        assertEq(usdc.balanceOf(address(smartWallet)), AMOUNT);
    }
}
