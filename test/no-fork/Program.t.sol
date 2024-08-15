// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/Script.sol";
import {
    CCIPLocalSimulator, IRouterClient, BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {ProgrammableTokenTransfers} from "../../src/ProgrammableTokenTransfers.sol";

contract ProgramTest is Test {
    CCIPLocalSimulator public ccipLocalSimulator;
    ProgrammableTokenTransfers public sender;
    ProgrammableTokenTransfers public receiver;

    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;

    function setUp() public {
        ccipLocalSimulator = new CCIPLocalSimulator();
        (uint64 chainSelector, IRouterClient sourceRouter,,,, BurnMintERC677Helper ccipBnM,) =
            ccipLocalSimulator.configuration();

        sender = new ProgrammableTokenTransfers(address(sourceRouter));
        receiver = new ProgrammableTokenTransfers(address(sourceRouter));

        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
    }

    function test_programmableTokens() external {
        deal(address(sender), 1 ether);
        ccipBnMToken.drip(address(sender));

        uint balanceOfSenderBefore = ccipBnMToken.balanceOf(address(sender));
        uint balanceOfReceiverBefore = ccipBnMToken.balanceOf(address(receiver));

        string memory messageToSend = "Hello, World!";
        uint amountToSend = 1 ether;

        bytes32 messageId = sender.sendMessage(
            destinationChainSelector, address(receiver), messageToSend, address(ccipBnMToken), amountToSend
        );

        (
            bytes32 latestMessageId,
            uint64 latestMessageSourceChainSelector,
            address latestMessageSender,
            string memory latestMessage,
            address latestMessageToken,
            uint latestMessageAmount
        ) = receiver.getLastReceivedMessageDetails();

        uint balanceOfSenderAfter = ccipBnMToken.balanceOf(address(sender));
        uint balanceOfReceiverAfter = ccipBnMToken.balanceOf(address(receiver));
        console.log("Sender: ", balanceOfSenderBefore / 1e18, "->", balanceOfSenderAfter / 1e18);
        console.log("Receiver: ", balanceOfReceiverAfter / 1e18, "->", balanceOfReceiverAfter / 1e18);

        assertEq(latestMessageId, messageId);
        assertEq(latestMessageSourceChainSelector, destinationChainSelector);
        assertEq(latestMessageSender, address(sender));
        assertEq(latestMessage, messageToSend);
        assertEq(latestMessageToken, address(ccipBnMToken));
        assertEq(latestMessageAmount, amountToSend);

        assertEq(balanceOfSenderAfter, balanceOfSenderBefore - amountToSend);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amountToSend);
    }
}
