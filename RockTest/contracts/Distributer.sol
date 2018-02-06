pragma solidity 0.4.11;

import './RocketToken.sol';
import '../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract RocketTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
 
    //operational
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**2;
    uint256 public commited = 0;
    RocketToken token;

    
    mapping (address => uint256) public saleRecord;
    mapping (address => uint256) public commitTime;
    mapping (address => mapping (address => bool)) public gotAirdrop;
    mapping(address => uint256) public tokenDistributions;
    mapping(address => uint256) public tokenDistributionTimes;  

    function RocketToken(address _otherOwner) OtherToken(_otherOwner){}  

    function distribute(address tokenAddress, uint256 amountToDistribute){
        OtherToken tok = OtherToken(tokenAddress);
        if(tok.balanceOf(msg.sender) >= amountToDistribute){
            tok.burn(amountToDistribute);
            tokenDistributionTimes[tokenAddress] = now;
            tokenDistributions[tokenAddress] = tokenDistributions[tokenAddress].add(amountToDistribute);
            Distributed(tokenAddress, amountToDistribute);
        }
        else {Failed(amountToDistribute, tokenAddress, amountToDistribute);}
    }

    function commit(address beneficiary, uint256 amountToCommit){
        OtherToken tok = OtherToken(token);
        if(tok.balanceOf(msg.sender) >= amountToCommit){
            tok.burn(amountToCommit);
            commitTime[beneficiary] = now;
            saleRecord[beneficiary] = saleRecord[beneficiary].add(amountToCommit);
            commited = commited.add(amountToCommit);
            Commited(beneficiary, amountToCommit);
        
        }
        else {Failed(amountToCommit, token, amountToCommit);}
    }

    function withdraw(address beneficiary, uint256 amountToWithdraw){
        if(saleRecord[msg.sender] >= amountToWithdraw){
            saleRecord[beneficiary] = saleRecord[beneficiary].sub(amountToWithdraw);
            token.mint(beneficiary, amountToWithdraw);
            commited = commited.sub(amountToWithdraw);
            Withdrawn(beneficiary, amountToWithdraw);
        }
        else {Failed(amountToWithdraw, msg.sender, amountToWithdraw);}
    }

    function collect(address beneficiary, address tokenAddress){
        if(!gotAirdrop[tokenAddress][beneficiary] && commitTime[beneficiary] <= tokenDistributionTimes[tokenAddress]){
            OtherToken tok = OtherToken(tokenAddress); 
            uint256 amount = tokenDistributions[tokenAddress].mul(saleRecord[beneficiary]).div(commited);
            tok.mint(beneficiary, amount);
            gotAirdrop[tokenAddress][beneficiary] = true;
            Collected(beneficiary, tokenAddress, amount);
        }
        else {Failed(amount, this, 1);}
    }