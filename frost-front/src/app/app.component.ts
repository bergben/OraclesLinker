import { Component, OnInit, OnDestroy, NgZone } from '@angular/core';
import { FrostInsuranceContractService } from './frost-insurance-contract.service';
import { StoreService, OraclesLink } from './store.service';
import { Subscription } from 'rxjs';
import { debounceTime } from 'rxjs/operators';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.sass']
})
export class AppComponent implements OnInit, OnDestroy {
  creatingInquiry = false;
  private subscriptions: Subscription[] = [];

  oraclesLinks: OraclesLink[] = [];

  get isConnectedToRopsten$() {
    return this.frostInsuranceContractService.isConnectedToRopsten$;
  }

  constructor(private frostInsuranceContractService: FrostInsuranceContractService, private store: StoreService, private ngZone: NgZone) {
  }

  ngOnInit() {
    this.frostInsuranceContractService.init();
    this.subscriptions.push(this.store.latestOraclesLinks$.pipe(debounceTime(500)).subscribe(oraclesLinks => {
      this.ngZone.run(() => this.oraclesLinks = oraclesLinks);
      console.log(this.oraclesLinks);
    }));
  }

  ngOnDestroy() {
    this.subscriptions.forEach(x => x.unsubscribe());
  }

  async createInquiry() {
    this.creatingInquiry = true;
    await this.frostInsuranceContractService.createInquiry();
    this.creatingInquiry = false;
  }
}
