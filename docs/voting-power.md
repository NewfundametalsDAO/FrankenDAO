# Voting Power Calculations

This document will outline how your voting power is calculated and how it will
change based on the voting multipliers. As a member of the FrankenDAO community,
you have a say in how participation is rewarded by voting on and controlling the
voting multipliers. These multipliers will give certain types of participation
more or less 'weight' in everyone's voting power. The thing that is most
rewarded in the system though is participation: the number of FrankenPunks you
stake, the number of times you vote, etc.

The rest of this document will explain how the individual pieces of your voting
power are calculated.

## Voting Power

Your total voting power is based on two things: your tokens' evil scores and
your community score. These two values combined give you your total voting
power.

These two values are controlled by actions you take in the DAO, such as staking
a FrankenPunk or voting on a proposal. The voting multipliers 'weight' these
actions, increasing their value. So, if you assume that all weights are set to
1 (i.e. no actions are given extra weight), the way to increase your voting
power are to:

1. Stake FrankenPunks in the DAO. (FrankenPunks with higher Evil Scores are given more voting power.)
2. Vote on proposals
3. Create proposals
4. Have a proposal that passes

The first action determines your VP from tokens (token score). Actions
2 through 4 determine your community score.

## Calculating Voting Power

The value of your token score (or voting power from the FrankenPunks you own) is
based on the number of tokens you have staked, the Evil Score of your staked
tokens, and the staking bonus applied based on how long you commit your tokens
for.

Each staked FrankenPunk gives a DAO member a base of 20 voting power. Staking
a FrankenPunk with an Evil Score greater than 1.5 will provides a bonus on top
of that base of 10 points. The exact formula is: 

```
((baseVotes * multipler) / 100) + stakedTimeBonus + evilBonus
```

Where:
* `baseVotes` is the bonus for staking a FrankenPunk
* `multiplier` is the optional multiplier tied to staking
* `stakedTimeBonus` is the bonus earned for staking length
* `evilBonus` is either 10 or 0, depending on how Evil your FrankenPunk is

A possible scenario:

Let's say you were to stake [FrankenPunk
#4701](https://opensea.io/assets/ethereum/0x1fec856e25f757fed06eb90548b0224e91095738/4701).
If you staked the token with no stake time bonus, your score would break down as
follows:

| Attribute | Value |
| --- | --- |
| Token Id  | 4701  |
| Base Votes  | 20  |
| Multiplier  | 1x  |
| Stake Time Bonus  | 0  |
| Evil Bonus  | 1.13035  |

Your voting power would be **20**.

Now, let's say you stake the same token for four weeks and earn the stake time
bonus:

| Attribute | Value |
| --- | --- |
| Token Id  | 4701  |
| Base Votes  | 20  |
| Multiplier  | 1x  |
| Stake Time Bonus  | 20  |
| Evil Bonus  | 1.13035  |

Now your voting power for the same token is **40**.

The stake time bonus is linear across the staking window. So if the stake window
is 4 weeks and the bonus is 20 VP, staking a token for 2 weeks would earn you 10
VP (or half the total possible staking bonus).

## Community Score

Your total community score is based on how much you participate in the DAO. More
participation is rewarded. The three ways to increase your voting power here are
to:
 
1. Vote on proposals
2. Create and submit proposals
3. Have a proposal pass

Each of these actions is then subject to a community score multiplier. The
default multipliers are:
 
| Action | Multipler % | Multiplier # |
| --- | --- | --- |
| Voting  | 100%  | 1x  |
| Creating a proposal | 200%  | 2x  |
| Passing proposal  | 200%  | 2x  |

Scenario:

Let's say you've participated actively over the last three months and have voted
on 15 proposals. You've also submitted 2 proposals of your own, 1 of which did
pass and one of which did not. Your scores would then be:

| Action | Multiplier | Base Points | VP |
| --- | --- | --- | --- |
| Voting  | 1x  | 15  | 15 |
| Proposing  | 2x  | 2  | 4 |
| Passing  | 2x  | 1  | 2 |

Your total community score voting power would then be: 21.

## All Together

Let's say you hold tokens #2146, #6707, and #2671 and stake all three for the
max staking bonus (4 weeks, for 20 bonus for each token). Let's also say you've
actively participated and have voted on 15 proposals, submitted 2 of your own,
and had 1 of them pass.

This is how your token voting power would break down:

| Token ID | Evil Score | Stake Bonus | Voting Power |
| --- | --- | --- | --- |
| #2146  | 1.40952 | 20  | 40 |
| #6707  | 2.5 | 20  | 50  |
| #2671  | 1.1865 | 20  | 40  |

Your total token voting power is: 130

This is how your community score would break down:

| Action | Multiplier | Base Points | VP |
| --- | --- | --- | --- |
| Voting  | 1x  | 15  | 15 |
| Proposing  | 2x  | 2  | 4 |
| Passing  | 2x  | 1  | 2 |

Your total community voting power would be: 21

Your total voting power is the combination of these two, which would be
**151**.

As you can see the 'Community Voting Power' addition is added to the wallet's
other tokens' voting power. The community voting power metric will benefit
smaller holders the most.

