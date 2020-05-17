let web3Instance;

const stringToBytes32 = (source) => {
  return web3Instance.eth.abi.encodeParameter(
    "bytes32",
    web3Instance.utils.asciiToHex(source)
  );
};

const numberToUint256 = (source) => {
  return web3Instance.eth.abi.encodeParameter("uint256", source.toString());
};

const numberToUint8 = (source) => {
  return web3Instance.eth.abi.encodeParameter("uint8", source.toString());
};

const hexToString = (source) => {
  return web3Instance.utils.hexToAscii(source);
};

const hexToBytes32 = (source) => {
  return stringToBytes32(hexToString(source));
};

const setWeb3Instance = (_web3Instance) => {
  web3Instance = _web3Instance;
};

module.exports = {
  stringToBytes32,
  setWeb3Instance,
  numberToUint256,
  numberToUint8,
  hexToBytes32,
  hexToString,
};
