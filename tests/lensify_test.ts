// [Previous test content]

Clarinet.test({
  name: "Ensure licenses are revoked on copyright transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet1 = accounts.get("wallet_1")!;
    const wallet2 = accounts.get("wallet_2")!;

    let block = chain.mineBlock([
      // Register photo
      Tx.contractCall("lensify", "register-photo", [
        types.utf8("Sample Photo"),
        types.utf8("A beautiful landscape"),
        types.utf8("ipfs://QmPhoto123"),
        types.utf8("CC-BY-4.0")
      ], deployer.address),
      // Grant license
      Tx.contractCall("lensify", "grant-license", [
        types.uint(1),
        types.principal(wallet1.address),
        types.uint(100),
        types.utf8("Commercial usage permitted")
      ], deployer.address),
      // Transfer copyright
      Tx.contractCall("lensify", "transfer-copyright", [
        types.uint(1),
        types.principal(wallet2.address)
      ], deployer.address)
    ]);

    // Check license is no longer valid
    let checkBlock = chain.mineBlock([
      Tx.contractCall("lensify", "check-license-validity", [
        types.uint(1),
        types.principal(wallet1.address)
      ], wallet1.address)
    ]);

    assertEquals(checkBlock.receipts[0].result, types.ok(false));
  },
});

// [Additional test cases for input validation]
