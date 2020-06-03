import { Component, OnInit } from '@angular/core';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeNestedDataSource } from '@angular/material/tree';
import { FrostInsuranceContractService } from './frost-insurance-contract.service';

interface OracleNode {
  name: string;
  children?: SourceNode[];
}

interface SourceNode {
  name: string;
  children?: any[];
}

const TREE_DATA: OracleNode[] = [
  {
    name: 'Fruit',
    children: [
      { name: 'Apple' },
      { name: 'Banana' },
      { name: 'Fruit loops' },
    ]
  }, {
    name: 'Vegetables',
    children: [
      {
        name: 'Green',
        children: [
          { name: 'Broccoli' },
          { name: 'Brussels sprouts' },
        ]
      }, {
        name: 'Orange',
        children: [
          { name: 'Pumpkins' },
          { name: 'Carrots' },
        ]
      },
    ]
  },
];

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.sass']
})
export class AppComponent implements OnInit {
  treeControl = new NestedTreeControl<OracleNode>(node => node.children);
  dataSource = new MatTreeNestedDataSource<OracleNode>();
  creatingInquiry = false;

  constructor(private frostInsuranceContractService: FrostInsuranceContractService) {
    this.dataSource.data = TREE_DATA;
  }

  ngOnInit() {
    this.frostInsuranceContractService.init();
  }

  hasChild = (_: number, node: OracleNode) => !!node.children && node.children.length > 0;

  async createInquiry() {
    this.creatingInquiry = true;
    await this.frostInsuranceContractService.createInquiry();
    this.creatingInquiry = false;
  }
}
