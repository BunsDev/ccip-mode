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
        uint64 DESTINATION_CHAIN_SELECTOR = 16015286601757825753;
        // console.log("DESTINATION_CHAIN_SELECTOR: ", DESTINATION_CHAIN_SELECTOR);

        // note: this is a deployed contract.
        address DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS = vm.envAddress("DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS");
        // console.log("DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS: ", DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS);

        // note: this is a deployed contract.
        address payable SOURCE_PROGRAMMABLE_TOKENS_ADDRESS = payable(vm.envAddress("SOURCE_PROGRAMMABLE_TOKENS_ADDRESS"));
        // console.log("SOURCE_PROGRAMMABLE_TOKENS_ADDRESS: ", SOURCE_PROGRAMMABLE_TOKENS_ADDRESS);

        vm.startBroadcast(deployerPrivateKey);
        console.log('Broadcast transaction...');

        bytes32 messageId = ProgrammableTokenTransfers(SOURCE_PROGRAMMABLE_TOKENS_ADDRESS).sendMessage(
            DESTINATION_CHAIN_SELECTOR,
            DESTINATION_PROGRAMMABLE_TOKENS_ADDRESS,
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
