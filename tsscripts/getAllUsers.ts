import * as fs from 'fs';

const OUT_FILE = '../queryResults/distinctUsers.json'

let allUsers : Map<string, boolean> = new Map<string, boolean>();

function parseHandleActions(json:any) {
  let rows = json.result.rows;
  for(let i=0; i<rows.length; i++) {
    let user = rows[i].user as string;
    allUsers.set(user, true);
  }
}

function parseClaims(json:any) {
  let rows = json.result.rows;
  for(let i=0; i<rows.length; i++) {
    let user = rows[i].call_tx_from as string;
    allUsers.set(user, true);
  }
}

async function getAllUsers() {
  parseHandleActions(require('../queryResults/handleAction_until_15442183_1.json'));
  parseHandleActions(require('../queryResults/handleAction_until_15442183_2.json'));
  parseHandleActions(require('../queryResults/handleAction_until_15442183_3.json'));

  parseClaims(require('../queryResults/claimAllRewards_until_15442183.json'));
  parseClaims(require('../queryResults/claimRewards_until_15442183.json'));

  let allDistinctUsers = Array.from(allUsers.keys());
  console.log(allDistinctUsers.length);
  fs.writeFileSync(OUT_FILE, JSON.stringify(allDistinctUsers, null, 2));
}

getAllUsers();