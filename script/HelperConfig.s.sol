// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script{
    struct NetworkConfig {
        uint256 ticketValue;
        uint256 maxTimeInterval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint256 requestConfirmations;
        uint256 numWords;
        uint32 callbackGasLimit;
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if (block.chainid = 11155111){
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }

    }

    function getSepoliaConfig () public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            ticketValue: 0.01 ether,
            maxTimeInterval: 1000,
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, //will be added with script
            requestConfirmations: 0,
            numWords: 1,
            callbackGasLimit: 50000
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory){
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        vm.stopBroadcast();
        
        return NetworkConfig ({
            ticketValue: 0.01 ether,
            maxTimeInterval: 1000,
            vrfCoordinator: address(vrfCoordinator),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0, //will be added with script
            numWords: 1,
            callbackGasLimit: 50000
        });
    }