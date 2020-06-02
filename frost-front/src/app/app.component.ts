import { Component, OnInit, Inject } from '@angular/core';
import { WEB3 } from './web3';
import Web3 from 'web3';
import { NestedTreeControl } from '@angular/cdk/tree';
import { MatTreeNestedDataSource } from '@angular/material/tree';

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

  constructor(@Inject(WEB3) private web3: Web3) {
    this.dataSource.data = TREE_DATA;
  }

  ngOnInit() {
  }

  hasChild = (_: number, node: OracleNode) => !!node.children && node.children.length > 0;

  async createInquiry() {
    if ('enable' in (this.web3.currentProvider as any)) {
      await (this.web3.currentProvider as any).enable();
    }
    const accounts = await this.web3.eth.getAccounts();
    console.log(accounts);
  }
}
