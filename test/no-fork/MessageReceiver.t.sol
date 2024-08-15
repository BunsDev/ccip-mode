// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {Test} from "forge-std/Test.sol";
import { console } from "forge-std/Script.sol";
// import {
//     CCIPLocalSimulator,
//     IRouterClient,
//     LinkToken,
//     BurnMintERC677Helper
// } from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
// import {BasicMessageReceiver} from "../../src/BasicMessageReceiver.sol";
import {BaseTest} from "../BaseTest.t.sol";

contract MessageReceiverTest is BaseTest {

    function setUp() public override {
        BaseTest.setUp();

    }

    function test_TransferTokensFromEoaToSmartContract() external {
        ccipLocalSimulator.requestLinkFromFaucet(alice, 5 ether);
        ccipBnMToken.drip(alice);
        uint balanceOfAliceBefore = ccipBnMToken.balanceOf(alice);
        console.log("balanceOfAliceBefore", balanceOfAliceBefore);
        uint balanceOfReceiverBefore = ccipBnMToken.balanceOf(address(basicMessageReceiver));
        console.log("balanceOfReceiverBefore", balanceOfReceiverBefore);
        assertEq(balanceOfAliceBefore, 1 ether);

        vm.startPrank(alice);

        uint amount = 100;
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
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amount);
        assertEq(balanceOfReceiverAfter, balanceOfReceiverBefore + amount);
    }
}
