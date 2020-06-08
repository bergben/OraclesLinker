import { Injectable, Inject } from '@angular/core';
import { distinct } from 'rxjs/operators';
import { Subject } from 'rxjs';
import Web3 from 'web3';
import { WEB3 } from './web3';

export interface OraclesLink {
    id: string;
    triggeredBy: string;
    createTransactionHash: string;
    blockNumber: number;
    fulfillTransactionHash?: string;
    result?: number;
    sources?: Source[];
}

export interface Source {
    id: string;
    oraclesLinkId: string;
    url: string;
    transactionHash?: string;
    result?: number;
    chainlinkRequests?: ChainlinkRequest[];
}

export interface ChainlinkRequest {
    id: string;
    oraclesLinkId: string;
    sourceId: string;
    oracleAddress: string;
    jobId: string;
    cost: number;
    result?: number;
    transactionHash?: string;
}

@Injectable({
    providedIn: 'root'
})
export class StoreService {
    private oraclesLinks: Map<string, OraclesLink> = new Map<string, OraclesLink>();
    private oraclesLinkToSourceIds: Map<string, Set<string>> = new Map<string, Set<string>>();
    private sources: Map<string, Source> = new Map<string, Source>();
    private sourceIdToChainlinkRequestIds: Map<string, Set<string>> = new Map<string, Set<string>>();
    private chainlinkRequests: Map<string, ChainlinkRequest> = new Map<string, ChainlinkRequest>();


