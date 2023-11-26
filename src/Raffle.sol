// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @title Modular Raffle contract
 * @author hellf
 * @notice This contract is a modular raffle contract
 * @dev Uses Chainlink VRF for random number generation and Automation for the raffle
 * */
contract Raffle {
    // Functions: pickWinner, enterRaffle
    // enterRaffle: allows a user to enter the raffle by paying a fee
    // pickWinner: picks a winner from the list of participants using Chainlink VRF 
    // and uses Automation to set times between each raffle and send the prize to the winner


    // Errors
    error Raffle__NotEnoughtFundsSent();
    error Raffle__MaxParticipantsReached();
    error Raffle__NotEnoughtPlayers();
    error Raffle__NotEnoughTimePassed();

    // State variables
    uint256 private imuttable i_ticketValue;
    address payable[] private s_participants;
    uint256 private immutable i_maxParticipants = 1000;
    uint256 private immutable i_maxTimeInterval; //duration of loterry in seconds
    uint256 private s_lastTimeStamp;


    // Events
    event RaffleParticipantEntered(address indexed participant, uint256 indexed amount);

    // Constructor
    constructor(uint256 ticketValue) {
        i_ticketValue = ticketValue;
        i_maxTimeInterval = 3600; // 1 hour
        s_lastTimeStamp = block.timestamp;
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

        s_participants.push(payable(msg.sender)); // add the participant to the list of participants
        emit RaffleParticipantEntered(msg.sender, msg.value); // emit the event that a participant entered the raffle

    }

    function pickWinner() external {
        // Check if the raffle has enough participants
        if (s_participants.length < 2) {
            revert Raffle__NotEnoughtPlayers();
        }
        // Check if enough time has passed since the last raffle
        if (block.timestamp - s_lastTimeStamp < i_maxTimeInterval) {
            revert Raffle__NotEnoughTimePassed();
        }
        // Pick a winner using Chainlink VRF
        
        
        // Send the prize to the winner using Chainlink Automation

        // Reset the raffle
        s_participants = [];
        s_lastTimeStamp = block.timestamp;

        
    }

    // Getters
    function getTicketValue() public view returns (uint256) {
        return i_ticketValue;
    }

    }
}