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
