// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./utils/Helper.sol";

import {BasicMessageReceiver} from "../src/BasicMessageReceiver.sol";
import {BasicMessageSender} from "../src/BasicMessageSender.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

// MessageReceiver Script
contract CCIPTokenTransfer is Script, Helper {
        address MESSAGE_RECEIVER_ADDRESS = vm.envAddress("MESSAGE_RECEIVER_ADDRESS");
        uint senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address SOURCE_ROUTER_ADDRESS = vm.envAddress("SOURCE_ROUTER_ADDRESS");
        address SOURCE_LINK_ADDRESS = vm.envAddress("SOURCE_LINK_ADDRESS");
        uint64 DESTINATION_CHAIN_ID = 16015286601757825753;
        address TOKEN_TO_SEND_ADDRESS = vm.envAddress("SOURCE_BNM_ADDRESS");

    function run(
        uint amount,
        PayFeesIn payFeesIn
    ) external returns (bytes32 messageId) {

        // note: this is a deployed contract.

        vm.startBroadcast(senderPrivateKey);

        IERC20(TOKEN_TO_SEND_ADDRESS).approve(SOURCE_ROUTER_ADDRESS, amount);
        console.log('TOKEN_TO_SEND_ADDRESS: ', TOKEN_TO_SEND_ADDRESS);

        Client.EVMTokenAmount[] memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0] = Client.EVMTokenAmount({
            token: address(TOKEN_TO_SEND_ADDRESS),
            amount: amount
        });

        // creates: message to send.
         Client.EVM2AnyMessage memory message = createMessage(address(SOURCE_LINK_ADDRESS), 
         tokensToSendDetails);

        uint fees = IRouterClient(SOURCE_ROUTER_ADDRESS).getFee(
            DESTINATION_CHAIN_ID,
            message
        );

        if (payFeesIn == PayFeesIn.LINK) {
            IERC20(SOURCE_LINK_ADDRESS).approve(SOURCE_ROUTER_ADDRESS, fees);
            messageId = IRouterClient(SOURCE_ROUTER_ADDRESS).ccipSend(
                DESTINATION_CHAIN_ID,
                message
            );
        } else {
            messageId = IRouterClient(SOURCE_ROUTER_ADDRESS).ccipSend{value: fees}(
                DESTINATION_CHAIN_ID,
                message
            );
        }

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }

    // HELPER FUNCTIONS //

    // creates: message to send cross-chain
    function createMessage(address feeToken, Client.EVMTokenAmount[] memory tokensToSendDetails) public view returns (Client.EVM2AnyMessage memory message) {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(MESSAGE_RECEIVER_ADDRESS),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: feeToken
        });
    }
}

// MessageReceiver Script
contract GetLatestMessageDetails is Script, Helper {
    function run() external view {
        // note: this is a deployed contract.
        address MESSAGE_RECEIVER_ADDRESS = vm.envAddress("MESSAGE_RECEIVER_ADDRESS");

        (
            bytes32 latestMessageId,
            uint64 latestSourceChainSelector,
            address latestSender,
            string memory latestMessage
        ) = BasicMessageReceiver(MESSAGE_RECEIVER_ADDRESS).getLatestMessageDetails();

        console.log("Latest Message ID: ");
        console.logBytes32(latestMessageId);
        console.log("Latest Source Chain Selector: ");
        console.log(latestSourceChainSelector);
        console.log("Latest Sender: ");
        console.log(latestSender);
        console.log("Latest Message: ");
        console.log(latestMessage);
    }
}

// MessageSender Script
contract SendMessage is Script, Helper {
    function run(
        string memory message,
        BasicMessageSender.PayFeesIn payFeesIn
    ) external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint64 DESTINATION_CHAIN_ID = 16015286601757825753;

        // note: this is a deployed contract.
        address MESSAGE_RECEIVER_ADDRESS = vm.envAddress("MESSAGE_RECEIVER_ADDRESS");
        // note: this is a deployed contract.
        address payable MESSAGE_SENDER_ADDRESS = payable(vm.envAddress("MESSAGE_SENDER_ADDRESS"));

        vm.startBroadcast(deployerPrivateKey);

        bytes32 messageId = BasicMessageSender(MESSAGE_SENDER_ADDRESS).send(
            DESTINATION_CHAIN_ID,
            MESSAGE_RECEIVER_ADDRESS,
            message,
            payFeesIn
        );

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
}