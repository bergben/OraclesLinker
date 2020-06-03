import { Injectable, Inject } from '@angular/core';
import { WEB3 } from './web3';
import Web3 from 'web3';
import { Contract } from 'web3-eth-contract';

import contractAbi from '../../../OraclesLinker/build/contracts/FrostInsuranceSampleContract.json';
const contractAddress = "0x4ca55A262B7546D90dfF3B194513Edd51862620E";

@Injectable({
    providedIn: 'root'
})
export class FrostInsuranceContractService {
    private frostInsuranceContract: Contract;

    constructor(@Inject(WEB3) private web3: Web3) {
    }

    async init() {
        if (await this.web3.eth.net.getNetworkType() !== 'ropsten') {
            alert('Please connect to the Ropsten network for this showcase');
        }
        this.frostInsuranceContract = new this.web3.eth.Contract(contractAbi.abi as any, contractAddress);
        this.getLogs();
    }

    async getLogs() {
        this.frostInsuranceContract.events.InquiryFulfilled({}, { fromBlock: 0, toBlock: 'latest' }).on(
            'data', (event) => {
                console.log(event);
            }).on('error', console.error);
    }

    async createInquiry() {
        if ('enable' in (this.web3.currentProvider as any)) {
            await (this.web3.currentProvider as any).enable();
        }
        const accounts = await this.web3.eth.getAccounts();
        let result = await this.frostInsuranceContract.methods.createInquiry().send({ from: accounts[0] });
        console.log(result);
    }
}