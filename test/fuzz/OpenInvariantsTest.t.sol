// What are our Invariants ?

//  1. The total supply of Dsc should be less than the total value of collateral
//  2. Getter View functions should not be reverted

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {DeployDsc} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizesStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant , Test{
    DeployDsc deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external{
        deployer = new DeployDsc();
        (dsc,dsce,config) = deployer.run();
        (,,weth,btc) = config.activeNetworkConfig();
      
        handler = new Handler(dsce,dsc);
        targetContract(address(handler));
    }

    function Invariant_protocolMusthaveMoreValueThanTotalSupply() public view{
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalBtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth,totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc,totalBtcDeposited);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}