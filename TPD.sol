// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TPD is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint; // you can make a call like myUint.add(123)
  
    uint256 public priceTPD = 1 ether;
    uint256 constant public TOTAL_SUPPLY = 3000000000;
    uint256 constant public TEAM_SUPPLY = 600000000;
    uint256 constant public TEAM_STEP_SUPPLY = 150000000;
    uint256 constant public INVESTOR_SUPPLY = 300000000;
    uint256 constant public INVESTOR_STEP_SUPPLY = 60000000;
    uint256 constant public SALE_SUPPLY = 2100000000;

    address public TEAM_ADDRESS = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db; //TEST ADDRESS
    address public INVESTOR_ADDRESS = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; //TEST ADDRESS

    uint8 public stepTransferTeam = 0;    //  1, 2, 3, 4 step
    uint8 public stepTransferInvestor = 0;    //  1, 2 step
    uint8 public stepBurn = 0;    //  1, 2, ..., 10 step
    uint256 public releaseTime = 0;       // datatime when contract deployed
  
    constructor() ERC20("Takaprotocol Token", "TPD") {
        _mint(msg.sender, TOTAL_SUPPLY);
        _transfer(msg.sender, TEAM_ADDRESS, TEAM_STEP_SUPPLY);
        releaseTime = block.timestamp;
        stepTransferTeam = 1;
    }
    function transfer(address recipient, uint256 amount) public virtual override onlyOwner returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferToTeam() public onlyOwner{
        require(stepTransferTeam < 4, "The step of minting for our team is over.");
        require(block.timestamp.sub(releaseTime) > stepTransferTeam*365*24*3600, "You can't transfer yet. Only once in a year.");
        transfer(payable(TEAM_ADDRESS), TEAM_STEP_SUPPLY);
        stepTransferTeam += 1;
    }
    function transferToInvestor() public onlyOwner{
        require(stepTransferInvestor < 3, "The step of minting for the investors is over.");
        if(stepTransferInvestor == 0){
            require(block.timestamp.sub(releaseTime) > 30*24*3600*3, "You can't transfer yet. Only once in a year.");
            transfer(payable(INVESTOR_ADDRESS), INVESTOR_STEP_SUPPLY);   
        }else{
            require(block.timestamp.sub(releaseTime) > stepTransferInvestor*365*24*3600, "You can't transfer yet. Only once in a year.");
            transfer(payable(INVESTOR_ADDRESS), INVESTOR_STEP_SUPPLY.mul(2));        
        }
        stepTransferInvestor += 1;
    }
    function calcFeeDiscount(uint256 curFee) public view returns (uint256) {
        require(curFee > 0, "There is no fee.");       
        uint256 subTime = block.timestamp.sub(releaseTime);
        uint256 discountFee;
        if(subTime > 0 && subTime <= 365*24*3600){
            discountFee = curFee.div(2);
        }else if (subTime > 365*24*3600 && subTime <= 2*365*24*3600){
            discountFee = (curFee.mul(3)).div(4);
        }else if(subTime > 2*365*24*3600 && subTime <= 3*365*24*3600){
            discountFee = (curFee.mul(7)).div(8);
        }else if(subTime > 3*365*24*3600 && subTime <= 4*365*24*3600){
            discountFee = (curFee.mul(15)).div(16);
        }else{
            discountFee = curFee;
        }
        return discountFee;
    }
    function burn(uint256 percent) public virtual override onlyOwner {
        uint256 amount_owner = balanceOf(owner()).mul(percent).div(100);
        uint256 amount_team = balanceOf(TEAM_ADDRESS).mul(percent).div(100);
        uint256 amount_investor = balanceOf(INVESTOR_ADDRESS).mul(percent).div(100);
        uint256 amount = amount_owner.add(amount_team).add(amount_investor);
        require(totalSupply().sub(amount) >= 1500000000, "The burning is ended.");
        require(block.timestamp.sub(releaseTime) > stepBurn*30*24*3600*3, "You can't burn yet. Only once in a quarter.");
        _burn(owner(), amount_owner);
        _burn(TEAM_ADDRESS, amount_team);
        _burn(INVESTOR_ADDRESS, amount_investor);
        stepBurn += 1;
    }
    function setTokenPrice(uint256 _price) external onlyOwner{
        priceTPD = _price;
    }
    function setTeamAddress(address _address) external onlyOwner{
        TEAM_ADDRESS = _address;
    }
    function setInvestorAddress(address _address) external onlyOwner{
        INVESTOR_ADDRESS = _address;
    }
    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "There is no balance.");
        payable(owner()).transfer(address(this).balance);        
    }
}