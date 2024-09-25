// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SmartWallet} from "src/ethereum/SmartWallet.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract SmartWalletDeploy is Script {
    function run() public {
        deploySmartWallet();
    }

    function deploySmartWallet() public returns (HelperConfig, SmartWallet) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        SmartWallet smartWallet = new SmartWallet(config.entryPoint);
        smartWallet.transferOwnership(config.account);
        vm.stopBroadcast();
        return (helperConfig, smartWallet);
    }
}
