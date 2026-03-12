//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


contract DSCEngine is ReentrancyGuard {

    error dsc_amountmustbegreaterthanzero();
    error dsc_notavalidcollateral();
    error dsc_tokensandpricefeedslengthmismatcch(); 
    error dsc_transferfailed();
    error dsc_healthfactorlessthanone();
    error dsc_healthFactorisOkay();
    error dsc_healthFFactorDoesNotImprove();

    DecentralisedStableCoin public immutable i_dsc;
    address[] public tokenaddresses;

    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant LIQUIDATION_BONUS = 10;

    mapping(address token => address pricefeeds) public s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) public s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) public s_DscMinted;

    modifier moreThanZero(uint256 amount){
        if(amount == 0) {
            revert dsc_amountmustbegreaterthanzero();
        }
        _;
    }

    modifier validCollateral (address token){
        if(s_priceFeeds[token] == address(0)){
            revert dsc_notavalidcollateral();
        }
        _;
    }

    constructor(address[] memory tokens , address[] memory pricefeeds , address dscAddress) {
        if(tokens.length != pricefeeds.length ){
            revert dsc_tokensandpricefeedslengthmismatcch();
        }
        for(uint256 i = 0 ; i < tokens.length ; i++){
            s_priceFeeds[tokens[i]] = pricefeeds[i];
            tokenaddresses.push(tokens[i]);
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
        
    }

    function depositCollateral(address collateralDepositAddress , uint256 amount) public moreThanZero(amount) validCollateral(collateralDepositAddress) nonReentrant {
        s_collateralDeposited[msg.sender][collateralDepositAddress] += amount;
        bool success = IERC20(collateralDepositAddress).transferFrom(msg.sender , address(this) , amount);
        if(!success){
            revert dsc_transferfailed();
        }

    }

    function mintDSc(uint256 amount) public moreThanZero(amount) nonReentrant {
        s_DscMinted[msg.sender] += amount ;
        if (healthFactor(msg.sender) < 1e18){
            revert dsc_healthfactorlessthanone();
        }
        i_dsc.mint(msg.sender , amount);
    }

    function depositCollateralAndMintDsc (address collateralAddress , uint256 collateralAmount , uint256 dscAmount) external {
        depositCollateral(collateralAddress, collateralAmount);
        mintDSc(dscAmount);
    }

    function redeemCollateral( address collateralAddress  , uint256 amount) public moreThanZero(amount) validCollateral(collateralAddress) nonReentrant {
        s_collateralDeposited[msg.sender][collateralAddress] -= amount ;
        bool success = IERC20(collateralAddress).transfer(msg.sender , amount );
        if(!success){
            revert dsc_transferfailed();
        }

        if (healthFactor(msg.sender) < 1e18){
            revert dsc_healthfactorlessthanone();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) nonReentrant(){
        s_DscMinted[msg.sender] -= amount ;
        bool success = i_dsc.transferFrom(msg.sender , address (this) , amount);
        if(!success){
            revert dsc_transferfailed();
        }
        i_dsc.burn(amount);
    }

    function redeemCollateralAndBurnDsc ( address collateralAddress , uint256 collateralAmount , uint256 dscAmount) external {
        redeemCollateral(collateralAddress, collateralAmount);
        burnDsc(dscAmount);
    }


    function liquidate(address collateral, address user, uint256 debtToCover) external {
        uint256 healthFactorInStart = healthFactor(user);
        if (healthFactorInStart >= 1e18) {
            revert dsc_healthFactorisOkay();
        }
        uint256 collateralAmountToCover = getTokenAmountFromUsd(collateral , debtToCover);
        uint256 bonusCollateral = (collateralAmountToCover * LIQUIDATION_BONUS) / 100;

        s_collateralDeposited[user][collateral] -= collateralAmountToCover;
        s_DscMinted[user] -= debtToCover;
        s_collateralDeposited[msg.sender][collateral] += collateralAmountToCover + bonusCollateral;
        
        bool success = i_dsc.transferFrom(msg.sender , address (this) , debtToCover);
        if(!success){
            revert dsc_transferfailed();
        }
        uint256 healthFactorInend = healthFactor(user);
        if (healthFactorInend<= healthFactorInStart){
            revert dsc_healthFFactorDoesNotImprove();
        }
    }


    function healthFactor(address user) public view returns (uint256){
        uint256 totalDscMinted = s_DscMinted[user];
        if (totalDscMinted == 0){
            return type(uint256).max;
        }
        uint256 totalCollateralValueInUsd = getCollateralValueInUsd(user);
        return ((totalCollateralValueInUsd * LIQUIDATION_THRESHOLD * 1e18)/100 / totalDscMinted) ;
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        for(uint256 i=0 ; i < tokenaddresses.length ; i++){
            totalValue += (s_collateralDeposited[user][tokenaddresses[i]] * getPriceinUsd(tokenaddresses[i]))/1e18;
        }
        return totalValue;
    }

    function getPriceinUsd(address token) public view returns (uint256){
        address priceFeedAddress = s_priceFeeds[token];
        AggregatorV3Interface exchangeRate = AggregatorV3Interface(priceFeedAddress);
        (,int256 price ,,,)= exchangeRate.latestRoundData();
        return uint256(price) * 1e10;
        
    }

    function getTokenAmountFromUsd(address token , uint256 usdAmount) public view returns (uint256) {
        uint256 price = getPriceinUsd(token);
        return (usdAmount * 1e18) / price;
    }

    function getCollateralBalance(address user , address collateral) public view returns (uint256){
        return s_collateralDeposited[user][collateral];
    }

    function getDscMinted(address user) public view returns (uint256){
        return s_DscMinted[user];
    }
     
    function getCollateralAddresses() public view returns (address[] memory){
        return tokenaddresses;
    }

}