// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizesStableCoin.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;
    uint256 MAX_DEPOSIT_SIZE = type(uint96).max

    constructor(DSCEngine _dscEngine,DecentralizedStableCoin _dsc){
        dcse = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbth = ERC20Mock(collateralTokens[1]);
    }
    function depositCollateral(address collateral , uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        amountCollateral = bound(amountCollateral,1,MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender,amountCollateral);
        collateral.approve(address(dsce),amountCollateral);
        dsce.depositColleteral(address(collateral),amountCollateral);
    }

    function minDsc(uint256 amount) public{
        amount = bound(amount,1,MAX_DEPOSIT_SIZE);
        (uint256 totalDscMinted,uint256 collateralValueInUsd) = dsce.getAccountInformation(msg.sender);

        int256 maxDscToMint = (int2556(collateralValueInUsd)/2) - int256(totalDscMinted);
        if(maxDscToMint <0){{
            return;
        }
        amount = bound(amount,0,uint256(maxDscToMint));
        if(amount == 0){
            return;
        }        
        vm.startPrank(msg.sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
    }

    function _getCollateralFromSeed(uint256 collateralSeed) private view returns(ERC20Mock){
        if(collateralSeed % 2 == 0){
            return weth;
        }
        return wbtc;
    }

    function redeemCollateral(uint256 collateralSeed,uint256 amountCollateral) public{
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dscEngine.getCollateralBalanceOfUser(address(collateral),msg.sender);
        amountCollateral = bound(amountCollateral,0,maxCollateralToRedeem);
        if(amountCollateral == 0){
            return ;
        }
        dsce.redeemColleteral(address(collateral),amountCollateral);
    }
}