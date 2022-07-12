//SPDX-License-Identifier:GPL-3.0
pragma solidity >= 0.5.0 < 0.9.0;

import "./github.com/Prasoon180/superPAD_Final_Project_1/blob/main/BEP20.sol";       // This is not initialising 
contract BEP20_TOKEN_transfer{

constructor() {
    Owner = msg.sender;
}
    event TransferSent(address _from, address _destAddr, uint _amount);
    event TransferReceived(address _from, uint _amount);

    receive() payable external {
        balance += msg.value;
        emit TransferReceived(msg.sender, msg.value);
    } 


     
     function transferBEP20(BEP20 token, address to, uint256 amount) public {
         require(msg.sender == Owner, "Only Owner can withdraw funds");
         uint256 bep20balance = token.balanceOf(address(this));
         require(amount <= bep20balance, "balance is low");
         token.transfer(to, amount);
         emit TransferSent(msg.sender, to, amount);
     }
     }
