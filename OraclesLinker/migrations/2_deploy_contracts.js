const SampleContract = artifacts.require("SampleContract");

module.exports = async (deployer) => {
  const randomOraclesProviderAddress =
    "0x4A97750FbD260D9929A6aB0A3c9F4cdbCDa624D0";
  const linkAddress = "0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571";
  await deployer.deploy(
    SampleContract,
    randomOraclesProviderAddress,
    linkAddress
  );
};
