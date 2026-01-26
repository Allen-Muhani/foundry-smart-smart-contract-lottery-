// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle raffle) {
        HelperConfig helperConfig = new HelperConfig();

        (
            uint256 entranceFee,
            uint256 interval,
            address vrfCoordinator,
            bytes memory gasLane,
            uint256 subscriptionId,
            uint256 callbackGasLimit
        ) = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        raffle = new Raffle(
            entranceFee,
            interval,
            subscriptionId,
            vrfCoordinator,
            gasLane
        );
        vm.stopBroadcast();
    }
}
