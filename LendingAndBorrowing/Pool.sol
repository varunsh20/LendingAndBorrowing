//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ATokens.sol";

contract Pool is ATokens{

    IERC20 public immutable lendingToken;
    IERC20 public immutable borrowingToken;
    address public immutable owner;

    uint256 public aTokensSupply;
    uint16 public constant LENDERS_INTEREST = 35;  //3.5%, we are using fixed interest rate
    uint16 public constant BORROWERS_INTEREST = 4; //4%

    uint256 public constant COLLATERAL_PERCENT = 80; //user can only borrow upto 80% of thier collateral

    uint256 public SECONDS_IN_YEAR = 31536000; //1 year in equivalent seconds

    uint256 public lenderIntersAccured;
    uint256 public borrowersInterestAccured;

    //we are considering lending token is a volatile asset and borrowing token is a stable coin.
    // price of 1 lending token = 2500 stable coins

    mapping(address=>userInfo) public usersInfo;

    struct userInfo{
        address userAddress;
        uint256 collateral;
        uint256 debt;
        uint256 lendAt;
        uint256 borrowAt;
    }

    event CollateralDeposited(
        address indexed user,
        uint256 amount,
        uint256 depositedAt
    );

    event CollateralWithdrawn(
        address indexed user,
        uint256 amount,
        uint256 withdrawnAt
    );

    event AmountBorrowed(
        address indexed user,
        uint256 amount,
        uint256 borrowedAt
    );

    event AmountRepayed(
        address indexed user,
        uint256 amount,
        uint256 borrowedAt
    );

    constructor(address _tokenA,address _tokenB){
        lendingToken = IERC20(_tokenA);
        borrowingToken = IERC20(_tokenB);
        owner = msg.sender;
    }

    modifier invalidAmount(uint256 _amount){
        require(_amount>0,"Invalid amount");
        _;
    }

    function getPriceStable(uint256 _volatileToken) public pure returns(uint256){
        return _volatileToken*2500;
    }

    function getPriceVolatile(uint256 _stableToken) public pure returns(uint256){
        return _stableToken/2500;
    }

    function deposit(address _token,uint256 _amount) external invalidAmount(_amount){
        require(_token==address(lendingToken));
        mint(msg.sender,_amount);
        aTokensSupply+=_amount;
        lenderIntersAccured+=lendersInterest(msg.sender);  //all interest accured till this time, is calculated
        usersInfo[msg.sender].collateral+=_amount;
        usersInfo[msg.sender].lendAt = block.timestamp;
        lendingToken.transferFrom(msg.sender,address(this),_amount);
        emit CollateralDeposited(msg.sender,_amount,block.timestamp);
    }

    function withdraw(uint256 _amount) external invalidAmount(_amount){
        require(usersInfo[msg.sender].debt==0,"Pay debt");
        require(balanceOf(msg.sender)>=_amount,"Insufficient balance");
        burn(msg.sender,_amount);
        aTokensSupply-=_amount;
        lenderIntersAccured = lendersInterest(msg.sender);  //all interest accured till this time, is calculated
        uint256 withdrawnAmount = _amount+lenderIntersAccured;
        lendingToken.transferFrom(address(this),msg.sender,withdrawnAmount);
        usersInfo[msg.sender].collateral-=_amount;
        usersInfo[msg.sender].lendAt = block.timestamp; //updating lendAt so that, upadted interest is calculated
        emit CollateralWithdrawn(msg.sender,withdrawnAmount,block.timestamp);  // for next time frame
    }

    function borrow(address _address, uint256 _amount) external invalidAmount(_amount){
        require(_address==address(borrowingToken));
        require(_amount<=getMaxBorrow(_amount),"Insufficient collateral");
        borrowersInterestAccured+=borrowersInterest(msg.sender); 
        usersInfo[msg.sender].debt+=_amount;
        usersInfo[msg.sender].borrowAt = block.timestamp;
        borrowingToken.transfer(msg.sender,_amount);
        emit AmountBorrowed(msg.sender,_amount,block.timestamp);
    }

    function repay(uint256 _repayAmount) external invalidAmount(_repayAmount){
        borrowersInterestAccured  = borrowersInterest(msg.sender); 
        uint256 total = _repayAmount+borrowersInterestAccured;
        borrowingToken.transferFrom(msg.sender,address(this),total);
        usersInfo[msg.sender].debt-=_repayAmount;
        usersInfo[msg.sender].borrowAt = block.timestamp; //updating lendAt so that, upadted interest is calculated
        emit AmountRepayed(msg.sender,total,block.timestamp); // for next time frame
    }

    function getMaxBorrow(uint256 _amount) private view invalidAmount(_amount) returns(uint256){
        uint256 collateralInStable = getPriceStable(usersInfo[msg.sender].collateral);
        uint256 maxBorrow = (collateralInStable*COLLATERAL_PERCENT)/100;
        return maxBorrow;
    }

    function lendersInterest(address _address) public view returns(uint256){
        uint256 principle = usersInfo[_address].collateral;
        if(principle==0){
            return 0;
        }
        uint256 interestPerSecond = principle*COLLATERAL_PERCENT*(block.timestamp-usersInfo[_address].lendAt)/
        (SECONDS_IN_YEAR*1000);
        return interestPerSecond;
    }

    function borrowersInterest(address _address) public view returns(uint256){
        uint256 debt = usersInfo[_address].debt;
        if(debt==0){
            return 0;
        }
        uint256 interestPerSecond = debt*BORROWERS_INTEREST*(block.timestamp-usersInfo[_address].borrowAt)/
        (SECONDS_IN_YEAR*100);
        return interestPerSecond;
    }

    function lendingTokenApprove(uint256 _amount) public{
        lendingToken.approve(address(this),_amount);
    }

    function borrowingTokenApprove(uint256 _amount) public{
        borrowingToken.approve(address(this),_amount);
    }

}