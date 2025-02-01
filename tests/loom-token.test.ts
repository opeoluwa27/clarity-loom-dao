import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that token transfer works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "loom-token",
        "transfer",
        [types.uint(100), types.principal(wallet_1.address), types.principal(wallet_2.address)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
  }
});
