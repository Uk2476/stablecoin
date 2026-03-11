//SPDX_License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";

contract DSCEngine {
    DecentralisedStableCoin public immutable i_dsc;
    address[] public immutable i_tokenaddresses;

    mapping(address token => address pricefeeds) public s_priceFeeds;

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

    function depositCollateral(address collateralDepositAddress , uint256 amount) external {
        // this function is used to deposit collateral of diiferent token address for a particular address ,
        // for this you have to create two mapping 
        // and connect it with ierc20 , add some modifiers also 
    }


}