import { BigNumberish, BytesLike, ethers } from "ethers";
import RewardsControllerABI from "./abi.json"
import SafeApiKit from '@safe-global/api-kit'
import Safe from '@safe-global/protocol-kit'
import {
  MetaTransactionData,
  OperationType
} from '@safe-global/safe-core-sdk-types'
import * as fs from 'fs';
import * as dotenv from 'dotenv';

dotenv.config();

const config = process.env;

interface DataObject {
    user: string;
    asset: string;
    reward: string;
    indexToSet: string;
    accruedToSet: string;
    currentAccrued: string;
    accruedToDeduct: string;
}

interface ConvertedData {
    users: string[];
    assets: string[];
    rewards: string[];
    indexesToSet: string[];
    accruedsToSet: string[];
}

interface BatchedData {
    userBatches: string[][];
    assetBatches: string[][];
    rewardBatches: string[][];
    indexToSetBatches: string[][];
    accruedToSetBatches: string[][];
}

const REWARDS_CONTROLLER_PROXY: string = '0x91Ac2FfF8CBeF5859eAA6DdA661feBd533cD3780';
const CHAIN_ID: bigint = BigInt(8453);
const BASE_RPC_URL = config.BASE_RPC_URL!;
const DELEGATE_ADDRESS = config.DELEGATE_ADDRESS!;
const DELEGATE_PK = config.DELEGATE_PK;
const SAFE_WALLET = config.SAFE_WALLET!;

async function encodeSetUserData(
    assets: string[], 
    rewards: string[], 
    users: string[], 
    indexes: BigNumberish[], 
    accruedAmounts: BigNumberish[]
): Promise<string>  {
    const rewardsControllerInterface = new ethers.Interface(RewardsControllerABI);
    
    const processedAssets = assets.map(asset => ethers.getAddress(asset));
    const processedRewards = rewards.map(reward => ethers.getAddress(reward));
    const processedUsers = users.map(user => ethers.getAddress(user));
    
    return rewardsControllerInterface.encodeFunctionData(
        'setUserData',
        [
            processedAssets,
            processedRewards,
            processedUsers,
            indexes,
            accruedAmounts
        ]
    );
}

function convertEntriesToArrays(jsonData: DataObject[]): ConvertedData {
    const convertedData: ConvertedData = {
        users: [],
        assets: [],
        rewards: [],
        indexesToSet: [],
        accruedsToSet: []
    };

    for (const obj of jsonData) {
        convertedData.users.push(obj.user);
        convertedData.assets.push(obj.asset);
        convertedData.rewards.push(obj.reward);
        convertedData.indexesToSet.push(obj.indexToSet);
        convertedData.accruedsToSet.push(obj.accruedToSet);
    }

    return convertedData;
}

function batchArray<T>(arr: T[], batchSize: number): T[][] {
    const batchedArray: T[][] = [];
    for (let i = 0; i < arr.length; i += batchSize) {
        batchedArray.push(arr.slice(i, i + batchSize));
    }
    return batchedArray;
}

async function createSafeTxs2(filePath: string, batchSize: number): Promise<void> {
    let batchedData: BatchedData;

    try {
        const data = fs.readFileSync(filePath, 'utf8');
        const jsonData: DataObject[] = JSON.parse(data);
    
        const convertedData = convertEntriesToArrays(jsonData);
    
        const batchSize = 500;
    
        batchedData = {
            userBatches: batchArray(convertedData.users, batchSize),
            assetBatches: batchArray(convertedData.assets, batchSize),
            rewardBatches: batchArray(convertedData.rewards, batchSize),
            indexToSetBatches: batchArray(convertedData.indexesToSet, batchSize),
            accruedToSetBatches: batchArray(convertedData.accruedsToSet, batchSize)
        };    
    } catch (err) {
        console.error('Error reading, parsing or batchind datam from, the file:', err);
        throw err;
    }

    try { 
        const apiKit = new SafeApiKit({
            chainId: CHAIN_ID
          });
        
        /// alternatively if we want to define custom txServiceUrl to test
        //   const apiKit = new SafeApiKit({
        //     chainId: 1n, // set the correct chainId
        //     txServiceUrl: 'https://url-to-your-custom-service'
        //   })

        const protocolKitDelegate = await Safe.init({
            provider: BASE_RPC_URL,
            signer: DELEGATE_PK,
            safeAddress: SAFE_WALLET
          });

        for (let i = 0; i < batchedData.userBatches.length; i++) {
             const encodedSetUserData = await encodeSetUserData(
                batchedData.assetBatches[i],
                batchedData.rewardBatches[i],
                batchedData.userBatches[i],
                batchedData.indexToSetBatches[i],
                batchedData.accruedToSetBatches[i]
            );

            console.log(`Encoded data for batch ${i + 1}: ${encodedSetUserData}`);

            // const safeTransactionData: MetaTransactionData = {
            //     to: REWARDS_CONTROLLER_PROXY,
            //     value: '0', 
            //     data: encodedSetUserData,
            //     operation: OperationType.Call
            //   }

            //   console.log(`Safe tx data for batch ${i + 1}: ${safeTransactionData}`)
              
            //   // single tx
            //   const safeTransaction = await protocolKitDelegate.createTransaction({
            //     transactions: [safeTransactionData]
            //   });
              
            //   const safeTxHash = await protocolKitDelegate.getTransactionHash(safeTransaction)
            //   const signature = await protocolKitDelegate.signHash(safeTxHash)
              
            //   // Propose transaction to the service
            //   await apiKit.proposeTransaction({
            //     safeAddress: SAFE_WALLET,
            //     safeTransactionData: safeTransaction.data,
            //     safeTxHash,
            //     senderAddress: DELEGATE_ADDRESS,
            //     senderSignature: signature.data
            //   });
        }
    } catch (err) {
        console.error('Error occurred whilst proposing transaction to Safe{Wallet}.');
        throw (err);
    }
}

