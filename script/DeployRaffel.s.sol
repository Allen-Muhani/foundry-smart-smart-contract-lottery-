// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle) {
        vm.startBroadcast();
        // raffle = new Raffle(10000, )
        vm.stopBroadcast();
    }
}
