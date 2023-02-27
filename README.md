# Ring Universus Smart Contracts

# Components

1. Ring
2. Town
3. Coin
4. E (Equipment)
5. ... (Coming Soon)

## Avoid using ESM / BreakChange package

Do not upgrade major version for following packages:

1. chalk (ESM)
2. node-fetch (ESM)
3. ethers (BreakingChange)

## Local testing

```shell
# compile
yarn compile
# start node
yarn hardhat:node
# setting index
yarn hardhat:dev settingIndex
# deploy
yarn hardhat:dev deploy
```
