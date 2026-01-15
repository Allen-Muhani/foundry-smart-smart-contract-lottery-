// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title A sample Raffle contract.
 * @author Allen Muhani
 * @notice This contrac is for creating sample raffle.
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    uint256 private s_entranceFee;

    constructor(uint256 entranceFee) {
        s_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    function getEntranceFee() external view returns (uint256) {
        return s_entranceFee;
    }
}
