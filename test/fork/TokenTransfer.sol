// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import "forge-std/Script.sol";

contract ForkTest is Script, Test {
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

    /// @notice immutable register instance.
    Register immutable registerContract;

    /// @notice address of the LINK faucet.
    address constant LINK_FAUCET = 0x4281eCF07378Ee595C564a59048801330f3084eE;

    function setUp() public {
        string memory DESTINATION_RPC_URL = vm.envString(
            "ETHEREUM_SEPOLIA_RPC_URL"
        );
        string memory SOURCE_RPC_URL = vm.envString("MODE_SEPOLIA_RPC_URL");

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
    }

    // prepares: balances, token, amountToSend
    function prepareScenario()
        public
        returns (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint amountToSend
        )
    {
        vm.selectFork(sourceFork);
        vm.startPrank(alice);
        sourceCCIPBnMToken.drip(alice);

        amountToSend = 100;
        sourceCCIPBnMToken.approve(address(sourceRouter), amountToSend);

        tokensToSendDetails = new Client.EVMTokenAmount[](1);
        tokensToSendDetails[0] = Client.EVMTokenAmount({
            token: address(sourceCCIPBnMToken),
            amount: amountToSend
        });

        vm.stopPrank();
    }

    // [test] sends: tokens from EOA -> EOA | fee: LINK
    function test_transfer_EOA_EOA_FeesInLink() external {
        (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint amountToSend
        ) = prepareScenario();
        vm.selectFork(destinationFork);

        // forks: Mode Sepolia
        vm.selectFork(sourceFork);
        (uint balanceOfBobBefore, uint balanceOfAliceBefore) = getPreBalances();
        
        vm.selectFork(sourceFork);

        requestLinkFromFaucet(alice, 10 ether);

        vm.startPrank(alice);

        // creates: message to send.
         Client.EVM2AnyMessage memory message = createMessage(address(sourceLinkToken), tokensToSendDetails);
        
        // sends: approves LINK fees for router
        uint fees = sourceRouter.getFee(destinationChainSelector, message);
        sourceLinkToken.approve(address(sourceRouter), fees);

        // router: sends message
        sourceRouter.ccipSend(destinationChainSelector, message);
        vm.stopPrank();

        // asserts: post balances are correct.
        (uint balanceOfBobAfter, uint balanceOfAliceAfter) = getPostBalances();
        // alice spends: `amountToSend`
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);
        // bob receives: `amountToSend`
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }

    // [test] sends: tokens from EOA -> EOA | fee: native (ETH)
    function test_transfer_EOA_EOA_FeesInNative() external {
        // gets: tokensToSendDetails, amountToSend
        (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint amountToSend
        ) = prepareScenario();

        (uint balanceOfBobBefore, uint balanceOfAliceBefore) = getPreBalances();
        
        vm.selectFork(sourceFork);

        vm.startPrank(alice);
        deal(alice, 5 ether);

        // creates: message to send.
        Client.EVM2AnyMessage memory message = createMessage(address(0), tokensToSendDetails);

        // sends: fees to router
        uint fees = sourceRouter.getFee(destinationChainSelector, message);
        sourceRouter.ccipSend{value: fees}(destinationChainSelector, message);
        vm.stopPrank();

        // asserts: post balances are correct.
        (uint balanceOfBobAfter, uint balanceOfAliceAfter) = getPostBalances();
        // alice spends: `amountToSend`
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);
        // bob receives: `amountToSend`
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }

    // HELPER FUNCTIONS //

    function createMessage(address feeToken, Client.EVMTokenAmount[] memory tokensToSendDetails) public view returns (Client.EVM2AnyMessage memory message) {
        message = Client.EVM2AnyMessage({
            receiver: abi.encode(bob),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: feeToken
        });
    }

    // gets: BNM balances (before)
    function getPreBalances()
        public
        returns (uint balanceBob, uint balanceAlice)
    {
        // gets: BNM balances
        vm.selectFork(sourceFork);
        balanceAlice = sourceCCIPBnMToken.balanceOf(alice);

        vm.selectFork(destinationFork);
        balanceBob = destinationCCIPBnMToken.balanceOf(bob);

        console.log("bob (before)", balanceBob);
        console.log("alice (before)", balanceAlice);
    }
    
    // gets: BNM balances (after)
    function getPostBalances()
        public
        returns (uint balanceBob, uint balanceAlice)
    {
        balanceAlice = sourceCCIPBnMToken.balanceOf(alice);
        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        balanceBob = destinationCCIPBnMToken.balanceOf(bob);

        console.log("bob (after)", balanceBob);
        console.log("alice (after)", balanceAlice);
    }

    // helper function: requests LINK from faucet.
    function requestLinkFromFaucet(
        address to,
        uint amount
    ) public returns (bool success) {
        address linkAddress = block.chainid == 919
            ? 0x925a4bfE64AE2bFAC8a02b35F78e60C29743755d
            : registerContract.getNetworkDetails(block.chainid).linkAddress;

        vm.startPrank(LINK_FAUCET);
        success = IERC20(linkAddress).transfer(to, amount);
        vm.stopPrank();
    }
}
