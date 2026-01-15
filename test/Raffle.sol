// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

// https://youtu.be/sas02qSFZ74?t=13319

pragma solidity ^0.8.0;

/**
 * @title A sample Raffle contract.
 * @author Allen Muhani
 * @notice This contrac is for creating sample raffle.
 * @dev Implements Chainlink VRFv2
 */
contract Raffle {
    /** Errors */
    error Raffle__NotEnoughETHSSent(uint256 amountSent, uint256 requiredAmount);

    /** State variables */

    /**
     * @dev The entrance fee for the raffle in wei.
     */
    uint256 private i_entranceFee;

    /**
     * @dev List of players who have entered the raffle.
     */
    address[] private s_players;

    uint256 private i_interval;

    uint256 private s_lastTimeStamp;

    /**Events */

    /**
     * Indicates that a player has entered the raffle.
     * @param player  The address of the player who entered the raffle.
     * @param entranceFee   The entrance fee paid by the player.
     */
    event EntredRaffle(address indexed player, uint256 entranceFee);

    /*
     * @dev Constructor to initialize the raffle contract.
     * @param entranceFee The entrance fee for the raffle in wei.
     * @param interval The time interval for the raffle.
     */
    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    /**External functions */

    /**
     * @dev This function is for entering the raffle by sending in the deposit.
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee)
            revert Raffle__NotEnoughETHSSent(msg.value, i_entranceFee);

        s_players.push(msg.sender);

        emit EntredRaffle(msg.sender, msg.value);
    }

    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert();
        }
        // Get Random winner
        // Payout the winner
    }

    /**Getters functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
