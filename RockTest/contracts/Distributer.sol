pragma solidity 0.4.11;

import './RocketToken.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract Distributer is Ownable {

    using SafeMath for uint256;
 
    //operational
    uint256 public commited = 0;
    RocketToken token;

    
    mapping (address => uint256) public commitments;
    mapping (address => uint256) public commitTime;
    mapping (address => uint256) public commitDistributionsSnapshot;
    mapping (address => mapping (address => bool)) public gotAirdrop;
    mapping (address => uint256) public tokenDistributions;
    mapping (address => uint256) public tokenDistributionTimes;  

    function Distributer(address rocket){
        token = RocketToken(rocket);
    }  

    function distribute(address tokenAddress, uint256 amountToDistribute){
        MintableToken tok = MintableToken(tokenAddress);
        if(tok.balances[msg.sender] >= amountToDistribute){
            tok.balances[msg.sender] = tok.balances[msg.sender].sub(amountToDistribute);
            tokenDistributionTimes[tokenAddress] = now;
            tokenDistributions[tokenAddress] = tokenDistributions[tokenAddress].add(amountToDistribute);
            commitDistributionsSnapshot[tokenAddress] = commited;
            Distributed(tokenAddress, amountToDistribute);
        }
        else {Failed(amountToDistribute, tokenAddress, amountToDistribute);}
    }

    function commit(address beneficiary, uint256 amountToCommit){
        MintableToken tok = MintableToken(token);
        if(tok.balances[msg.sender] >= amountToCommit){
            tok.balances[msg.sender] = tok.balances[msg.sender].sub(amountToCommit);
            commitTime[beneficiary] = now;
            commitments[beneficiary] = commitments[beneficiary].add(amountToCommit);
            commited = commited.add(amountToCommit);
            Commited(beneficiary, amountToCommit);
        
        }
        else {Failed(amountToCommit, token, amountToCommit);}
    }

    function withdraw(address beneficiary, uint256 amountToWithdraw){
        if(commitments[msg.sender] >= amountToWithdraw){
            commitments[msg.sender] = commitments[msg.sender].sub(amountToWithdraw);
            commited = commited.sub(amountToWithdraw);
            tok.balances[beneficiary] = tok.balances[beneficiary].add(amountToWithdraw);
            Withdrawn(beneficiary, amountToWithdraw);
        }
        else {Failed(amountToWithdraw, msg.sender, amountToWithdraw);}
    }

    function collect(address beneficiary, address tokenAddress){
        if(!gotAirdrop[tokenAddress][beneficiary] && commitTime[beneficiary] <= tokenDistributionTimes[tokenAddress]){
            MintableToken tok = MintableToken(tokenAddress); 
            uint256 amount = tokenDistributions[tokenAddress].mul(commitments[beneficiary]).div(commitDistributionsSnapshot[tokenAddress]);
            commited = commited.sub(amountToWithdraw);
            tok.balances[msg.sender] = tok.balances[msg.sender].sub(amountToWithdraw);
            gotAirdrop[tokenAddress][beneficiary] = true;
            Collected(beneficiary, tokenAddress, amount);
        }
        else {Failed(amount, this, 1);}
    }