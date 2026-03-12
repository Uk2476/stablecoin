// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "../src/DecentralisedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../script/DeployDSC.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import { ERC20Mock } from "../test/mocks/ERC20Mock.sol";



contract DSCEngineTest is Test {

    DSCEngine public dscEngine;
    DecentralisedStableCoin public dsc;
    HelperConfig public Config;
    DeployDSC public deployer;

    address public etherUsdPriceFeed;
    address public wbtcUsdPriceFeed;
    address public weth;
    address public wbtc;  
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    address public user = makeAddr("User");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_BALANCE= 10 ether;

    modifier depositCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dscEngine), AMOUNT_COLLATERAL);
        dscEngine.depositCollateral(weth , AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function setUp() public{
        deployer = new DeployDSC();
        (dscEngine , dsc , Config) = deployer.run();
        (etherUsdPriceFeed , wbtcUsdPriceFeed , weth , wbtc , ) = Config.activeNetworkConfig();
        ERC20Mock(weth).mint(user , STARTING_BALANCE);
        ERC20Mock(wbtc).mint(user , STARTING_BALANCE);

    }


    function testGetPriceInUsd() public view{
        uint256 priceInUsd =  dscEngine.getPriceinUsd(weth);
        assertEq(priceInUsd , 1000 ether);
    }

    function testRevertsIfTokenLengthDoesNotMatchPriceFeedSlength() external {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(etherUsdPriceFeed);
        priceFeedAddresses.push(wbtcUsdPriceFeed);

        vm.expectRevert(DSCEngine.dsc_tokensandpricefeedslengthmismatcch.selector);
        new DSCEngine(tokenAddresses , priceFeedAddresses , address(dsc));
    }


    function testGetTokenAmountFromUsd() public view {
        uint256 tokenAmountFromUsd = dscEngine.getTokenAmountFromUsd(weth , 1000 );
        assertEq(tokenAmountFromUsd , 1 );
    }

    function testGetCollateralVAlueInUsd () public {
        vm.prank(user);
        uint256 collateralValueInUsd = dscEngine.getCollateralValueInUsd(user);
        assertEq(collateralValueInUsd , 20000 ether);
    }  

    function testRevertsWithUnapprovedCollateral() public{
        ERC20Mock notListedCollateral = new ERC20Mock("NotListedCollateral" , "NLC" , msg.sender , 1000e18);
        vm.prank(user);
        vm.expectRevert(DSCEngine.dsc_notavalidcollateral.selector);
        dscEngine.depositCollateral(address(notListedCollateral), 1000e18);
    }

    function testDepositCollateral() public depositCollateral(){
        uint256 collateralDEposited = dscEngine.getCollateralBalance(user, weth);
        assertEq(collateralDEposited, AMOUNT_COLLATERAL);
    }
}