const SampleContract = artifacts.require("SampleContract");

module.exports = async (deployer) => {
  const randomOraclesProviderAddress =
    "0x474931668F6fbb75A2d4051f3cA156c7CAd8E1cC";
  const linkAddress = "0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571";
  await deployer.deploy(
    SampleContract,
    randomOraclesProviderAddress,
    linkAddress
  );
};
