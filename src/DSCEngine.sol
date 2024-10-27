// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {DecentralizedStableCoin} from "./DecentralizesStableCoin.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Ofuzor Chukwuemeke
 * @author Ofuzor chukwuemeke
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

contract DSCEngine is ReentrancyGuard {
    // Errors

    error DSCEngine__NeedsMoreThanZero();
    error DCSEngine__TokenAddressAndPriceFeedAddressMustbeTheSameLength();
    error DSCEngine__TokenNotAllowed(address token);
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 healthFactor);
    error DSCEngine__MintFailed();

    mapping(address token=>address priceFeed) private s_priceFeeds; 
    mapping(address user => mapping(address token => uint256 amount)) private s_colleteralDeposited;
    mapping(address user => uint256 amountDeposited) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e10;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; 
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR =1;

    event ColleteralDeposited(address indexed user , address indexed token,uint256 indexed amount);
    // MODIFIER
     ///////////////////
    // Modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__TokenNotAllowed(token);
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

    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral,uint256 amountDscToMint) external {
        depositColleteral(tokenColleteral, amountColleteral);
        mintDsc(amountDscToMint);
    }

    function depositColleteral(
        address tokenColleteral,
        uint256 amountColleteral
    ) external moreThanZero(amountColleteral) 
     nonReentrant
    isAllowedToken(tokenColleteral)
    {
        s_colleteralDeposited[msg.sender][tokenColleteral] += amountColleteral;
        emit ColleteralDeposited(msg.sender,tokenColleteral,amountColleteral);
        bool success = IERC20(tokenColleteral).transferFrom(msg.sender,address(this),amountColleteral);
        if(!success){
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemColleteral() external {}

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant{
        s_DSCMinted[msg.sender]+= amountDscToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender,amountDscToMint);
        if(!minted){
            revert DSCEngine__MintFailed();
        }
    }

    function redeemColleteralForDsc() external {}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external {}

    function _getAccountInformation(address user)private view returns (uint256 totalDscMinted,uint256 colleteralValueInUsd){
        totalDscMinted = s_DSCMinted[user];
        colleteralValueInUsd = getAccountColleteralValueInUsd(user);
    }

    function _healthFactor(address user) private view returns(uint256){
        (uint256 totalDscMinted,uint256 colleteralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (colleteralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;

        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }


    function _revertIfHealthFactorIsBroken(address user)internal view{
        uint256 userhealthFactor = _healthFactor(user);
        if(userhealthFactor < MIN_HEALTH_FACTOR){
            revert DSCEngine__BreaksHealthFactor(userhealthFactor);
        }
    }

    function getAccountColleteralValueInUsd(address user) public view returns(uint256 totalCollateralValueInUsd){
        // loop through each colleteral tokens
        for(uint256 i=0;i<s_collateralTokens.length;i++){
            address token = s_collateralTokens[i];
            uint256 amount = s_colleteralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;

    }

    function getUsdValue(address token , uint256 amount) public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price , , ,) = priceFeed.latestRoundData();
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION;
    }
}
