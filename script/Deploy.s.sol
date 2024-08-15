// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "forge-std/Script.sol";
import {BasicMessageReceiver} from "../src/BasicMessageReceiver.sol";
import {BasicMessageSender} from "../src/BasicMessageSender.sol";
import {Helper} from "./utils/Helper.sol";
import {ProgrammableTokenTransfers} from "../src/ProgrammableTokenTransfers.sol";


contract DeployBasicTokenSender is Script, Helper {
    function run(SupportedNetworks source) external {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address SOURCE_ROUTER_ADDRESS = vm.envAddress("SOURCE_ROUTER_ADDRESS");
        address SOURCE_LINK_ADDRESS = vm.envAddress("SOURCE_LINK_ADDRESS");
        uint SOURCE_CHAIN_ID = vm.envUint("SOURCE_CHAIN_ID");

        vm.startBroadcast(senderPrivateKey);

        BasicTokenSender basicTokenSender = new BasicTokenSender(
            SOURCE_ROUTER_ADDRESS,
            SOURCE_LINK_ADDRESS
        );

        console.log(
            "Token Sender deployed on chainId: ",
            SOURCE_CHAIN_ID,
            "with address: ",
            address(basicTokenSender)
        );

        vm.stopBroadcast();
    }
}

contract DeployBasicMessageReceiver is Script, Helper {
    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address DESTINATION_ROUTER_ADDRESS = vm.envAddress("DESTINATION_ROUTER_ADDRESS");
        uint DESTINATION_CHAIN_ID = vm.envUint("DESTINATION_CHAIN_ID");

        vm.startBroadcast(deployerPrivateKey);

        // deploys: BasicMessageReceiver
        BasicMessageReceiver basicMessageReceiver = new BasicMessageReceiver(
            DESTINATION_ROUTER_ADDRESS
        );

        console.log(
            "Message Receiver deployed on chainId: ",
            DESTINATION_CHAIN_ID,
            "with address: ",
            address(basicMessageReceiver)
        );

        vm.stopBroadcast();
    }
}

contract DeployBasicMessageSender is Script, Helper {
    uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address SOURCE_ROUTER_ADDRESS = vm.envAddress("SOURCE_ROUTER_ADDRESS");
    address SOURCE_LINK_ADDRESS = vm.envAddress("SOURCE_LINK_ADDRESS");
    uint SOURCE_CHAIN_ID = vm.envUint("SOURCE_CHAIN_ID");

    function run() external {

        vm.startBroadcast(deployerPrivateKey);

        BasicMessageSender basicMessageSender = new BasicMessageSender(
            SOURCE_ROUTER_ADDRESS,
            SOURCE_LINK_ADDRESS
        );

        console.log(
            "Message Sender deployed on chainId: ",
            SOURCE_CHAIN_ID,
            "with address: ",
            address(basicMessageSender)
        );

        vm.stopBroadcast();
    }
}

contract DeployProgrammableTokens is Script, Helper {
    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address SOURCE_ROUTER_ADDRESS = vm.envAddress("SOURCE_ROUTER_ADDRESS");
        uint SOURCE_CHAIN_ID = vm.envUint("SOURCE_CHAIN_ID");

        vm.startBroadcast(deployerPrivateKey);

        // deploys: ProgrammableTokenTransfers on Mode Sepolia (source chain).
        ProgrammableTokenTransfers programmableTokenTransfers = new ProgrammableTokenTransfers(
                SOURCE_ROUTER_ADDRESS
        );

        console.log(
            "ProgrammableTokens contract deployed on chainId: ",
            SOURCE_CHAIN_ID,
            "with address: ",
            address(programmableTokenTransfers)
        );

        vm.stopBroadcast();
    }
}
