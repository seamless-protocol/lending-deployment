import "forge-std/Script.sol";
import {RewardsController} from "seamless/aave-v3-periphery/rewards/RewardsController.sol";
import {Constants} from "./Constants.sol";
import {IPoolAddressesProvider} from "seamless/aave-v3-periphery/misc/interfaces/IUiIncentiveDataProviderV3.sol";

contract NewRewardController is RewardsController {
    constructor(address emissionManager) RewardsController(emissionManager) {}

    function getUserRewards(address user, address asset, address reward) external view returns (uint256) {
        return _assets[asset].rewards[reward].usersData[user].accrued;
    }
}

contract UpgradeRewardController is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        console.log("Deployer address: ", deployerAddress);
        console.log("Deployer balance: ", deployerAddress.balance);
        console.log("BlockNumber: ", block.number);
        console.log("ChainId: ", block.chainid);

        vm.startBroadcast(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);


        // NewRewardController newRewardController = new NewRewardController(Constants.EMISSION_MANAGER);

        NewRewardController newRewardController = NewRewardController(Constants.REWARDS_CONTROLLER);

        console.log(newRewardController.getUserRewards(0x002841301d1AB971D8acB3509Aa2891e3ef9D7E1, 0x53E240C0F985175dA046A62F26D490d1E259036e, 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913));


        vm.stopBroadcast();


        // vm.startBroadcast(0x639d2dD24304aC2e6A691d8c1cFf4a2665925fee);




// IPoolAddressesProvider poolAddressProvider = IPoolAddressesProvider(0x0E02EB705be325407707662C6f6d3466E939f3a0);
// poolAddressProvider.setAddressAsProxy(keccak256("INCENTIVES_CONTROLLER"), address(newRewardController));

//         vm.stopBroadcast();








    }
}

