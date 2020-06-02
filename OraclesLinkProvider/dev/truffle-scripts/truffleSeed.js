const OraclesStore = artifacts.require("OraclesStore");
const {
  stringToBytes32,
  setWeb3Instance,
  numberToUint256,
  numberToUint8,
} = require("./utils.js");
const {seedOracles} = require("./seedOracles.js");

module.exports = async (callback) => {
  console.log("start seeding");
  const accounts = await web3.eth.getAccounts();
  const mainAccount = accounts[0];
  const instance = await OraclesStore.deployed();
  setWeb3Instance(web3);

  console.log("initialized");

  await instance.addToWhitelist(mainAccount, {from: mainAccount});
  console.log("added owner To Whitelist");

  const jobType = stringToBytes32("HttpGetInt256");
  console.log("jobType", jobType);

  await instance.addJobType(jobType, {from: mainAccount});
  console.log("added Job Type");


  let index=0;
  while(index < seedOracles.length){
    await instance.proposeStartRound(numberToUint256(Date.now()), {
      from: mainAccount,
    });

    console.log("roundStarted");
  
    // add 5 oracles at a time only in each round to keep transaction gas cost low enough
    for(let i = index; i < index + 5 && i < seedOracles.length; i++){
      let seedOracleWithJob = seedOracles[i];
      await instance.proposeAddOracle(
        seedOracleWithJob.address,
        numberToUint8(seedOracleWithJob.level),
        {from: mainAccount}
      );
      await instance.proposeAddJob(
        seedOracleWithJob.address,
        stringToBytes32(seedOracleWithJob.jobId),
        jobType,
        numberToUint256(web3.utils.toWei(seedOracleWithJob.cost.toString())),
        {from: mainAccount}
      );
      console.log(`oracle and job proposal added for oracle: ${seedOracleWithJob.name}`);
    }
  
    await instance.proposeEndRound(numberToUint256(Date.now()), {
      from: mainAccount,
    });
  
    console.log("round ended");
    index += 5;
  }

  console.log("proposal seeding finished");
  callback();
};
