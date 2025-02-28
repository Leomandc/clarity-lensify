import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

[Previous test cases remain unchanged...]

Clarinet.test({
  name: "Ensure can revoke license",
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
      ], deployer.address),
      Tx.contractCall("lensify", "revoke-license", [
        types.uint(1),
        types.principal(wallet1.address)
      ], deployer.address)
    ]);

    assertEquals(block.receipts.length, 3);
    block.receipts[2].result.expectOk();
  },
});

Clarinet.test({
  name: "Ensure expired licenses are detected",
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
        types.uint(3), // Very short expiry
        types.utf8("Commercial usage permitted")
      ], deployer.address)
    ]);

    // Advance chain
    chain.mineEmptyBlock(10);

    let checkBlock = chain.mineBlock([
      Tx.contractCall("lensify", "get-license-details", [
        types.uint(1),
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);

    checkBlock.receipts[0].result.expectErr(105); // err-license-expired
  },
});
