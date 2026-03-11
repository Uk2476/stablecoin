//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract DSCEngine is ReentrancyGuard {
    DecentralisedStableCoin public immutable i_dsc;
    address[] public immutable i_tokenaddresses;

    uint256 public constant LIQUIDATION_THRESHOLD = 50;

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
            i_tokenaddresses.push(tokens[i]);
        }
        i_dsc = DecentralisedStableCoin(dscAddress);
        
    }

    function depositCollateral(address collateralDepositAddress , uint256 amount) external moreThanZero(amount) validCollateral(collateralDepositAddress) nonReentrant {
        s_collateralDeposited[msg.sender][collateralDepositAddress] += amount;
        bool success = IERC20(collateralDepositAddress).transferFrom(msg.sender , address(this) , amount);
        if(!success){
            revert dsc_transferfailed();
        }

    }

    function mintDSc(uint256 amount) external moreThanZero(amount) nonReentrant {
        s_DscMinted[msg.sender] += amount ;
        if (healthFactor(msg.sender) < 1){
            revert dsc_healthfactorlessthanone();
        }
        bool success = i_dsc.mint(msg.sender , amount);
        if(!success){
            revert dsc_mintfailed();
        }
    }

    function healthFactor(address user) public view returns (uint256){
        uint256 totalDscMinted = s_DscMinted[user];
        uint256 totalCollateralValueInUsd = getCollateralValueInUsd(user);
        return ((totalCollateralValueInUsd * LIQUIDATION_THRESHOLD * 1e18)/100 / totalDscMinted) ;
    }

    function getCollateralValueInUsd(address user) public view returns (uint256) {
        uint256 totalValue = 0;
        for(uint256 i=0 ; i < i_tokenaddresses.length ; i++){
            totalValue += (s_collateralDeposited[user][i_tokenaddresses[i]] * getPriceinUsd(i_tokenaddresses[i]))/1e18;
        }
        return totalValue;
    }

    function getPriceinUsd(address token) public view returns (uint256){
        address priceFeedAddress = s_priceFeeds[token];
        AggregatorV3Interface exchangeRate = AggregatorV3Interface(priceFeedAddress);
        (,int256 price ,,,)= exchangeRate.latestRoundData();
        return uint256(price) * 1e10;
        
    }
}