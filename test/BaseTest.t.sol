// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "forge-std/Script.sol";
import { Test } from "forge-std/Test.sol";
// import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
// import {BasicTokenSender} from "../src/BasicTokenSender.sol";
import {BasicMessageReceiver} from "../src/BasicMessageReceiver.sol";
// import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {
    CCIPLocalSimulator,
    IRouterClient,
    LinkToken,
    BurnMintERC677Helper
} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
// import {Client} from "node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {BasicMessageReceiver} from "../src/BasicMessageReceiver.sol";

contract BaseTest is Test {
    bool private baseTestInitialized;

    CCIPLocalSimulator public ccipLocalSimulator;
    BasicMessageReceiver public basicMessageReceiver;
    address public alice;

    IRouterClient public router;
    uint64 public destinationChainSelector;
    BurnMintERC677Helper public ccipBnMToken;
    LinkToken public linkToken;

  function setUp() public virtual {

        ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            ,
            LinkToken link,
            BurnMintERC677Helper ccipBnM,
        ) = ccipLocalSimulator.configuration();

        router = sourceRouter;
        destinationChainSelector = chainSelector;
        ccipBnMToken = ccipBnM;
        linkToken = link;

        basicMessageReceiver = new BasicMessageReceiver(address(destinationRouter));

        alice = makeAddr("alice");
        console.log('alice: ', alice);
        // BaseTest.setUp is often called multiple times from tests' setUp due to inheritance.
        if (baseTestInitialized) return;
        baseTestInitialized = true;
  }
}