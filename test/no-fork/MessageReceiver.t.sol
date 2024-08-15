// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Client} from "node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {console, BaseTest} from "../BaseTest.t.sol";

contract MessageReceiverTest is BaseTest {

    function setUp() public override {
        BaseTest.setUp();
    }

    function test_TransferTokens_EOA_SmartContract() external {
        ccipLocalSimulator.requestLinkFromFaucet(alice, 5 ether);
        ccipBnMToken.drip(alice);
        uint balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        uint balanceOfReceiverBefore = ccipBnMToken.balanceOf(address(basicMessageReceiver));
        assertEq(balanceOfAliceBefore, 1 ether);

        vm.startPrank(alice);

        uint amount = 1 ether;
        ccipBnMToken.approve(address(router), amount);

        Client.EVMTokenAmount[] memory tokensToSendDetails = new Client.EVMTokenAmount[](1);
        Client.EVMTokenAmount memory tokenToSendDetails =
            Client.EVMTokenAmount({token: address(ccipBnMToken), amount: amount});

        tokensToSendDetails[0] = tokenToSendDetails;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(basicMessageReceiver),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: "",
            feeToken: address(linkToken)
        });

        uint fees = router.getFee(destinationChainSelector, message);
        linkToken.approve(address(router), fees);

        router.ccipSend(destinationChainSelector, message);

        vm.stopPrank();

        uint balanceOfAliceAfter = ccipBnMToken.balanceOf(alice);
        uint balanceOfReceiverAfter = ccipBnMToken.balanceOf(address(basicMessageReceiver));

        console.log("Alice: ", balanceOfAliceBefore / 1e18, "->", balanceOfAliceAfter / 1e18);
        console.log("Receiver: ", balanceOfReceiverBefore / 1e18, "->", balanceOfReceiverAfter / 1e18);

        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amount);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amount);
    }
}
