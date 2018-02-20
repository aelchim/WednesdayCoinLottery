# WednesdayCoinLottery
Lottery game for WednesdayCoin. In this game people will use WednesdayCoin to enter the lottery. That coin goes into the pot. The pot then continues to grow until it hits the designated jackpot amount (starts at 100k). Once the pot size is greater than or equal to the jackpot, the lottery pays out. Once it pays out the pot resets to 0 and the jackpot gets upped by 100k for next time.

# WednesdayCoinLottery Oraclize
In this implementation we are using the oraclize function to come up with a secured random number. This is currently using the same approach for the winners but is too expensive as this requires the contract address to have ETH and having a call to the service for a random number per submission will be much too expensive. The best approach for this is to put all entries into a list then use the oraclize service to pick one randomly from that. Downside is that the winner will not be weighted based on amount contributed. Fix to that may be to have a static amount that is needed for entry - say 10k or 25k as the price for entry. 

## Winners
For-loops are expensive in solidity so we have 2 choices
  1. Each entry, regardless of amount, counts as 1 entry
  2. Weigh each entry based on amount submitted.
  
Putting 1 entry per submission is easy but then someone submitting 100000WED has the same chance as someone submitting 1WED, which seems a bit off to me. I was hoping for each WED entered we could put an entry into a list. So 500WED entered would create 500 Entries in the list and then at the end "randomly" pick one. For-loops to create entries would be expensive so we would have to go with something else.

To solve this and take into account amount submitted, we will use a modification of the [Reservoir Sampling](https://en.wikipedia.org/wiki/Reservoir_sampling) algorithm. We will generate a p-value for each submission that is amountSubmitted/PotSize. Then with that p-value (we will normalize in code since solidity doesn't suport floating point) we will generate a random number between 0-1. If the generated number is lower than the p-value they are the current winner.

Starting with 1 person submitting 50WED 

  1. p = 50/50 == 1 //amountSubmitted == 50, and potsize == 50 - we randomly generate a number between 0-1 but in this case any number less than 1 will work, so there is 100% chance they are the winner, they are the only entry after all :)
  2. p = 25/75 == .33 //person 2 submits 25, this increases potsize to 75 - we randomly generate a number between 0-1, they have a 33% chance of winning
  3. p = 1000/1075 == .93 //person 3 submits 1000, increaing potsize to 1075 - we gen a number between 0-1, they have a 93% chance of winning
  4. p = 1/1076 == .00092936802974 //person 4 submits 1, increasing potsize to 1076 - we gen a number between 0-1, the have a .0929% chance of winning
  
We believe this method is evenly distributed based on amount and is mathematically provable.  Issue with this is that it is heavily weighted on entries, so someone who is able to submit a large amount has a much larger chance of winning, discouraging people from submitting low amounts like 1 (though chance of winning evenly distributed). We are also only keeping of 1 entry, no longer a list of entries. When a user submits we calculate then if they are "winner" or not, though its not real winner since no jackpot. Given the example above: person #2 has a 33% chance of winningso say they win, then person #3 has a 93% chance of winning, and person #2 has a 7% chance of staying as "winner". Though everything is equal it doesn't seem as clear as a lottery. No random calculation is done at the end, who ever is winner gets the payout once jackpot is reached.

## Random
The random currently being used here is not secure enough for a lottery because it can be manipulated by the miner. However this may be the only way to do it without manual intervention.

`uint256 _seed = uint256(keccak256(
                _seed,
                block.blockhash(block.number - 1),
                block.coinbase,
                block.difficulty
            ));`

### Possible solution for random
The issue is that the seed can be manipulated by the miner. One possible solution is to have the seed be passed in by the contribution address.  We would no longer payout only if the pot is more than the jackpot, the contract would also need confirmation from the contribution address. This is still problematic because it centralizes the generation of the seed, both how and when. This can lead to mistrust as the contribution has all the power of the payouts.

### Oraclize
In the normal implementation we are using the random function stated above. In the Oraclize implementation we are using the [Oraclize](https://docs.oraclize.it/) service to generate a secure random number. Issue with that is that it is expensive and requires ETH to be in the contract address and to be used everytime it is called.
