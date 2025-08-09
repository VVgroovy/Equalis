import { keccak256, toUtf8Bytes } from "ethers";

// Minimal helper to build leaves keccak256(abi.encode(account, amount))
export function leaf(account: string, amount: bigint) {
  const encoded = new Uint8Array([
    ...toUtf8Bytes(account.toLowerCase()),
    ...toUtf8Bytes(amount.toString())
  ]);
  return keccak256(encoded);
}


