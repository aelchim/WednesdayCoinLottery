pragma solidity ^0.4.18;

import "./oraclizeAPI.sol";
import "./ownable.sol";
import "./destructible.sol";
import "./tokenInterfaces.sol";

/**
 *  More complex lottery implementation
 *  Using oraclize will generate a securely random number
 *  Using it is more expensive so ETH will need to be used
 */


/**
 * @title WednesdayCoinLottery
 * @dev WednesdayCoinLottery is a token lottery where people will give tokens to enter
 * and once the pot has been reached the lottery will give the pot to a random person
 */
contract WednesdayCoinLottery is usingOraclize, Ownable, Destructible {

    event newRandomNumber_bytes(bytes);
    event newRandomNumber_uint(uint);

    // WednesdayCoin contract being held
    WednesdayCoin public wednesdayCoin;

    // list of entries
    address[] public entries;

    // current total pot size
    uint256 public potSize;

    uint256 public jackPotSize;

    uint256 public randomInt;
    //10k entry
    uint256 public contribution = 10000000000000000000000;
    //100k
    uint256 public increaseJackpotBy = 100000000000000000000000;

    function WednesdayCoinLottery() {
        wednesdayCoin = WednesdayCoin(0xEDFc38FEd24F14aca994C47AF95A14a46FBbAA16);
        potSize = 0;
        // 100k
        jackPotSize = 100000000000000000000000;
        //set owner to first one in case call to oraclize fail
        entries.push(owner);
        oraclize_setProof(proofType_Ledger);
        update();
    }

    function receiveApproval(address from, uint256 value, address tokenContract, bytes extraData) returns (bool) {
        if (wednesdayCoin.transferFrom(from, this, value)) {
            if (from != owner) {
                require(value == contribution);
            }
            //add value to pot
            potSize += value;

            if (from != owner) {
                entries.push(from);

                if (potSize >= jackPotSize) {
                    release();
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

        randomInt = randomInt % entries.length;
        address winner = entries[randomInt];

        require(winner != 0x0);

        wednesdayCoin.transfer(winner, potSize);

        //up jackpot by 100k
        jackPotSize += increaseJackpotBy;
        potSize = 0;
        update();
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

            newRandomNumber_bytes(bytes(_result));
            // this is the resulting random number (bytes)

            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = 2**(8* 7);
            // we want to generate a number
            uint randomNumber = uint(sha3(_result)) % maxRange;
            // this is an efficient way to get the uint out in the [0, maxRange] range

            randomInt = randomNumber;

            //randomInt = 0;
            newRandomNumber_uint(randomNumber);
            // this is the resulting random number (uint)
        }
    }

    function update() payable {
        uint N = 7;
        // number of random bytes we want the datasource to return
        uint delay = 0;
        // number of seconds to wait before the execution takes place
        uint callbackGas = 200000;
        // amount of gas we want Oraclize to set for the callback function
        bytes32 queryId = oraclize_newRandomDSQuery(delay, N, callbackGas);
        // this function internally generates the correct oraclize_query and returns its queryId
    }

    function() payable {
        //call your function here / implement your actions
    }

    function setContribution(uint256 _newContribution) public onlyOwner {
        contribution = _newContribution;
    }

    function setIncreaseJackpot(uint256 _increaseJackpot) public onlyOwner {
        increaseJackpotBy = _increaseJackpot;
    }

    // Used for transferring any accidentally sent ERC20 Token by the owner only
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // Used for transferring any accidentally sent Ether by the owner only
    function transferEther(address dest, uint amount) public onlyOwner {
        dest.transfer(amount);
    }
}