//SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//100000000000000000000
contract ATokens is ERC20{
    constructor() ERC20("AToken","ATN"){
    }

    function mint(address _address,uint256 _value) internal{
        _mint(_address,_value);
    } 

    function burn(address _address,uint256 _value) internal{
         _burn(_address,_value);
    }
}