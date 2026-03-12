//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test} from "forge-std/Test.sol";
import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {

    DSCEngine public dscEngine;
    DecentralisedStableCoin public dsc;

    address weth;
    address wbtc;

    constructor(DSCEngine _dscEngine , DecentralisedStableCoin _dsc){
        dscEngine = _dscEngine;
        dsc = _dsc;

        address[] memory tokenAddress = dscEngine.getCollateralAddresses();
        weth = tokenAddress[0];
        wbtc = tokenAddress[1];
    }

    function depositCollateral( uint256 collateralSeed , uint256 amount) public{
        ERC20Mock collateral =  getCollateralFromSeed(collateralSeed);
        amount = bound(amount , 1 , 10 ether);

        vm.startPrank(msg.sender);
        collateral.mint(msg.sender, amount);
        collateral.approve(address(dscEngine), amount);
        dscEngine.depositCollateral(address(collateral), amount);
        vm.stopPrank();
    }

    function getCollateralFromSeed(uint256 collateralSeed) public view returns (ERC20Mock){
        if(collateralSeed % 2 == 0){
            return ERC20Mock(weth);
        }
        else{
            return ERC20Mock(wbtc);

        }
        
    }
}