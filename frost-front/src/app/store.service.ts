import { Injectable } from '@angular/core';
import { distinct } from 'rxjs/operators';
import { Subject, BehaviorSubject } from 'rxjs';

interface OraclesLink {
    id: string;
    triggeredBy: string;
    createTransactionHash: string;
    fulfillTransactionHash?: string;
    result?: number;
}

interface Source {
    id: string;
    oraclesLinkId: string;
    url: string;
    transactionHash?: string;
    result?: number;
}

interface ChainlinkRequest {
    id: string;
}

@Injectable({
    providedIn: 'root'
})
export class StoreService {
    oraclesLinks: Map<string, OraclesLink> = new Map<string, OraclesLink>();
    oraclesLinkToSourceIds: Map<string, Set<string>> = new Map<string, Set<string>>();
    sources: Map<string, Source> = new Map<string, Source>();


    inquiryFulfilled$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, answer: string }, transactionHash: string }>();
    inquiryCreated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, triggeredBy: string }, transactionHash: string }>();

    sourceCreated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, sourceResponsesId: string, url: string } }>();
    sourceAggregated$ = new Subject<{ id: string, returnValues: { oraclesLinkId: string, sourceResponsesId: string, result: string }, transactionHash: string }>();

    constructor() {
        this.subscribeEvents();
    }

    private subscribeEvents() {
        this.inquiryCreated$.pipe(distinct(e => e.id)).subscribe(event => {
            this.onInquiryCreated(event.returnValues.oraclesLinkId, event.returnValues.triggeredBy, event.transactionHash);
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
    }



    private onInquiryCreated(oraclesLinkId: string, triggeredBy: string, transactionHash: string) {
        this.oraclesLinks.set(oraclesLinkId, {
            ...this.oraclesLinks.get(oraclesLinkId),
            id: oraclesLinkId,
            triggeredBy,
            createTransactionHash: transactionHash
        });
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
    }

    private onSourceAggregated(oraclesLinkId: string, sourceId: string, result: string, transactionHash: string) {
        this.sources.set(sourceId, {
            ...this.sources.get(sourceId),
            id: sourceId,
            oraclesLinkId,
            transactionHash,
            result: this.answerToFloat(result)
        });

        console.log("sourceAggregated", this.sources);
        console.log("oraclesLinkToSourceIds", this.oraclesLinkToSourceIds);
    }

    private onInquiryFulfilled(oraclesLinkId: string, answer: string, transactionHash: string) {
        this.oraclesLinks.set(oraclesLinkId, {
            ...this.oraclesLinks.get(oraclesLinkId),
            id: oraclesLinkId,
            result: this.answerToFloat(answer),
            fulfillTransactionHash: transactionHash
        });

        console.log("fulfilled", this.oraclesLinks);
    }

    private answerToFloat(answer: string): number {
        answer = answer.slice(0, -2) + "." + answer.slice(-2);
        return parseFloat(answer);
    }
}