import * as fs from 'fs';

function simplifyHandleActions(path:string) {
  let json = require(path+'.json');

  let onlyImportant = {
    data: {
      user: json.result.rows.map((a:any) => a.user),
      asset: json.result.rows.map((a:any) => a.asset),
      totalSupply: json.result.rows.map((a:any) => a.totalSupply),
      userBalance: json.result.rows.map((a:any) => a.userBalance),
    }
  }
  fs.writeFileSync(path+'_s.json', JSON.stringify(onlyImportant, null, 2));

  // let onlyImportant = json.result.rows.map((a:any) => { 
  //   return { 
  //     user: a.user, 
  //     asset: a.asset, 
  //     totalSupply: a.totalSupply, 
  //     userBalance: a.userBalance
  //   } 
  // });
  // fs.writeFileSync(path+'_s.json', JSON.stringify({data: onlyImportant}, null, 2));
}

function simplifyClaimAllRewards(json:any) {

}

function simplifyClaimRewards(json:any) {

}

async function simplifyFiles() {
  simplifyHandleActions('../queryResults/handleAction_until_15442183_1');
  simplifyHandleActions('../queryResults/handleAction_until_15442183_2');
  simplifyHandleActions('../queryResults/handleAction_until_15442183_3');

  // simplifyClaimAllRewards(require('../queryResults/claimAllRewards_until_15442183.json'));
  // simplifyClaimRewards(require('../queryResults/claimRewards_until_15442183.json'));

  // let allDistinctUsers = Array.from(allUsers.keys());
  // console.log(allDistinctUsers.length);
  // fs.writeFileSync(OUT_FILE, JSON.stringify(allDistinctUsers, null, 2));
}

simplifyFiles();