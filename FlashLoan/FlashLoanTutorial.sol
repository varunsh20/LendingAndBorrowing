// contracts/FlashLoan.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from  "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase {
    address public owner;

    constructor(address _addressProvider) 
    FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"Not allowed");
        _;
    }

    function executeOperation(address asset,uint256 amount,uint256 premium,address initiator,
    bytes calldata params) external returns (bool){
        uint256 _amount = amount+premium;
        IERC20(asset).approve(address(POOL),_amount);  //approving pool to retrieve their funds on this contract 
        return true;                                   //behalf
    }

    function requestLoan(address asset,uint256 amount) external{
        address receiverAddress = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;
        POOL.flashLoanSimple(receiverAddress,asset,amount,params,referralCode);
    } 

    function withdraw(address _asset, uint256 amount) external onlyOwner{
        require(IERC20(_asset).balanceOf(owner)>=amount,"Insufficient funds");
        IERC20(_asset).transfer(owner,amount);
    }

    function getBalance(address _asset) external view returns(uint256){
      return IERC20(_asset).balanceOf(address(this));
    }
}