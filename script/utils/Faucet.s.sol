// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "./Helper.sol";
import {Helper} from "./Helper.sol";

interface ICCIPToken {
    function drip(address to) external;
}

contract Faucet is Script, Helper {
    function run(bool isEthereum) external {
        SupportedNetworks network = isEthereum ? SupportedNetworks.ETHEREUM_SEPOLIA : SupportedNetworks.MODE_SEPOLIA;
    
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(senderPrivateKey);
        address senderAddress = vm.addr(senderPrivateKey);

        (address ccipBnm, address ccipLnm) = getDummyTokensFromNetwork(network);

        ICCIPToken(ccipBnm).drip(senderAddress);

        if (isEthereum) {
            ICCIPToken(ccipLnm).drip(senderAddress);
        }

        vm.stopBroadcast();
    }
}
