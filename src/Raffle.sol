// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

/**
 * @title Modular Raffle contract
 * @author hellf
 * @notice This contract is a modular raffle contract
 * @dev Uses Chainlink VRF for random number generation and Automation for the raffle
 * */
contract Raffle is VRF2ConsumerBase{
    // Functions: pickWinner, enterRaffle
    // enterRaffle: allows a user to enter the raffle by paying a fee
    // pickWinner: picks a winner from the list of participants using Chainlink VRF
    // and uses Automation to set times between each raffle and send the prize to the winner


    // Errors
    error Raffle__NotEnoughtFundsSent();
    error Raffle__MaxParticipantsReached();
    error Raffle__ProblemSendingPrize();
    error Raffle__RaffleClosed();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 timeSinceLastRaffle, RaffleState state, uint256 participants);

    //Type declarations
    enum RaffleState {
        OPEN, // 0
        CALCULATING //1
    }

    // State variables
    uint256 private immutable i_ticketValue;
    uint256 private immutable i_maxParticipants = 1000;
    uint256 private immutable i_maxTimeInterval; //duration of loterry in seconds
    uint256 private s_lastTimeStamp;
    address payable[] private s_participants;
    address private s_mostRecentWinner;
    RaffleState private s_raffleState;

    // Chainlink VRF variables
    uint16 private immutable i_requestConfirmations;
    uint32 private immutable i_callbackGasLimit;
    uint32 private immutable i_numWords;
    uint64 private immutable i_subscriptionId;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;

    // Events
    event RaffleParticipantEntered(address indexed participant, uint256 indexed amount);
    event RaffleWinnerPicked(address indexed winner, uint256 indexed amount);

    // Constructor
    // We need to pass VRFConsumerBaseV2 constructor arguments to the constructor of this contract
    constructor(
        uint256 ticketValue, uint256 maxTimeInterval, address vrfCoordinator, bytes32 gasLane, uint256 subscriptionId, uint256 requestConfirmations, uint256 numWords, uint32 callbackGasLimit) 
        
        VRFConsumerBaseV2(vrfCoordinator) 
        {
        i_ticketValue = ticketValue;
        i_maxTimeInterval = maxTimeInterval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_requestConfirmations = requestConfirmations;
        i_numWords = numWords;
        i_callbackGasLimit = callbackGasLimit;
        }

    // Functions
    function enterRaffle() external payable {
        // require(msg.value >= i_ticketValue, "Raffle: ticket value is not correct");
        if (msg.value < i_ticketValue) {
            revert Raffle__NotEnoughtFundsSent();
        }

        if (s_participants.length >= i_maxParticipants) {
            revert Raffle__MaxParticipantsReached();
        }

        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__RaffleClosed();
        }

        s_participants.push(payable(msg.sender)); // add the participant to the list of participants
        emit RaffleParticipantEntered(msg.sender, msg.value); // emit the event that a participant entered the raffle

    }
    /**
     * @dev This is the function that Chainlink Automation nodes calls when to see if its time to perform an upkeep. Need to be true if the conditions to pick a winner are met
     * 1. The contract has ETH (players that have paid the ticket value)
     * 2. Enough time has passed since the last raffle
     * 3. Raffle is OPEN state
     * 4. Subscription has LINK
     * @return upKeepNeeded 
     */
    function checkUpkeep (bytes memory /*checkData*/
    ) public view returns (bool upKeepNeeded, bytes memory /*performData*/) { //checkData and performData are required by chainlink functions, but we ignore it here
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_maxTimeInterval;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool contractHasEth = address(this).balance > 0;
        bool hasPlayers = s_participants.length > 0;
        upKeepNeeded = (timeHasPassed && raffleIsOpen && contractHasEth && hasPlayers);

        return (upKeepNeeded, "0x0");        
    }

    function performUpkeep(bytes calldata /*performData*/) external {
        // Validate the call
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                block.timestamp - s_lastTimeStamp,
                s_raffleState,
                s_participants.length
            );
        }

        // Pick a winner using Chainlink VRF
        uint256 requestId = i_vrfCoordinator.requestRandomWords( // calls the requestRandomWords function from the VRF Coordinator
           i_gasLane, // changes for each network
           s_subscriptionId, // subscription id on chainlink
           i_requestConfirmations, // number of confirmations
           i_callbackGasLimit, // gas limit
           i_numWords // number of words
        );
        
        // Change the raffle state to CALCULATING
        s_raffleState = RaffleState.CALCULATING;
    }

    function fulfillRandomWords( //func
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // Pick a winner from the list of participants using the random number / participants length
        uint256 winnerIndex = requestId % s_participants.length;
        address payable winner = s_participants[winnerIndex];
        emit RaffleWinnerPicked(winner, address(this).balance); // emit the event that a winner was picked

        // Updates the most recent winner
        s_mostRecentWinner = winner;

        // Change the raffle state to OPEN
        s_participants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        //Send the prize to the winner
        (bool success, ) = s_mostRecentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__ProblemSendingPrize();
        }
    }

    // Getters
    function getTicketValue() external view returns (uint256) {
        return i_ticketValue;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getParticipants(uint256 indexOfPlayer) external view returns (address) {
        return s_participants[indexOfPlayer];
    }

}