// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./utils/Helper.sol";
import {ProgrammableTokenTransfers} from "../src/ProgrammableTokenTransfers.sol";

contract SendTokensAndData is Script, Helper {
    function run(
        address payable sender,
        SupportedNetworks destination,
        address receiver,
        string memory message,
        address token,
        uint256 amount
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        (, , , uint64 destinationChainId) = getConfigFromNetwork(destination);

        bytes32 messageId = ProgrammableTokenTransfers(sender).sendMessage(
            destinationChainId,
            receiver,
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