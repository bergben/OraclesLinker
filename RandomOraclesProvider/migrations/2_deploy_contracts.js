const RandomOraclesProvider = artifacts.require("RandomOraclesProvider");

module.exports = function (deployer) {
  const oraclesProviderAddress = "0x4e00Ae28Cc4872c7B10a829355a6004BeD1085A6";
  deployer.deploy(RandomOraclesProvider, oraclesProviderAddress);
};
