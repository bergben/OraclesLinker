const FrostInsuranceSampleContract = artifacts.require("FrostInsuranceSampleContract");

module.exports = async (deployer) => {
  const randomOraclesProviderAddress =
    "0x7D8094e6643D4C3E169fD9426AC4c8Cf83042613";
  const ropstenLinkAddress = "0x20fE562d797A42Dcb3399062AE9546cd06f63280";
  await deployer.deploy(
    FrostInsuranceSampleContract,
    randomOraclesProviderAddress,
    ropstenLinkAddress
  );
};
