# Ring Universus Smart Contracts

## Components

1. Ring
2. Town
3. Coin
4. E (Equipment)
5. Bounty
6. Player Logic (Core)
7. ... (More Coming Soon)

## Avoid using ESM / BreakChange package

Do not upgrade major version for following packages:

1. chai (ESM)
2. chalk (ESM)
3. node-fetch (ESM)

## Local testing

```shell
# compile
yarn compile
# start node
yarn hardhat:node
# setting index
yarn hardhat:dev settingIndex
# deploy
yarn deploy:contracts
# Interactive upgradable packages
yarn upgrade-interactive --latest
```
