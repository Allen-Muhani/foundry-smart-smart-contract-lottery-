// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


contract RaffleTest is Test {
    Raffle raffle;
    HelperConfig helperConfig;
    uint256 entranceFee;
    uint256 interval;

    address public PLAYER_1 = makeAddr("player");
    address public PLAYER_2 = makeAddr("player1");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    /**
     * Indicates that a player has entered the raffle.
     * @param player  The address of the player who entered the raffle.
     * @param entranceFee   The entrance fee paid by the player.
     */
    event EnteredRaffle(address indexed player, uint256 entranceFee);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();

        (uint256 _entranceFee, uint256 _interval, , , , , ) = helperConfig
            .activeNetworkConfig();

        entranceFee = _entranceFee;
        interval = _interval;

        vm.deal(PLAYER_1, STARTING_USER_BALANCE);
        vm.deal(PLAYER_2, STARTING_USER_BALANCE);
    }

    function testRaffleInitializesInOpenstate() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //////////////////////////
    //  enterRaffle        //
    /////////////////////////

    /**
     * @dev test sending less than enough entry fee.
     * @notice forge test --match-test testRaffleRevertsWhenYodontPayEnough
     */
    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER_1);

        // Act. /assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__NotEnoughETHSSent.selector,
                0,
                entranceFee
            )
        );
        raffle.enterRaffle();
    }

    /**
     *
     * @notice forge test --match-test testRaffleRecordsPlayerWhenTheyEnter
     */
    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER_1);

        raffle.enterRaffle{value: entranceFee + 1}();

        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER_1);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER_1);

        vm.expectEmit(true, false, false, true, address(raffle));
        emit EnteredRaffle(PLAYER_1, entranceFee);

        raffle.enterRaffle{value: entranceFee}();
    }

    //forge test --match-test testCantEnterWhenRaffleIsCalculating -vvvvv
    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER_2);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(PLAYER_1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        raffle.performUpkeep("");

        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER_1);

        raffle.enterRaffle{value: entranceFee}();
    }

    ////////////////////////////////
    ///  CheckUpkeep Tests       //
    ////////////////////////////////

    //forge test --match-test testcheckUpkeepReturnsFalseIfItHasNoBalance
    function testcheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    //forge test --match-test testCheckUpkeepReturnsFalseIfRaffleNotOpen
    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        //  Arrange
        vm.prank(PLAYER_2);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(PLAYER_1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    //////////////////////////////////
    // performUpkeep Tests       ////
    /////////////////////////////////
    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER_2);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(PLAYER_1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testPerformUpokeepShouldRevertIfUpkeepIsFalse() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle_UpkeepNotNeeded.selector,
                address(raffle).balance, // raffle contrat balance.
                0, //nu8mber of users entered.
                uint256(raffle.getRaffleState())
            )
        );
        raffle.performUpkeep("");
    }

    modifier raffleEnteredAndTimePassed() {
        // Arrange
        vm.prank(PLAYER_2);
        raffle.enterRaffle{value: entranceFee}();

        vm.prank(PLAYER_1);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerfromUpkeepUdatesRaffleeStaeAbdEmitsRquestId()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs();

        raffle.performUpkeep(""); //emit the request id.abi
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1]; // the request id is the second topic of the second log entry.
        Raffle.RaffleState raffleState = raffle.getRaffleState();

        assert(uint256(requestId) > 0);
        assert(raffleState == Raffle.RaffleState.CALCULATING);
    }
}
