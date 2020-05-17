const OraclesStore = artifacts.require("OraclesStore");

module.exports = async (callback) => {
  console.log("start seeding");
  const accounts = await web3.eth.getAccounts();
  const mainAccount = accounts[0];
  const instance = await OraclesStore.deployed();

  console.log("initialized");

  await instance.addToWhitelist(mainAccount, {from: mainAccount});
  console.log("added owner To Whitelist");

  const jobType = stringToBytes32("HttpGetInt256");
  console.log("jobType", jobType);

  await instance.addJobType(jobType, {from: mainAccount});
  console.log("added Job Type");

  await instance.proposeStartRound(
    web3.eth.abi.encodeParameter("uint256", Date.now()),
    {from: mainAccount}
  );

  console.log("roundStarted");
  // add senior oracles
  await instance.proposeAddOracle(
    "0x83da1beeb89ffaf56d0b7c50afb0a66fb4df8cb1",
    2,
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0xd8c819674b79c7372d56db03280a5695a9254894",
    2,
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x90eeb07a0ddb176d4c60dec3a146e2289dcb2674",
    2,
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x5471030a14ea46a32f065ac226516723b429ec2b",
    2,
    {from: mainAccount}
  );
  await instance.proposeAddOracle(
    "0x83f00b902cbf06e316c95f51cbeed9d2572a349a",
    2,
    {from: mainAccount}
  );
  console.log("oracle proposals added");

  // add HttpGetInt256 Jobs for each Oracle
  await instance.proposeAddJob(
    "0x83da1beeb89ffaf56d0b7c50afb0a66fb4df8cb1",
    stringToBytes32("2f9cdff5cb5f499bb13061dced947426"),
    jobType,
    web3.eth.abi.encodeParameter("uint256", "100000000000000000"),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0xd8c819674b79c7372d56db03280a5695a9254894",
    stringToBytes32("52d3b29cc024487990a6a029616f13c2"),
    jobType,
    web3.eth.abi.encodeParameter("uint256", "1000000000000000000"),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x90eeb07a0ddb176d4c60dec3a146e2289dcb2674",
    stringToBytes32("86d12771437e42b38c33dad5e2d8412f"),
    jobType,
    web3.eth.abi.encodeParameter("uint256", "100000000000000000"),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x5471030a14ea46a32f065ac226516723b429ec2b",
    stringToBytes32("7e75ce0f80d043dca4993cb419943a54"),
    jobType,
    web3.eth.abi.encodeParameter("uint256", "1000000000000000"),
    {from: mainAccount}
  );
  await instance.proposeAddJob(
    "0x83f00b902cbf06e316c95f51cbeed9d2572a349a",
    stringToBytes32("63a2add7b67a4082aaacfa1b069e3fea"),
    jobType,
    web3.eth.abi.encodeParameter("uint256", "100000000000000000"),
    {from: mainAccount}
  );
  console.log("job proposals added");

  await instance.proposeEndRound(Date.now(), {from: mainAccount});

  console.log("round ended");
  console.log("proposal seeding finished");
  callback();
};

function stringToBytes32(source) {
  return web3.eth.abi.encodeParameter("bytes32", web3.utils.asciiToHex(source));
}
