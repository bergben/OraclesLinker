const RandomOraclesProvider = artifacts.require("RandomOraclesProvider");
const {
  stringToBytes32,
  setWeb3Instance,
  numberToUint256,
  numberToUint8,
  hexToBytes32,
  hexToString,
} = require("./utils.js");

module.exports = async (callback) => {
  console.log("start retrieval");
  const accounts = await web3.eth.getAccounts();
  const mainAccount = accounts[2];
  const instance = await RandomOraclesProvider.deployed();
  setWeb3Instance(web3);

  console.log("initialized");

  const jobType = stringToBytes32("HttpGetInt256");

  console.log("-------------------- Senior -------------------");

  var randiomSeniorIndicesMainAccount = await instance.getRandomSeniorIndices.call(
    numberToUint8(2),
    jobType,
    hexToBytes32(mainAccount)
  );
  console.log(
    "Random Senior Oracles with some account",
    randiomSeniorIndicesMainAccount.map((x) => x.toString())
  );

  var randiomSeniorIndicesDifferentAccount = await instance.getRandomSeniorIndices.call(
    numberToUint8(2),
    jobType,
    hexToBytes32(accounts[3])
  );
  console.log(
    "Random Senior Oracles with a different account",
    randiomSeniorIndicesDifferentAccount.map((x) => x.toString())
  );

  await Promise.all(
    randiomSeniorIndicesMainAccount.map(async (randomIndex) => {
      var getSeniorOracleWithJob = await instance.getSeniorOracleWithJob.call(
        numberToUint256(parseInt(randomIndex.toString())),
        jobType
      );
      console.log(
        `Random Senior Oracle at index ${randomIndex.toString()}: address=${
          getSeniorOracleWithJob[0]
        },  jobId=${hexToString(
          getSeniorOracleWithJob[1]
        )},  cost=${web3.utils.fromWei(getSeniorOracleWithJob[2].toString())}`
      );
    })
  );

  console.log("-------------------- MATURE -------------------");

  var randiomMatureIndices = await instance.getRandomMatureIndices.call(
    numberToUint8(1),
    jobType,
    hexToBytes32(mainAccount)
  );
  console.log(
    "Random Mature Oracle Index",
    randiomMatureIndices.map((x) => x.toString())
  );

  await Promise.all(
    randiomMatureIndices.map(async (randomIndex) => {
      var getMatureOracleWithJob = await instance.getMatureOracleWithJob.call(
        numberToUint256(parseInt(randomIndex.toString())),
        jobType
      );
      console.log(
        `Random Mature Oracle at index ${randomIndex.toString()}: address=${
          getMatureOracleWithJob[0]
        },  jobId=${hexToString(
          getMatureOracleWithJob[1]
        )},  cost=${web3.utils.fromWei(getMatureOracleWithJob[2].toString())}`
      );
    })
  );

  console.log("random retrieval finished");
  callback();
};
