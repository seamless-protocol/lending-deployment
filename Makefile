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
deploy-pool-implementation-base-mainnet		:; forge script script/DeployPoolImplementation.s.sol:DeployPoolImplementation --force --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-pool-implementation-tenderly			:; forge script script/DeployPoolImplementation.s.sol:DeployPoolImplementation --force --chain tenderly --slow --broadcast -vvv

deploy-price-oracle-sentinel-base-mainnet		:; forge script script/DeployPriceOracleSentinel.s.sol:DeployPriceOracleSentinel --force --chain base --slow --broadcast --verify --delay 5 -vvv
deploy-price-oracle-sentinel-tenderly			:; forge script script/DeployPriceOracleSentinel.s.sol:DeployPriceOracleSentinel --force --chain tenderly --slow --broadcast -vvv