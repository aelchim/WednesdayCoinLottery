# WednesdayCoinLottery
We are using a different approach for this lottery game. In this game people will use WednesdayCoin to enter the lottery. That coin goes into the pot. The pot then continues to grow until some time has passed, say 6 hours. Once enough time has passed, the lottery payout wil be initiated by the contract owner. Once it pays out the pot resets to 0.

## Approach
This is a simpler approach where we do have a list of entries. Each entry is now 10,000 WED, that is what is currently set but can be changed later. Each entry will be added to an array and once payout is initiated, we will randomly select one.

## Random
We are deciding random ourselves before the lottery. To prove this we are storing the hash of the random number in the contract before the lottery begins. Once the payout will occur we will pass the random number and the contract will hash it and compare to the stored hashProof. This way we can prove that the random number was decided before the lottery begins and that is was NOT changed while the lottery was occurring. This way we prove that the random number has not been influenced based on the entries.
