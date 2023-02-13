# Ring Universus Smart Contracts

# Components

1. Ring
2. Town
3. ... (Coming Soon)

## Avoid using ESM / BreakChange package

Do not upgrade major version for following packages:

1. chalk (ESM)
2. node-fetch (ESM)
3. ethers (BreakChange)

## Local testing

```shell
# compile
yarn compile
# start node
yarn hardhat:node
# deploy
yarn hardhat:dev deploy
```
