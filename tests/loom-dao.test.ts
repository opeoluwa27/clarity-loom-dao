import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that proposal creation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "loom-dao",
        "create-proposal",
        [
          types.utf8("Test Proposal"),
          types.utf8("Test Description"),
          types.uint(1000),
          types.uint(100)
        ],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
  }
});
