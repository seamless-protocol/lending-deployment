import * as fs from 'fs';
import csvParser from 'csv-parser';

const ACTUAL_FILE = 'output_actual_view.csv'
const EXPECTED_FILE = 'output_expected_view.csv'
const OUT_TOTALDIFF_FILE = 'totalDiff.json'

const readCSV = async (filePath: string): Promise<any[]> => {
  return new Promise((resolve, reject) => {
    const results: any[] = [];
    fs.createReadStream(filePath)
      .pipe(csvParser())
      .on('data', (data) => results.push(data))
      .on('end', () => {
        resolve(results);
      })
      .on('error', (error) => {
        reject(error);
      });
  });
};

async function makeDiff() {

  const actualData = await readCSV(ACTUAL_FILE);
  const expectedData = await readCSV(EXPECTED_FILE);

  if (actualData.length != expectedData.length) throw "DATA LENGTH DIFFERENT"

  let totalDiff : any[] = [];
  let indexDiffWhereItShouldnt : any[] = [];

  for(let i=0; i<actualData.length; i++) {
    if (actualData[i].asset != expectedData[i].asset || actualData[i].reward != expectedData[i].reward || actualData[i].user != expectedData[i].user) {
      throw `DATA (user, asset, reward) NOT EQUAL for row ${i}`
    }

    if (actualData[i].userAccrued != expectedData[i].userAccrued || actualData[i].userIndex != expectedData[i].userIndex) {
      totalDiff.push({
        actualData: actualData[i],
        expectedData: expectedData[i]
      })

      if (actualData[i].userAccrued != expectedData[i].userAccrued) {
        // if (expectedData[i].userAccrued > actualData[i].userAccrued) throw "EXPECTED ACCRUED > ACTUAL ACCRUED"

        if (expectedData[i].userIndex != actualData[i].userIndex) {
          indexDiffWhereItShouldnt.push({
            actualData: actualData[i],
            expectedData: expectedData[i]
          })
          
          // throw "BOTH INDEX AND ACCRUED DIFFERENT"
        } 
        
        // todo: add to accruedDiff
      }
    }
  }

  console.log(JSON.stringify(indexDiffWhereItShouldnt, null, 2));

  fs.writeFileSync(OUT_TOTALDIFF_FILE, JSON.stringify(totalDiff, null, 2));
}

makeDiff();