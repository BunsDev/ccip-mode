// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";
import {BurnMintERC677Helper, IERC20} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

contract Example01ForkTest is Test {
    CCIPLocalSimulatorFork public ccipLocalSimulatorFork;
    uint256 public sourceFork;
    uint256 public destinationFork;
    address public alice;
    address public bob;
    IRouterClient public sourceRouter;
    uint64 public destinationChainSelector;
    BurnMintERC677Helper public sourceCCIPBnMToken;
    BurnMintERC677Helper public destinationCCIPBnMToken;
    IERC20 public sourceLinkToken;

    /// @notice The BurnMintERC677Helper instance for CCIP-BnM token
    BurnMintERC677Helper public CCIP_BNM;

    function setUp() public {
        CCIP_BNM = new BurnMintERC677Helper("CCIP-BnM", "CCIP-BnM");

        // vm.makePersistent(address(CCIP_BNM));

        string memory DESTINATION_RPC_URL = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");
        string memory SOURCE_RPC_URL = vm.envString("MODE_SEPOLIA_RPC_URL");
        string memory SOURCE_BNM_ADDRESS = vm.envString("SOURCE_BNM_ADDRESS");
        // string memory SOURCE_LNM_ADDRESS = vm.envString("SOURCE_LNM_ADDRESS");
        string memory SOURCE_LINK_ADDRESS = vm.envString("SOURCE_LINK_ADDRESS");
        string memory SOURCE_ROUTER_ADDRESS = vm.envString("SOURCE_ROUTER_ADDRESS");

        destinationFork = vm.createSelectFork(DESTINATION_RPC_URL);
        sourceFork = vm.createFork(SOURCE_RPC_URL);

        bob = makeAddr("bob");
        alice = makeAddr("alice");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        Register.NetworkDetails
            memory destinationNetworkDetails = ccipLocalSimulatorFork
                .getNetworkDetails(block.chainid);
        destinationCCIPBnMToken = BurnMintERC677Helper(
            destinationNetworkDetails.ccipBnMAddress
        );
        destinationChainSelector = destinationNetworkDetails.chainSelector;

        vm.selectFork(sourceFork);

        // supportNewToken(address(SOURCE_BNM_ADDRESS));

        sourceCCIPBnMToken = BurnMintERC677Helper(
            // "CCIP-BnM", "CCIP-BnM"
            // // SOURCE_BNM_ADDRESS
            0xB9d4e1141E67ECFedC8A8139b5229b7FF2BF16F5
        );
        sourceLinkToken = IERC20(
            // SOURCE_LINK_ADDRESS
            0x925a4bfE64AE2bFAC8a02b35F78e60C29743755d
        );
        sourceRouter = IRouterClient(
            // SOURCE_ROUTER_ADDRESS
            0xc49ec0eB4beb48B8Da4cceC51AA9A5bD0D0A4c43
        );
    }

    function prepareScenario()
        public
        returns (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint256 amountToSend
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

    function test_transferTokensFromEoaToEoaPayFeesInLink() external {
        (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint256 amountToSend
        ) = prepareScenario();
        vm.selectFork(destinationFork);
        uint256 balanceOfBobBefore = destinationCCIPBnMToken.balanceOf(bob);

        vm.selectFork(sourceFork);
        uint256 balanceOfAliceBefore = sourceCCIPBnMToken.balanceOf(alice);
        ccipLocalSimulatorFork.requestLinkFromFaucet(alice, 10 ether);

        vm.startPrank(alice);
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(bob),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: address(sourceLinkToken)
        });

        uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
        sourceLinkToken.approve(address(sourceRouter), fees);
        sourceRouter.ccipSend(destinationChainSelector, message);
        vm.stopPrank();

        uint256 balanceOfAliceAfter = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        uint256 balanceOfBobAfter = destinationCCIPBnMToken.balanceOf(bob);
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }

    function test_transferTokensFromEoaToEoaPayFeesInNative() external {
        (
            Client.EVMTokenAmount[] memory tokensToSendDetails,
            uint256 amountToSend
        ) = prepareScenario();
        vm.selectFork(destinationFork);
        uint256 balanceOfBobBefore = destinationCCIPBnMToken.balanceOf(bob);

        vm.selectFork(sourceFork);
        uint256 balanceOfAliceBefore = sourceCCIPBnMToken.balanceOf(alice);

        vm.startPrank(alice);
        deal(alice, 5 ether);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(bob),
            data: abi.encode(""),
            tokenAmounts: tokensToSendDetails,
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0})
            ),
            feeToken: address(0)
        });

        uint256 fees = sourceRouter.getFee(destinationChainSelector, message);
        sourceRouter.ccipSend{value: fees}(destinationChainSelector, message);
        vm.stopPrank();

        uint256 balanceOfAliceAfter = sourceCCIPBnMToken.balanceOf(alice);
        assertEq(balanceOfAliceAfter, balanceOfAliceBefore - amountToSend);

        ccipLocalSimulatorFork.switchChainAndRouteMessage(destinationFork);
        uint256 balanceOfBobAfter = destinationCCIPBnMToken.balanceOf(bob);
        assertEq(balanceOfBobAfter, balanceOfBobBefore + amountToSend);
    }
}
