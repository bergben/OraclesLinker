import { Injectable, Inject } from '@angular/core';
import Web3 from 'web3';
import { Contract } from 'web3-eth-contract';
import { WEB3 } from './web3';
import { StoreService } from './store.service';

import contractAbi from '../../../OraclesLinker/build/contracts/FrostInsuranceSampleContract.json';
import { BehaviorSubject } from 'rxjs';
const contractAddress = "0x4ca55A262B7546D90dfF3B194513Edd51862620E";

@Injectable({
    providedIn: 'root'
})
export class FrostInsuranceContractService {
    private frostInsuranceContract: Contract;
    public isConnectedToRopsten$ = new BehaviorSubject<boolean>(false);

    constructor(@Inject(WEB3) private web3: Web3, private store: StoreService) {
    }

    async init() {
        if (await this.web3.eth.net.getNetworkType() !== 'ropsten') {
            return;
        }

        this.isConnectedToRopsten$.next(true);
        this.frostInsuranceContract = new this.web3.eth.Contract(contractAbi.abi as any, contractAddress);
        this.subscribeEventLogs();
    }

    async createInquiry(): Promise<string> {
        if ('enable' in (this.web3.currentProvider as any)) {
            await (this.web3.currentProvider as any).enable();
        }
        const accounts = await this.web3.eth.getAccounts();
        let result = await this.frostInsuranceContract.methods.createInquiry().send({ from: accounts[0] });
        return result as string;
    }

    private async subscribeEventLogs() {
        this.frostInsuranceContract.events.InquiryCreated({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.inquiryCreated$.next(event))
            .on('error', console.error);

        this.frostInsuranceContract.events.OraclesLinkSourceCreated({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.sourceCreated$.next(event))
            .on('error', console.error);

        this.frostInsuranceContract.events.OraclesLinkChainlinkCreated({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.chainlinkCreated$.next(event))
            .on('error', console.error);

        this.frostInsuranceContract.events.ChainlinkAnswerInt256Handled({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.chainlinkFulfilled$.next(event))
            .on('error', console.error);

        this.frostInsuranceContract.events.OraclesLinkSourceAggregated({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.sourceAggregated$.next(event))
            .on('error', console.error);

        this.frostInsuranceContract.events.InquiryFulfilled({}, { fromBlock: 0, toBlock: 'latest' })
            .on('data', event => this.store.inquiryFulfilled$.next(event))
            .on('error', console.error);
    }
}