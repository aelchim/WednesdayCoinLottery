pragma solidity ^0.4.18;

//WednesdayCOin Interface
contract WednesdayCoin {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
}


/**
 * @title WednesdayCoinLottery
 * @dev WednesdayCoinLottery is a token lottery where people will give tokens to enter
 * and once the pot has been reached the lottery will give the pot to a random person
 */
contract WednesdayCoinLottery {

    // WednesdayCoin contract being held
    WednesdayCoin public wednesdayCoin;

    // current holder/winner
    address private winner;

    // current total pot size
    uint256 public potSize;

    address public contributionAddress;

    uint256 public jackPotSize;

    function WednesdayCoinLottery() {
        wednesdayCoin = WednesdayCoin(0xEDFc38FEd24F14aca994C47AF95A14a46FBbAA16);
        contributionAddress = 0x05C73b2f42AE86C69F9A9fCB0d6de75821117bb4;
        potSize = 0;
        // 1mil
        jackPotSize = 1000000000000000000000000;
    }

    function receiveApproval(address from, uint256 value, address tokenContract, bytes extraData) returns (bool) {
        if (wednesdayCoin.transferFrom(from, this, value))
        {
            //require Wednesday(3)
            uint8 dayOfWeek = uint8((now / 86400 + 4) % 7);
            require(dayOfWeek == 3);

            //add value to pot
            potSize += value;

            //for-loop is expensive - each entry is only 1
            //We need to account for value of entry - more WED should give higher chance
            //i.e. 1000WED should count for 1000 entries and have a higher chance than 10WED
            /*
             * 1. p = 50/50 == 1
             * 2. p = 25/75 == 0.333
             * 3. p = 1000/1075 == 0.93
             * 4. p = 1/1076 == 0.00092936802974
             */
            //Solidity does not have floating point so we will mult by 100,000,000 to give 8 digits of precision
            uint256 dist = (value/potSize) * 100000000;

            if (dist <= random(100000000) && from != contributionAddress) {
                winner = from;

                if (potSize >= jackPotSize) {
                    release();
                    //up jackpot by 1mil
                    jackPotSize = potSize + 1000000000000000000000000;
                    potSize = 0;
                }
            }
        }
    }

    /**
     * @notice Transfers tokens to random winner
     */
    function release() public {
        //require Wednesday(3)
        uint8 dayOfWeek = uint8((now / 86400 + 4) % 7);
        require(dayOfWeek == 3);
        //require current pot size to be >= jackpot
        require(potSize >= jackPotSize);

        require(winner != 0x0);

        wednesdayCoin.transfer(winner, potSize);
    }

    /**
     * Get Current Pot Size
     */
    function potSize() public constant returns (uint) {
        return potSize;
    }

    /**
     * Get Current JackPot Size
     */
    function jackPotSize() public constant returns (uint) {
        return jackPotSize;
    }

    function maxRandom() public returns (uint256 randomNumber) {
        uint256 _seed = uint256(keccak256(
                _seed,
                block.blockhash(block.number - 1),
                block.coinbase,
                block.difficulty
            ));
        return _seed;
    }

    // return a pseudo random number between lower and upper bounds
    // given the number of previous blocks it should hash.
    function random(uint256 upper) public returns (uint256 randomNumber) {
        return maxRandom() % upper;
    }
}