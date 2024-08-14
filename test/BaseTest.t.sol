// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console } from "lib/forge-std/src/Script.sol";
import { Test } from "lib/forge-std/src/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract BaseTest is Test {
    bool private s_baseTestInitialized;

    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint public sourceFork;
    uint public destinationFork;

    address public alice;
    address public bob;

    IRouterClient public sourceRouter;
    uint64 public destinationChainSelector;

    BurnMintERC677Helper public sourceCCIPBnMToken;
    BurnMintERC677Helper public destinationCCIPBnMToken;

    IERC20 public sourceLinkToken;
    address constant LINK_FAUCET = 0x4281eCF07378Ee595C564a59048801330f3084eE;

    Register immutable registerContract;

  function setUp() public virtual {

        string memory DESTINATION_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory SOURCE_RPC_URL = vm.envString(
            "MODE_SEPOLIA_RPC_URL"
        );

        // creates: forks
        destinationFork = vm.createSelectFork(DESTINATION_RPC_URL);
        sourceFork = vm.createFork(SOURCE_RPC_URL);

        // creates: peers
        bob = makeAddr("bob");
        alice = makeAddr("alice");

        // creates: CCIP Local Simulator Fork
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // DESTINATION CONFIGURATION //

        // stores: destination network details
        Register.NetworkDetails
            memory destinationNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);
        destinationCCIPBnMToken = BurnMintERC677Helper(
            destinationNetworkDetails.ccipBnMAddress
        );
        destinationChainSelector = destinationNetworkDetails.chainSelector;

        vm.selectFork(sourceFork);

        // DESTINATION CONFIGURATION //

        // SOURCE BNM TOKEN
        sourceCCIPBnMToken = BurnMintERC677Helper(
            0xB9d4e1141E67ECFedC8A8139b5229b7FF2BF16F5
        );

        // SOURCE LINK TOKEN
        sourceLinkToken = IERC20(0x925a4bfE64AE2bFAC8a02b35F78e60C29743755d);

        // SOURCE ROUTER
        sourceRouter = IRouterClient(
            0xc49ec0eB4beb48B8Da4cceC51AA9A5bD0D0A4c43
        );

        // BaseTest.setUp is often called multiple times from tests' setUp due to inheritance.
        if (s_baseTestInitialized) return;
        s_baseTestInitialized = true;
  }
}