 ## OraclesLink External Adapter
 The OraclesLink External Adapter is used to feed data from market.link to the OraclesStore smart contract.

 - External Adapter Job is Triggered by Chainlink Initiator https://docs.chain.link/docs/initiators (every few hours?)
 - Initiator proposes round start
 - listens to RoundStart event
 - on RoundStart event -> fetch data from market.link api: https://market.link/v1/search/nodes?sortOrder=desc&verified=true&networkId=3&size=1000
 - retrieved data is organized into oracles with a level and the assigned jobs
 - to find the correct job for a certain jobType, the structure of a jobType is defined by its tasks (amount and order)
 - propose adding / removing of jobs and oracles
 - send round propose end


Data from market.link could be extended with data from reputation.link
