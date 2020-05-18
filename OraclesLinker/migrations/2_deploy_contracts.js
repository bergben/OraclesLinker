const SampleContract = artifacts.require("SampleContract");

module.exports = async (deployer) => {
  const randomOraclesProviderAddress =
    "0x95285B64017453B77fE92c6D75b8dfb509D9756d";
  const linkAddress = "0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571";
  await deployer.deploy(
    SampleContract,
    randomOraclesProviderAddress,
    linkAddress
  );
};
