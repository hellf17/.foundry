// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription} from "../script/Interactions.s.sol";


contract DeployRaffle is Script{
    function run() external returns (Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        (uint256 ticketValue,
        uint256 maxTimeInterval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint256 requestConfirmations,
        uint256 numWords,
        uint32 callbackGasLimit) = helperConfig.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinator);
        } 

        vm.startBroadcast();
        Raffle raffle = new Raffle (
            ticketValue,
            maxTimeInterval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            requestConfirmations,
            numWords,
            callbackGasLimit
        );
        return (raffle, helperConfig);
        vm.stopBroadcast();
    }
}
