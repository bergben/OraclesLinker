const OraclesStore = artifacts.require("OraclesStore");

module.exports = function (deployer) {
  deployer.deploy(OraclesStore);
};
