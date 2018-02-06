pragma solidity 0.4.19;

import './RocketToken.sol';
import '../zeppelin-solidity/contracts/crowdsale/Crowdsale.sol';
import '../zeppelin-solidity/contracts/ownership/Ownable.sol';


contract RocketTokenCrowdsale is Ownable, Crowdsale {

    using SafeMath for uint256;
 
    //operational
    bool public LockupTokensWithdrawn = false;
    uint256 public constant toDec = 10**18;
    uint256 public tokensLeft = 14700000*toDec;
    uint256 public constant cap = 14700000*toDec;
    uint256 public constant startRate = 1000;

    enum State { BeforeSale, Bonus, NormalSale, ShouldFinalize, Lockup, SaleOver }
    State public state = State.BeforeSale;

    /* --- Ether wallets --- */
    // Admin ETH Wallet: 0x0662a2f97833b9b120ed40d4e60ceec39c71ef18

    // 4% Team Tokens: 0x1EB5cc8E0825dfE322df4CA44ce8522981874d51

    // 1% For me

    // 25% Investor 1: TBC

    // Pre ICO wallets

    address[2] public wallets;

    uint256 public TeamSum = 840000*toDec; // 0 - 4%

    uint256 public MeSum = 210000*toDec; // 1 - 1%

    uint256 public InvestorSum = 5250000*toDec; // 2 - 25%


    // /* --- Time periods --- */

    uint256 public startTimeNumber = block.timestamp;

    uint256 public lockupPeriod = 180 * 1 days;

    uint256 public bonusPeriod = 90 * 1 days;

    uint256 public bonusEndTime = bonusPeriod + startTimeNumber;



    event LockedUpTokensWithdrawn();
    event Finalized();

    modifier canWithdrawLockup() {
        require(state == State.Lockup);
        require(endTime.add(lockupPeriod) < block.timestamp);
        _;
    }

    function RocketTokenCrowdsale(
        address _admin, /*used as the wallet for collecting funds*/
        address _team,
        address _me,
        address _investor)
    Crowdsale(
        block.timestamp + 10, // 2018-02-01T00:00:00+00:00 - 1517443200
        1527811200, // 2018-08-01T00:00:00+00:00 - 
        1000,/* start rate - 1000 */
        _admin
    )  
    public 
    {      
        wallets[0] = _team;
        wallets[1] = _me;
        owner = _admin;
        token.mint(_investor, InvestorSum);
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific MintableToken token.
    function createTokenContract() internal returns (MintableToken) {
        return new RocketToken();
    }

    function forwardFunds() internal {
        forwardFundsAmount(msg.value);
    }

    function forwardFundsAmount(uint256 amount) internal {
        wallet.transfer(amount);
    }

    function refundAmount(uint256 amount) internal {
        msg.sender.transfer(amount);
    }

    function fixAddress(address newAddress, uint256 walletIndex) onlyOwner public {
        wallets[walletIndex] = newAddress;
    }

    function calculateCurrentRate() internal {
        if (state == State.NormalSale) {
            rate = 500;
        }
    }

    function buyTokensUpdateState() internal {
        if(state == State.BeforeSale && now >= startTimeNumber) { state = State.Bonus; }
        if(state == State.Bonus && now >= bonusEndTime) { state = State.NormalSale; }
        calculateCurrentRate();
        require(state != State.ShouldFinalize && state != State.Lockup && state != State.SaleOver && msg.value >= toDec.div(2));
        if(msg.value.mul(rate) >= tokensLeft) { state = State.ShouldFinalize; }
    }

    function buyTokens(address beneficiary) public payable {
        buyTokensUpdateState();
        var numTokens = msg.value.mul(rate);
        if(state == State.ShouldFinalize) {
            lastTokens(beneficiary);
            numTokens = tokensLeft;
        }
        else {
            tokensLeft = tokensLeft.sub(numTokens); // if negative, should finalize
            super.buyTokens(beneficiary);
        }
    }

    function lastTokens(address beneficiary) internal {
        require(beneficiary != 0x0);
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokensForFullBuy = weiAmount.mul(rate);// must be bigger or equal to tokensLeft to get here
        uint256 tokensToRefundFor = tokensForFullBuy.sub(tokensLeft);
        uint256 tokensRemaining = tokensForFullBuy.sub(tokensToRefundFor);
        uint256 weiAmountToRefund = tokensToRefundFor.div(rate);
        uint256 weiRemaining = weiAmount.sub(weiAmountToRefund);
        
        // update state
        weiRaised = weiRaised.add(weiRemaining);

        token.mint(beneficiary, tokensRemaining);
        TokenPurchase(msg.sender, beneficiary, weiRemaining, tokensRemaining);

        forwardFundsAmount(weiRemaining);
        refundAmount(weiAmountToRefund);
    }

    function withdrawLockupTokens() canWithdrawLockup public {
        token.mint(wallets[1], MeSum);
        token.mint(wallets[0], TeamSum);
        LockupTokensWithdrawn = true;
        LockedUpTokensWithdrawn();
        state = State.SaleOver;
    }

    function finalizeUpdateState() internal {
        if(now > endTime) { state = State.ShouldFinalize; }
        if(tokensLeft == 0) { state = State.ShouldFinalize; }
    }

    function finalize() public {
        finalizeUpdateState();
        require (state == State.ShouldFinalize);

        finalization();
        Finalized();
    }

    function finalization() internal {
        endTime = block.timestamp;
        /* - preICO investors - */
        tokensLeft = 0;
        state = State.Lockup;
    }
}
