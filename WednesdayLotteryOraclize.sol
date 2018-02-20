pragma solidity ^0.4.18;

import "./oraclizeAPI.sol";

/**
 *  More complex lottery implementation
 *  Problem with this approach is that it is
 *  extremely expensive. This is because we are
 *  calculating random every time; todo However with this approach
 *  it could be more beneficial to keep track of all entries
 *  and then pick randomly at the end, that would be cheaper
 */

//WednesdayCoin Interface
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
contract WednesdayCoinLottery is usingOraclize {

    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);

    // WednesdayCoin contract being held
    WednesdayCoin public wednesdayCoin;

    // current holder/winner
    address private winner;

    // current total pot size
    uint256 public potSize;

    uint256 public jackPotSize;

    uint256 public randomInt;

    bool public runProofOnce;

    uint256 constant MAX_CONTRIBUTION = 25000000000000000000000;
    //100k
    uint256 constant INCREASE_JACKPOT = 100000000000000000000000;
    //100mil
    uint256 constant NORMALIZE_BY_100MIL = 100000000;

    function WednesdayCoinLottery() {
        wednesdayCoin = WednesdayCoin(0xEDFc38FEd24F14aca994C47AF95A14a46FBbAA16);
        potSize = 0;
        // 100k
        jackPotSize = 100000000000000000000000;
        runProofOnce = false;
        //oraclize_setProof(proofType_Ledger); // sets the Ledger authenticity proof in the constructor
        //update(); // let's ask for N random bytes immediately when the contract is created!
    }

    function receiveApproval(address from, uint256 value, address tokenContract, bytes extraData) returns (bool) {
        if (wednesdayCoin.transferFrom(from, this, value))
        {

            require(value <= MAX_CONTRIBUTION);

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
            uint256 dist = (value/potSize) * NORMALIZE_BY_100MIL;
            //this is for setproof to be used only 1 since it seems to expensive to call in constructor
            if (!runProofOnce) {
                oraclize_setProof(proofType_Ledger);
                runProofOnce = true;
            }
            update(); //generate another random number, cost will be on user submitting
            if ( randomInt <= dist ) {
                winner = from;
            }

            if (potSize >= jackPotSize) {
                release();
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

        //up jackpot by 100k
        jackPotSize += INCREASE_JACKPOT;
        potSize = 0;
        winner = 0x0;
    }

    // the callback function is called by Oraclize when the result is ready
    // the oraclize_randomDS_proofVerify modifier prevents an invalid proof to execute this function code:
    // the proof validity is fully verified on-chain
    function __callback(bytes32 _queryId, string _result, bytes _proof)
    {
        if (msg.sender != oraclize_cbAddress()) revert();

        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..

            newRandomNumber_bytes(bytes(_result)); // this is the resulting random number (bytes)

            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = NORMALIZE_BY_100MIL; // we want to generate a number 0-100000000
            uint randomNumber = uint(sha3(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range

            randomInt = randomNumber;
            newRandomNumber_uint(randomNumber); // this is the resulting random number (uint)
        }
    }

    function update() payable {
        uint N = 7; // number of random bytes we want the datasource to return
        uint delay = 0; // number of seconds to wait before the execution takes place
        uint callbackGas = 200000; // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas); // this function internally generates the correct oraclize_query and returns its queryId
    }

    function () payable {
        //call your function here / implement your actions
    }
}