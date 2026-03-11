//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract DSCEngine is ReentrancyGuard {
    DecentralisedStableCoin public immutable i_dsc;
    address[] public immutable i_tokenaddresses;

    mapping(address token => address pricefeeds) public s_priceFeeds;
    mapping(address user => mapping(address token => uint256 amount)) public s_collateralDeposited;

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


}