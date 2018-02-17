# WednesdayCoinLottery
Lottery game for WednesdayCoin. In this game people will use WednesdayCoin to enter the lottery. That coin goes into the pot. The pot then continues to grow until it hits the designated jackpot amount (starts at 1 million). Once the pot size is greater than or equal to the jackpot, the lottery pays out. Once it pays out the pot resets to 0 and the jackpot gets upped by 1mil + pot size for next time.

## Winners

## Random
The random currently being used here is not secure enough for a lottery because it can be manipulated by the miner. However thi may be the only way to do it without manual intervention.

`uint256 _seed = uint256(keccak256(
                _seed,
                block.blockhash(block.number - 1),
                block.coinbase,
                block.difficulty
            ));`

### Possible solution for random
The issue is that the seed can be manipulated by the miner. One possible solution is to have the seed be passed in by the contribution address.  We would no longer payout only if the pot is more than the jackpot, the contract would also need confirmation from the contribution address. This is still problematic because it centralizes the generation of the seed, both how and when. This can lead to mistrust as the contribution has all the power of the payouts.
