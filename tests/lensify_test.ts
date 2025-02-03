import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can register new photo",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("lensify", "register-photo", [
        types.utf8("Sample Photo"),
        types.utf8("A beautiful landscape"),
        types.utf8("ipfs://QmPhoto123"),
        types.utf8("CC-BY-4.0")
      ], deployer.address)
    ]);

    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Ensure can transfer copyright",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("lensify", "register-photo", [
        types.utf8("Sample Photo"),
        types.utf8("A beautiful landscape"), 
        types.utf8("ipfs://QmPhoto123"),
        types.utf8("CC-BY-4.0")
      ], deployer.address),
      Tx.contractCall("lensify", "transfer-copyright", [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);

    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk();
  },
});

Clarinet.test({
  name: "Ensure can grant license",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;

    let block = chain.mineBlock([
      Tx.contractCall("lensify", "register-photo", [
        types.utf8("Sample Photo"),
        types.utf8("A beautiful landscape"),
        types.utf8("ipfs://QmPhoto123"), 
        types.utf8("CC-BY-4.0")
      ], deployer.address),
      Tx.contractCall("lensify", "grant-license", [
        types.uint(1),
        types.principal(wallet1.address),
        types.uint(100),
        types.utf8("Commercial usage permitted")
      ], deployer.address)
    ]);

    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk();
  },
});
