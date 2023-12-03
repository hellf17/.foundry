// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64){
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,,,,,) = helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64) {
        vm.startBroadcast();
        console.log("Creating subscription on ChainId:", block.chainid);
        uint64 subscriptionId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast;
        console.log("SubscriptionId:", subscriptionId);
        console.log("Update subscriptionId in HelperConfig.s.sol");
        return subscriptionId;       
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}