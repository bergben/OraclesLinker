- Split OraclesLinker into one more pre-deployed contract that is accessed via address -if possible. To minimize the bytecode that the end consumer smart contracts have to deploy everytime. 
- Better seperation of generic functionality and Int256 specific functionality in OraclesLinker
- External Adapter that feeds to OraclesStore
- Link Payment integration
- Example Contract with UI -> weather data? triggered with Chainlink Alarm Clock?
- Cancel Request
- Optimizations
- Add more job types (Api Aggregation, Bool, etc.)
- Random retrieval could be enhanced with Chainlink VRF or Ethereum 2.0 randomness