// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizesStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract DeployDsc is Script{
    address[] public tokenAddreses;
    address[] public priceFeedAddresses;

    function run() external returns(DecentralizedStableCoin,DSCEngine){
        HelperConfig config = new HelperConfig();

        (address wethUsdPriceFeed , address wethUsdPriceFeed, address weth , address wbtc, uint256 deployerKey) = config.activeNetworkConfig();

        tokenAddreses = [weth,wbtc];
        priceFeedAddresses = [wethUsdPriceFeed,wbtcUsdPriceFeed];

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine engine = new DSCEngine(tokenAddreses,priceFeedAddresses,address(dsc));
        dsc.transferOwnership(engine);
        vm.stopBroadcast();
        return (dsc,engine);
    }

}

