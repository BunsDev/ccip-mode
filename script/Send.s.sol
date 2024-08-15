// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./utils/Helper.sol";
import {BasicTokenSender} from "../src/BasicTokenSender.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract SendBatch is Script, Helper {
    function run(
        SupportedNetworks destination,
        address payable basicTokenSenderAddres,
        address receiver,
        Client.EVMTokenAmount[] memory tokensToSendDetails,
        BasicTokenSender.PayFeesIn payFeesIn
    ) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);

        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        BasicTokenSender(basicTokenSenderAddres).send(
            destinationChainId,
            receiver,
            tokensToSendDetails,
            payFeesIn
        );

        vm.stopBroadcast();
    }
}