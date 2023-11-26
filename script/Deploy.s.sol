// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Deploy} from "../src/Deploy.sol";

contract Deploy is Script{
    function run()  external returns (Deploy) {
        vm.startBroadcast();
        Deploy newDeploy = new Deploy();
        vm.stopBroadcast();
        return newDeploy;
    }
        
}