// interface RawUserDataRow {
//     asset: string;
//     reward: string;
//     user: number;
//     index: BigNumberish;
//     accruedAmount: BigNumberish;d
// }

// async function createSafeTxs(filePath: string, numRows: number): Promise<void> {
//     // separate these completely
//     const safeMetaTransactions: MetaTransactionData[] = [];

//     // Read CSV data
//     const data: RawUserDataRow[] = await new Promise((resolve, reject) => {
//         const dataArray: RawUserDataRow[] = [];
//         fs.createReadStream(filePath)
//             .pipe(csvParser())
//             .on('data', (row: RawUserDataRow) => {
//                 dataArray.push(row);
//             })
//             .on('end', () => {
//                 console.log('CSV file successfully processed.');
//                 resolve(dataArray);
//             })
//             .on('error', (error) => {
//                 console.error('There was an error with processing the CSV file.');
//                 reject(error);
//             });
//     });

//     // Batch data into arrays of numRows
//     const batches: RawUserDataRow[][] = [];
//     if (data.length <= numRows) {
//         // If total rows are less than or equal to numRows, process all data in a single batch
//         batches.push(data);
//     } else {
//         // Otherwise, batch the data into arrays of numRows
//         let i = 0;
//         while (i < data.length) {
//             const remainingRows = data.length - i;
//             const batchSize = Math.min(numRows, remainingRows);
//             batches.push(data.slice(i, i + batchSize));
//             i += batchSize;
//         }
//     }

//     // Process each batch
//     for (const batch of batches) {
//         const columns: Record<string, any[]> = {};
//         for (const column of Object.keys(batch[0])) {
//             columns[column] = batch.map(row => row[column]);
//         }

//         // Encode and make transactions for the batch
//         const encodedSetUserData: string = await encodeSetUserData(
//             columns['asset'],
//             columns['reward'],
//             columns['user'],
//             columns['index'],
//             columns['accruedAmount']
//         );

//         const safeTransactionData: MetaTransactionData = {
//             to: REWARDS_CONTROLLER_PROXY,
//             value: '0',
//             data: encodedSetUserData,
//             operation: OperationType.Call
//         };
        

//         try {
//             // propose transaction
//         } catch (err) {
//             console.error('An error occurred when attempting to propose transactions.');
//             throw err;
//         }
//     }

//     console.log('safeSigner: ', config.SAFE_SIGNER_ADDRESS);
//     console.log('safeAddress: ', config.SAFE_ADDRESS);
//     try {
//         console.log('safeTransaction: ', safeMetaTransactions);

//         // console.log('before Safe init');
//         // const protocolKitOwnerA = await Safe.init({
//         //     provider: 'https://base-sepolia.g.alchemy.com/v2/yzI_2ZiJys3q0SyaZVNcBUQTx5RfreMd',
//         //     signer: '',
//         //     safeAddress: config.SAFE_ADDRESS
//         // });
        
//         // console.log('after safe init');
//         // console.log(safeMetaTransactions);
//         // const safeTransaction = await protocolKitOwnerA.createTransaction({
//         //     transactions: safeMetaTransactions
//         // });

//         // const txResponse = await protocolKitOwnerA.executeTransaction(safeTransaction)
        
//         // console.log('Safe transaction created:', safeTransaction);
//     } catch (error) {
//         console.error('Error creating safe transaction:', error);
//     }
// }


const filePath = './ourData.json'; 
const batchSize = 2;
createSafeTxs2(filePath, batchSize)
    .then(() => {
        console.log('JSON data processed successfully.');
    })
    .catch(error => {
        console.error('Error in creating SafeTxs:', error);
        throw error;
    });