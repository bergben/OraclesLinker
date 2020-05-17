const OraclesStore = artifacts.require("OraclesStore");
const {
  stringToBytes32,
  setWeb3Instance,
  numberToUint256,
  numberToUint8,
} = require("./utils.js");

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

  await instance.proposeStartRound(numberToUint256(Date.now()), {
    from: mainAccount,
  });

  console.log("roundStarted");
  // add senior oracles
  await instance.proposeAddOracle(
    "0x83dA1beEb89Ffaf56d0B7C50aFB0A66Fb4DF8cB1",
    numberToUint8(1),
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0xD8C819674b79C7372d56db03280A5695a9254894",
    numberToUint8(2),
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x90eeb07A0DdB176D4c60deC3a146e2289DCB2674",
    numberToUint8(2),
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x5471030A14ea46A32F065ac226516723B429Ec2B",
    numberToUint8(2),
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x83F00b902cbf06E316C95F51cbEeD9D2572a349a",
    numberToUint8(2),
    {from: mainAccount}
  );
  console.log("oracle proposals added");

  // add HttpGetInt256 Jobs for each Oracle
  await instance.proposeAddJob(
    "0x83dA1beEb89Ffaf56d0B7C50aFB0A66Fb4DF8cB1",
    stringToBytes32("2f9cdff5cb5f499bb13061dced947426"),
    jobType,
    numberToUint256(100000000000000000),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0xD8C819674b79C7372d56db03280A5695a9254894",
    stringToBytes32("52d3b29cc024487990a6a029616f13c2"),
    jobType,
    numberToUint256(1000000000000000000),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x90eeb07A0DdB176D4c60deC3a146e2289DCB2674",
    stringToBytes32("86d12771437e42b38c33dad5e2d8412f"),
    jobType,
    numberToUint256(100000000000000000),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x5471030A14ea46A32F065ac226516723B429Ec2B",
    stringToBytes32("7e75ce0f80d043dca4993cb419943a54"),
    jobType,
    numberToUint256(1000000000000000),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x83F00b902cbf06E316C95F51cbEeD9D2572a349a",
    stringToBytes32("63a2add7b67a4082aaacfa1b069e3fea"),
    jobType,
    numberToUint256(100000000000000000),
    {from: mainAccount}
  );
  console.log("job proposals added");

  // add some more oracles with jobs
  await instance.proposeAddOracle(
    "0x3C2d31ee73BB4458D22E0ED4DE275A30646836A6",
    numberToUint8(2),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x3C2d31ee73BB4458D22E0ED4DE275A30646836A6",
    stringToBytes32("00e3ab1cafb74b718b37c3ea53dc50d6"),
    jobType,
    numberToUint256(1000000000000000000),
    {from: mainAccount}
  );

  await instance.proposeAddOracle(
    "0x7a75A19a120d025F58988347680Fa12b49090b50",
    numberToUint8(2),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x7a75A19a120d025F58988347680Fa12b49090b50",
    stringToBytes32("4908e02d4973488ba1093fe13224bc07"),
    jobType,
    numberToUint256(50000000000000000),
    {from: mainAccount}
  );

  await instance.proposeAddOracle(
    "0xad5B002Df76d5eC3Ac139aF81a3583899078e590",
    numberToUint8(1),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0xad5B002Df76d5eC3Ac139aF81a3583899078e590",
    stringToBytes32("b62e961aa7754a4f9a25595dfca11b03"),
    jobType,
    numberToUint256(1000000000000000000),
    {from: mainAccount}
  );

  await instance.proposeAddOracle(
    "0x9ba2963909acFB23F92535f709163e7686a177EF",
    numberToUint8(1),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x9ba2963909acFB23F92535f709163e7686a177EF",
    stringToBytes32("5d499efd71f54bcca80894ba0172e4f2"),
    jobType,
    numberToUint256(1000000000000000000),
    {from: mainAccount}
  );

  await instance.proposeAddOracle(
    "0x255FEC56e9F96029d76DC7203c2422AbE28B7471",
    numberToUint8(0),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x255FEC56e9F96029d76DC7203c2422AbE28B7471",
    stringToBytes32("ba534c5961594f9389082149992be859"),
    jobType,
    numberToUint256(80000000000000000),
    {from: mainAccount}
  );

  await instance.proposeEndRound(numberToUint256(Date.now()), {
    from: mainAccount,
  });

  console.log("round ended");
  console.log("proposal seeding finished");
  callback();
};
