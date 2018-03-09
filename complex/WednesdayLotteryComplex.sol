pragma solidity ^0.4.18;

import "./ownable.sol";
import "./destructible.sol";
import "./tokenInterfaces.sol";

/**
 *  More complex lottery implementation
 *  We keep track of all entries
 *  End to lottery will be
 */


/**
 * @title WednesdayCoinLottery
 * @dev WednesdayCoinLottery is a token lottery where people will give tokens to enter
 * and once enough time has passed the lottery will give the pot to a random person
 */
contract WednesdayCoinLottery is Ownable, Destructible {

    // WednesdayCoin contract being held
    WednesdayCoin public wednesdayCoin;

    // list of entries
    address[] public entries;

    // current total pot size
    uint256 public potSize;

    //Hash proof of initial random value, this is set (roughly) before the lottery begins
    uint256 public hashProof;

    //combined hash of entry addresses
    uint256 public aggregateHash = 0x0;

    uint256 public entriesCount = 0;

    //10k entry
    uint256 public contribution = 10000000000000000000000;

    bool public stopLottery;

    function WednesdayCoinLottery() {
        wednesdayCoin = WednesdayCoin(0xEDFc38FEd24F14aca994C47AF95A14a46FBbAA16);
        potSize = 0;
        stopLottery = false;
    }

    function receiveApproval(address from, uint256 value, address tokenContract, bytes extraData) returns (bool) {
        require(stopLottery == false);

        if (wednesdayCoin.transferFrom(from, this, value)) {
            //from check to owner allows owner to up the pot with being put as an entry
            if (from != owner) {
                require(value == contribution);
                entries.push(from);
                entriesCount++;
                aggregateHash = uint256(keccak256(aggregateHash, from));
            }

            //add value to pot regardless of owner or not
            potSize += value;
        }
    }

    /**
     * @notice Transfers tokens to random winner
     */
    function release(uint256 _randomNumber, uint256 _newHashProof) public onlyOwner {
        require(stopLottery == false);
        //require Wednesday(3)
        uint8 dayOfWeek = uint8((now / 86400 + 4) % 7);
        require(dayOfWeek == 3);

        //Check hat the hashproof has been set
        require(hashProof != 0x0);

        //This is to prove that the random number we submit is the same one calculated before the start of the lottery
        require(uint256(keccak256(_randomNumber)) == hashProof);

        uint256 randomInt = uint256(keccak256(aggregateHash, _randomNumber)) % (entriesCount - 1);
        address winner = entries[randomInt];

        //check that winner is not 0x0
        require(winner != 0x0);

        wednesdayCoin.transfer(winner, potSize);

        potSize = 0;

        //This is the new hashProof for the next lottery to prove once again that the random number is calculated before the start of the lottery
        hashProof = _newHashProof;
    }

    function setContribution(uint256 _newContribution) public onlyOwner {
        contribution = _newContribution;
    }

    function setStopLottery(bool _stopLottery) public onlyOwner {
        stopLottery = _stopLottery;
    }

    // Used for transferring any accidentally sent ERC20 Token by the owner only
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // Used for transferring any accidentally sent Ether by the owner only
    function transferEther(address dest, uint amount) public onlyOwner {
        dest.transfer(amount);
    }

    function setHashProof(uint256 _hashProof) public onlyOwner {
        hashProof = _hashProof;
    }

    function clearEntries() public onlyOwner {
        delete entries;
    }
}