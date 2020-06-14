const FrostInsuranceSampleContract = artifacts.require("FrostInsuranceSampleContract");
const {
  numberToUint256,
  setWeb3Instance,
  numberToInt256,
} = require("./utils.js");

module.exports = async (callback) => {
  console.log("start triggering");
  const accounts = await web3.eth.getAccounts();
  const mainAccount = accounts[0];
  const instance = await FrostInsuranceSampleContract.deployed();
  setWeb3Instance(web3);

  console.log("initialized");
  var payment = numberToUint256(web3.utils.toWei("500"));
  console.log("payment", payment);

  var oraclesLink = await instance.createInquiry(payment, {
    from: mainAccount,
  });

  var oraclesLinkId;
  var chainlinkRequests = [];
  let sources = new Map();
  let answersPerSource = new Map();

  console.log("Gas used for request", oraclesLink.receipt.gasUsed);

  oraclesLink.logs.forEach((log) => {
    if (log.event === "OraclesLinkRequested") {
      oraclesLinkId = log.args.id;
    } else if (log.event === "OraclesLinkSourceCreated") {
      chainlinkRequests.push({
        chainlinkRequestId: log.args.chainlinkRequestId,
        sourceResponsesId: log.args.sourceResponsesId,
        sourceUrl: log.args.url,
      });
      if (!sources.has(log.args.sourceResponsesId)) {
        answersPerSource.set(log.args.sourceResponsesId, []);
        sources.set(log.args.sourceResponsesId, {
          id: log.args.sourceResponsesId,
          url: log.args.url,
        });
      }
    } else {
      console.log(log);
    }
  });

  console.log("triggered oracles Link with id", oraclesLinkId);
  console.log("Total chainlinkRequests", chainlinkRequests.length);
  console.log("chainlinkRequests", chainlinkRequests);
  console.log("sources", sources);

  console.log(" --- sending out mock answers for the chainlink requests ---");

  let fulfilledOraclesLinkId;
  let fulfilledOraclesLinkAnswer;

  // first send out non complete, only then finish sources complete with second iteration further down below
  for (let i = 0; i < chainlinkRequests.length - 2; i = i + 3) {
    let req = chainlinkRequests[i];
    let chainlinkRequestId = req.chainlinkRequestId;
    let answer = Math.floor(Math.random() * 10 + 1);
    await instance.fulfillChainlinkInt256(
      chainlinkRequestId,
      numberToInt256(answer),
      {
        from: mainAccount,
      }
    );
    answersPerSource.get(req.sourceResponsesId).push(answer);
    console.log(
      `sent out answer:${answer} for chainlink request id ${chainlinkRequestId} with source responses id ${req.sourceResponsesId} `
    );
  }

  // this iteration fulfilles the oraclesLink
  for (let i = 1; i < chainlinkRequests.length; i++) {
    if (i % 3 == 0) {
      // has already been sent out in for loop up
      continue;
    }
    let req = chainlinkRequests[i];
    let chainlinkRequestId = req.chainlinkRequestId;
    let answer = Math.floor(Math.random() * 10 + 1);
    let result = await instance.fulfillChainlinkInt256(
      chainlinkRequestId,
      numberToInt256(answer),
      {
        from: mainAccount,
      }
    );
    answersPerSource.get(req.sourceResponsesId).push(answer);
    console.log(
      `sent out answer:${answer} for chainlink request id ${chainlinkRequestId} with source responses id ${req.sourceResponsesId} `
    );
    if (result.logs.length > 2) {
      // OraclesLinkFulfilled!
      result.logs.forEach((log) => {
        if (log.event === "OraclesLinkAggregated") {
          fulfilledOraclesLinkId = log.args.oraclesLinkId;
          fulfilledOraclesLinkAnswer = log.args.result.toString();
        }
      });
      i = chainlinkRequests.length;
    }
  }

  console.log("---------------------");
  console.log("OraclesLinkFulfilled!");
  let sourceMedians = [];
  sources.forEach((source) => {
    if (answersPerSource.get(source.id).length) {
      console.log(
        `sent out answers: ${answersPerSource.get(source.id)} for source ${
          source.id
        } with url ${source.url}`
      );
      sourceMedians.push(parseInt(median(answersPerSource.get(source.id))));
      console.log(
        `source median would be ${parseInt(
          median(answersPerSource.get(source.id))
        )}`
      );
    }
  });

  console.log("---------------------");
  console.log("calculated median would be", parseInt(median(sourceMedians)));

  console.log("---------------------");
  console.log(
    `OraclesLink ${fulfilledOraclesLinkId} fulfilled with aggregated answer: ${fulfilledOraclesLinkAnswer}`
  );

  console.log("---------------------");
  console.log("triggering finished");
  callback();
};

function median(values) {
  if (values.length === 0) return 0;

  values.sort(function (a, b) {
    return a - b;
  });

  var half = Math.floor(values.length / 2);

  if (values.length % 2) return values[half];

  return (values[half - 1] + values[half]) / 2.0;
}
