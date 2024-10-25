// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {DecentralizedStableCoin} from "./DecentralizesStableCoin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Ofuzor Chukwuemeke
 * @author Patrick Collins
 *
 * The system is designed to be as minimal as possible , and have the tokens maintain a 1 token == $1 peg
 * This stablecoin has the properties:
 * -Exogenoeous Colleteral
 * -Dollar Pegged
 * -Algorithmic Stable
 *
 * It is similar to DAI if DAI had no governance , no fees , and was only backed by WETH and WBTC
 *
 * Our DSC system should always be "overcollateralized". At no point , should the value of all colleteral <= the $ backed value of all the DSC.
 */

contract DSCEngine {
    // Errors

    error DSCEngine__NeedsMorethanZero();
    error DCSEngine__TokenAddressAndPriceFeedAddressMustbeTheSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();

    mapping(address token=>address priceFeed) private s_priceFeeds; 
    mapping(address user => mapping(address token => uint256 amount)) private s_colleteraldDeposited;
    mapping(address user => uint256 amountDeposited) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; 
    UINT256 private constant LIQUIDATION_PRECISION = 100;

    event ColleteralDeposited(address indexed user , address indexed token , uint256 indexed amount);
    // MODIFIER
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMorethanZero();
        }
        _;
    }

    modifer isAllowedToken(address token){
        if(s_priceFeeds[token] == address(0)){
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddress,address dscAddress){
        if(tokenAddresses.length != priceFeedAddress.length){
            revert DCSEngine__TokenAddressAndPriceFeedAddressMustbeTheSameLength();
        }

        for(uint256 i=0 ; i<tokenAddresses.length;i++){
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddress[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    // External Functions

    function depositCollateralAndMintDsc() external {}

    function depositColleteral(
        address tokenColleteral,
        uint256 amountColleteral
    ) external moreThanZero(amountColleteral) 
     nonReentrant
    isAllowedToken(tokenColleteral)
    {
        s_colleteraldDeposited[msg.sender][tokenColleteral] += amountColleteral;
        emit ColleteralDeposited(msg.sender,tokenColleteral,amountColleteral);
        bool success = IERC20(tokenColleteral).transferFrom(msg.sender,address(this),amountColleteral);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemColleteral() external {}

    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant{
        s_DSCMinted[msg.sender]+= amountDscToMint;
    }

    function redeemColleteralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external {}

    function _getAccountInformation(address user)private view returns (uint256 totalDscMinted,uint256 colleteralInUsd){
        totalDSCMinted = s_DSCMinted[user]
        colleteralValueInUsd = getAccountColleteralValueInUsd(user);
    }

    function _healthFactor(address user) private view returns(uint256){
        (uint256 totalDscMinted,uint256 colleteralValueInUsd) = _getAccounInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
    }

    function _revertIfHealthFactorIsBroken(address user)internal view{

    }

    function getAccountColleteralValueInUsd(address user) public view returns(uint256 totalCollateralValueInUsd){
        // loop through each colleteral tokens
        for(uint256 i=0;i<s_colleteralTokens.length;i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;

    }

    function getUsdValue(address token , uint256 amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[tokens]);
        (,int256 price , , ,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