    inquiryFulfilled$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, answer: string }, transactionHash: string }>();
    inquiryCreated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, triggeredBy: string }, transactionHash: string, blockNumber: number }>();

    sourceCreated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, sourceResponsesId: string, url: string } }>();
    sourceAggregated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, sourceResponsesId: string, result: string }, transactionHash: string }>();

    chainlinkCreated$ = new Subject<{
        id: string, returnValues: {
            oraclesLinkId: string, sourceResponsesId: string, chainlinkRequestId: string, oracleAddress: string, jobId: string, cost: string
        }
    }>();
    chainlinkFulfilled$ = new Subject<{
        id: string, returnValues: {
            oraclesLinkId: string, sourceResponsesId: string, chainlinkRequestId: string, answer: string
        }, transactionHash: string
    }>();

    private latestOraclesLinks$$ = new Subject<OraclesLink[]>();


    public get latestOraclesLinks$() {
        return this.latestOraclesLinks$$.asObservable();
    }

    constructor(@Inject(WEB3) private web3: Web3) {
        this.subscribeEvents();
    }

    private updateLatestOraclesLinks() {
        const oraclesLinks = [...this.oraclesLinks.values()].sort((x, y) => x.blockNumber - y.blockNumber);
        // get latest 5

        oraclesLinks?.forEach(oraclesLink => {
            oraclesLink.sources = this.getOraclesLinkSources(oraclesLink.id);
            oraclesLink.sources?.forEach(source => {
                source.chainlinkRequests = this.getSourceChainlinkRequests(source.id);
            });
        });
        this.latestOraclesLinks$$.next(oraclesLinks);
    }

    private getOraclesLinkSources(oraclesLinkId: string) {
        const sources: Source[] = [];
        this.oraclesLinkToSourceIds.get(oraclesLinkId)?.forEach(sourceId => {
            sources.push(this.sources.get(sourceId));
        });
        return sources;
    }

    private getSourceChainlinkRequests(sourceId: string) {
        const chainlinkRequests: ChainlinkRequest[] = [];
        this.sourceIdToChainlinkRequestIds.get(sourceId)?.forEach(chainlinkRequestId => {
            chainlinkRequests.push(this.chainlinkRequests.get(chainlinkRequestId));
        });
        return chainlinkRequests;
    }

    private subscribeEvents() {
        this.inquiryCreated$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onInquiryCreated(event.returnValues.oraclesLinkId, event.returnValues.triggeredBy, event.transactionHash, event.blockNumber);
        });
        this.inquiryFulfilled$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onInquiryFulfilled(event.returnValues.oraclesLinkId, event.returnValues.answer, event.transactionHash);
        });


        this.sourceCreated$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onSourceCreated(event.returnValues.oraclesLinkId, event.returnValues.sourceResponsesId, event.returnValues.url);
        });
        this.sourceAggregated$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onSourceAggregated(event.returnValues.oraclesLinkId, event.returnValues.sourceResponsesId, event.returnValues.result, event.transactionHash);
        });


        this.chainlinkCreated$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onChainlinkCreated(event.returnValues.oraclesLinkId,
                event.returnValues.sourceResponsesId,
                event.returnValues.chainlinkRequestId,
                event.returnValues.oracleAddress,
                event.returnValues.jobId,
                event.returnValues.cost);
        });
        this.chainlinkFulfilled$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onChainlinkFulfilled(
                event.returnValues.oraclesLinkId,
                event.returnValues.sourceResponsesId,
                event.returnValues.chainlinkRequestId,
                event.returnValues.answer,
                event.transactionHash);
        });
    }

    private onChainlinkCreated(oraclesLinkId: string, sourceId: string, chainlinkRequestId: string, oracleAddress: string, jobId: string, cost: string) {
        this.chainlinkRequests.set(chainlinkRequestId, {
            ...this.sources.get(chainlinkRequestId),
            id: chainlinkRequestId,
            oraclesLinkId,
            sourceId,
            oracleAddress,
            jobId,
            cost: parseFloat(this.web3.utils.fromWei(cost)),
        });

        if (!this.sourceIdToChainlinkRequestIds.has(sourceId)) {
            this.sourceIdToChainlinkRequestIds.set(sourceId, new Set<string>());
        }
        this.sourceIdToChainlinkRequestIds.get(sourceId).add(chainlinkRequestId);
        this.updateLatestOraclesLinks();
    }

    private onChainlinkFulfilled(oraclesLinkId: string, sourceId: string, chainlinkRequestId: string, answer: string, transactionHash: string) {
        this.chainlinkRequests.set(chainlinkRequestId, {
            ...this.chainlinkRequests.get(chainlinkRequestId),
            id: chainlinkRequestId,
            oraclesLinkId,
            sourceId,
            transactionHash,
            result: this.answerToFloat(answer)
        });

        console.debug("onChainlinkFulfilled", this.chainlinkRequests);
        console.debug("sourceIdToChainlinkRequestIds", this.sourceIdToChainlinkRequestIds);
        this.updateLatestOraclesLinks();
    }


    private onInquiryCreated(oraclesLinkId: string, triggeredBy: string, transactionHash: string, blockNumber: number) {
        this.oraclesLinks.set(oraclesLinkId, {
            ...this.oraclesLinks.get(oraclesLinkId),
            id: oraclesLinkId,
            blockNumber,
            triggeredBy,
            createTransactionHash: transactionHash
        });
        this.updateLatestOraclesLinks();
    }

    private onSourceCreated(oraclesLinkId: string, sourceId: string, url: string) {
        this.sources.set(sourceId, {
            ...this.sources.get(sourceId),
            id: sourceId,
            oraclesLinkId,
            url,
        });

        if (!this.oraclesLinkToSourceIds.has(oraclesLinkId)) {
            this.oraclesLinkToSourceIds.set(oraclesLinkId, new Set<string>());
        }
        this.oraclesLinkToSourceIds.get(oraclesLinkId).add(sourceId);
        this.updateLatestOraclesLinks();
    }

    private onSourceAggregated(oraclesLinkId: string, sourceId: string, result: string, transactionHash: string) {
        this.sources.set(sourceId, {
            ...this.sources.get(sourceId),
            id: sourceId,
            oraclesLinkId,
            transactionHash,
            result: this.answerToFloat(result)
        });

        console.debug("sourceAggregated", this.sources);
        console.debug("oraclesLinkToSourceIds", this.oraclesLinkToSourceIds);
        this.updateLatestOraclesLinks();
    }

    private onInquiryFulfilled(oraclesLinkId: string, answer: string, transactionHash: string) {
        this.oraclesLinks.set(oraclesLinkId, {
            ...this.oraclesLinks.get(oraclesLinkId),
            id: oraclesLinkId,
            result: this.answerToFloat(answer),
            fulfillTransactionHash: transactionHash
        });

        console.debug("Inquiry fulfilled", this.oraclesLinks);
        this.updateLatestOraclesLinks();
    }

    private answerToFloat(answer: string): number {
        answer = answer.slice(0, -2) + "." + answer.slice(-2);
        return parseFloat(answer);
    }
}