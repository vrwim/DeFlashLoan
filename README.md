# DeFlashLoan

- Users can deposit ERC20 tokens
    - Receive liquidity tokens from that, for liquidity and bookkeeping
    - Users can choose a fee level that they want to receive: lower -> more flash loans; higher -> less flash loans, more commission per flash loan
- Users can withdraw ERC20 tokens
    - By burning liquidity tokens
- Users can take a flash loan and then must return `amount * (1 + fee percentage)`
    - Commission is distributed over users that deposited
- Commission calculations happen based on the highest percentage that was needed for the flash loan

## Open questions
- Liquidity is not possible :( Either I have a fixed fee or I have different liquidity tokens per ERC20 token (one per fee level)
    - Possibly a DAO-model to decide on the fee level per token?
- Need to research reinserting rewards in the pool to compound interest
- How to efficiently store staking rewards? rewardDebt... But what about reinserting rewards??