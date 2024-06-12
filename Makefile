# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

.PHONY: test clean

# Build & test
build                   :; forge build
coverage                :; forge coverage
gas                     :; forge test --gas-report
gas-check               :; forge snapshot --check --tolerance 1
snapshot                :; forge snapshot
clean                   :; forge clean
fmt                     :; forge fmt
test                    :; forge test -vvvv --gas-report

# Deploy
deploy-pool-implementation-base-mainnet		:; forge script script/DeployPoolImplementation.s.sol:DeployPoolImplementation --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-pool-implementation-tenderly			:; forge script script/DeployPoolImplementation.s.sol:DeployPoolImplementation --force --rpc-url tenderly --slow --broadcast -vvv

deploy-price-oracle-sentinel-base-mainnet		:; forge script script/DeployPriceOracleSentinel.s.sol:DeployPriceOracleSentinel --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-price-oracle-sentinel-tenderly			:; forge script script/DeployPriceOracleSentinel.s.sol:DeployPriceOracleSentinel --force --rpc-url tenderly --slow --broadcast -vvv

deploy-config-engine-base-mainnet		:; forge script script/DeployConfigEngine.s.sol:DeployConfigEngine --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-config-engine-tenderly			:; forge script script/DeployConfigEngine.s.sol:DeployConfigEngine --force --rpc-url tenderly --etherscan-api-key ${TENDERLY_ACCESS_KEY} --verifier-url ${TENDERLY_VERIFY_URL} --slow --broadcast --verify --delay 5 -vvv

deploy-risk-steward-base-mainnet		:; forge script script/DeployRiskSteward.s.sol:DeployRiskSteward --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-risk-steward-tenderly			:; forge script script/DeployRiskSteward.s.sol:DeployRiskSteward --force --rpc-url tenderly --etherscan-api-key ${TENDERLY_ACCESS_KEY} --verifier-url ${TENDERLY_VERIFY_URL} --slow --broadcast --verify --delay 5 -vvv

deploy-interest-strategy-base-mainnet		:; forge script script/DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-interest-strategy-tenderly			:; forge script script/DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy --force --rpc-url tenderly --etherscan-api-key ${TENDERLY_ACCESS_KEY} --verifier-url ${TENDERLY_VERIFY_URL} --slow --broadcast --verify --delay 5 -vvv

deploy-rewards-controller-base-mainnet		:; forge script script/DeployRewardsController.s.sol:DeployRewardsController --force --rpc-url base --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-rewards-controller-tenderly			:; forge script script/DeployRewardsController.s.sol:DeployRewardsController --force --rpc-url tenderly --etherscan-api-key ${TENDERLY_ACCESS_KEY} --verifier-url ${TENDERLY_VERIFY_URL} --slow --broadcast --verify --delay 5 -vvv

replay-reward-state						:; forge test --match-contract ReplayRewardState

startAnvil :; anvil --fork-url "wss://base-mainnet.g.alchemy.com/v2/Sx7otGaSe8SUjRwxUlGPJWqHmp0BuCnK" --fork-block-number 15505539
anvilSetup :; cast rpc anvil_autoImpersonateAccount true --rpc-url http://127.0.0.1:8545 && cast rpc anvil_setBalance 0x639d2dD24304aC2e6A691d8c1cFf4a2665925fee 1000000000000000000 --rpc-url http://127.0.0.1:8545
upgradeAnvilRewardController :; forge script script/UpgradeRewardController.s.sol:UpgradeRewardController --unlocked --rpc-url http://127.0.0.1:8545 --broadcast -vvv --sender 0x639d2dD24304aC2e6A691d8c1cFf4a2665925fee
getDuneData :; curl -H "X-Dune-API-Key:lL8RcBkGR2tLdXje40zvFC8YpuSq9kH0" "https://api.dune.com/api/v1/query/3801423/results?limit=20000" > ./tsscripts/final/userAssetReward.json
runJsFinal :; ts-node ./tsscripts/final/index.ts