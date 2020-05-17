const OraclesStore = artifacts.require("OraclesStore");
const RandomOraclesProvider = artifacts.require("RandomOraclesProvider");

module.exports = async (deployer) => {
  await deployer.deploy(OraclesStore);
  const deployedOraclesStore = await OraclesStore.deployed();

  await deployer.deploy(RandomOraclesProvider, deployedOraclesStore.address);
};
