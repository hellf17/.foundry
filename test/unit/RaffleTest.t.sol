// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract RaffleTest is Test {
    // Events
    event EnteredRaffle(address indexed participant, uint256 indexed amount);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 ticketValue;
    uint256 maxTimeInterval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint256 requestConfirmations;
    uint256 numWords;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddress("player");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setup() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (uint256 ticketValue,
        uint256 maxTimeInterval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint256 requestConfirmations,
        uint256 numWords,
        uint32 callbackGasLimit) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_BALANCE);
    }

    function testRaffleInitializesInOpenState () public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);

    }

    // enterRaffle
    function revertWhenNotEnoughtMoney() public view {
        //Arrange
        vm.prank(PLAYER);
        //Act / Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughtFundsSent.selector);
        raffle.enterRaffle();    
    }

    function raffleRecordPlayerAreRecorded () public {
        vm.prank(PLAYER);
        vm.dea
        raffle.enterRaffle{value: 1 ether}();
        address playerRecorded = raffle.getParticipants(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitEventWhenEntered () public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER, ticketValue);
        raffle.enterRaffle{value: ticketValue}();        
    }

    function testCantEnterInRaffleIfCalculating () public{
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketValue}();
        vm.warp(block.timestamp + interval + 10);
        vm.roll(block.number + 10);
        raffle.performUpkeep;
        
        vm.expectRevert(Raffle.Raffle__RaffleClosed.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: ticketValue}();
    }

    function testRaffleClosesAfterMaxParticipants () public view {
        for (uint256 i = 0; i < 1000; i++) {
            raffle.enterRaffle{value: 1 ether}();
        }
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }
}