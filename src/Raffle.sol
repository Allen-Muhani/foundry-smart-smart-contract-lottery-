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

// https://youtu.be/sas02qSFZ74?t=15525

pragma solidity ^0.8.0;

import {VRFConsumerBaseV2Plus} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "chainlink-brownie-contracts/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title A sample Raffle contract.
 * @author Allen Muhani
 * @notice This contrac is for creating sample raffle.
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /** Errors */
    error Raffle__NotEnoughETHSSent(uint256 amountSent, uint256 requiredAmount);

    error Raffle__TransferFailed();

    error Raffle_RaffleNotOppen();

    /**Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    RaffleState private s_raffleState = RaffleState.OPEN;

    /** State variables */

    /**
     * @dev The entrance fee for the raffle in wei.
     */
    uint256 private i_entranceFee;

    /**
     * @dev List of players who have entered the raffle.
     */
    address payable[] private s_players;

    uint256 private immutable i_interval;

    uint256 private s_lastTimeStamp;

    uint256 private immutable i_subscriptionId;

    bytes32 private immutable i_Key_Hash_Gas_Lane;

    uint32 private constant NUM_WORDS = 1;

    uint32 private constant CALL_BACK_GASS_LIMIT = 200000;

    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    address payable s_recentWinner;

    /**Events */

    /**
     * Indicates that a player has entered the raffle.
     * @param player  The address of the player who entered the raffle.
     * @param entranceFee   The entrance fee paid by the player.
     */
    event EnteredRaffle(address indexed player, uint256 entranceFee);

    event WinnerPickeed(address winner);

    /*
     * @dev Constructor to initialize the raffle contract.
     * @param entranceFee The entrance fee for the raffle in wei.
     * @param interval The time interval for the raffle.
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        uint256 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;

        i_subscriptionId = subscriptionId;
        i_Key_Hash_Gas_Lane = keyHash;
    }

    /**External functions */

    /**
     * @dev This function is for entering the raffle by sending in the deposit.
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee)
            revert Raffle__NotEnoughETHSSent(msg.value, i_entranceFee);

        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender, msg.value);
    }

    /**
     * @dev this funtion is used by the chainlink nodes to check if the
     *  smartcontract needs to perfrom upkeep.
     *
     * The following should be true for this to return true.
     * 1. The time interval passed btwn raffl runs.
     * 2. The raffle is in the OPEN state.
     * 3. The contract has eth and players.
     * 4. (Implicit) the subscription is funded with Link.
     * @return upkeepNeeded true if upkeep is needed.
     * @return
     */
    function checkUpkeep(
        bytes memory
    ) public view override returns (bool upkeepNeeded, bytes memory) {
        bool playersPresent = s_players.length > 1;
        bool raffleOpen = s_raffleState == RaffleState.OPEN;
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp < i_interval);
        bool hasBalance = address(this).balance > 0;

        upkeepNeeded =
            playersPresent &&
            raffleOpen &&
            timeHasPassed &&
            hasBalance;

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert Raffle_RaffleNotOppen();
        }

        pickWinner();
    }

    /**
     * Logic to pick a winner using chainlink VRF.
     */
    function pickWinner() public {
        if (block.timestamp - s_lastTimeStamp < i_interval) {
            revert Raffle_RaffleNotOppen();
        }

        s_raffleState = RaffleState.CALCULATING;

        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_Key_Hash_Gas_Lane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALL_BACK_GASS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        // tells it to pay in LINK tokens instead of eth
                        nativePayment: false
                    })
                )
            })
        );
    }

    /**
     * @notice Callback function used by VRF Coordinator.
     * param _requestId The ID initially returned by requestRandomWords.
     * @param randomWords the VRF output expanded to the requested number of words.
     */
    function fulfillRandomWords(
        uint256,
        uint256[] calldata randomWords
    ) internal override {
        uint256 indexOfWinner = (randomWords[0] % s_players.length) + 1;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit WinnerPickeed(winner);
    }

    /**Getters functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
