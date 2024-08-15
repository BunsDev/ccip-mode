// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./utils/Helper.sol";
import {ProgrammableTokenTransfers} from "../src/ProgrammableTokenTransfers.sol";

contract SendTokensAndData is Script, Helper {
    function run(
        string memory message,
        address token,
        uint amount
    ) external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint64 DESTINATION_CHAIN_ID = 16015286601757825753;

        // note: this is a deployed contract.
        address MESSAGE_RECEIVER_ADDRESS = vm.envAddress("MESSAGE_RECEIVER_ADDRESS");
        // note: this is a deployed contract.
        address payable MESSAGE_SENDER_ADDRESS = payable(vm.envAddress("MESSAGE_SENDER_ADDRESS"));

        vm.startBroadcast(deployerPrivateKey);

        bytes32 messageId = ProgrammableTokenTransfers(MESSAGE_SENDER_ADDRESS).sendMessage(
            DESTINATION_CHAIN_ID,
            MESSAGE_RECEIVER_ADDRESS,
            message,
            token,
            amount
        );

        console.log(
            "You can now monitor the status of your Chainlink CCIP Message via https://ccip.chain.link using CCIP Message ID: "
        );
        console.logBytes32(messageId);

        vm.stopBroadcast();
    }
}
