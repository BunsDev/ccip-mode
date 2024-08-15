// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./utils/Helper.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";

contract CCIPTokenTransfer is Script, Helper {
    function run(
        uint256 amount,
        PayFeesIn payFeesIn
    ) external returns (bytes32 messageId) {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address SOURCE_ROUTER_ADDRESS = vm.envAddress("SOURCE_ROUTER_ADDRESS");
        address SOURCE_LINK_ADDRESS = vm.envAddress("SOURCE_LINK_ADDRESS");
        uint DESTINATION_CHAIN_ID = vm.envUint("DESTINATION_CHAIN_ID");
        uint TOKEN_TO_SEND_ADDRESS = vm.envUint("DESTINATION_BNM_ADDRESS");

        // note: this is a deployed contract.
        address MESSAGE_RECEIVER_ADDRESS = vm.envAddress("MESSAGE_RECEIVER_ADDRESS");

        vm.startBroadcast(senderPrivateKey);

        IERC20(TOKEN_TO_SEND_ADDRESS).approve(SOURCE_ROUTER_ADDRESS, amount);

        Client.EVMTokenAmount[]
            memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails = Client
            .EVMTokenAmount({token: TOKEN_TO_SEND_ADDRESS, amount: amount});

        tokensToSendDetails[0] = tokenToSendDetails;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: "",
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: payFeesIn == PayFeesIn.LINK ? SOURCE_LINK_ADDRESS : address(0)
        });

        uint256 fees = IRouterClient(SOURCE_ROUTER_ADDRESS).getFee(
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
}
