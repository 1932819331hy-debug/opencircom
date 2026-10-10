const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const assert = chai.assert;
const BUILD = path.join(__dirname, "..", "build");

const IDENTITY = [0, 1, 2, 3, 4, 5, 6, 7];
const VALUES = [10, 20, 30, 40, 50, 60, 70, 80];

function applyPerm(arr, perm) {
  return perm.map((i) => arr[i]);
}

function baseInput(overrides = {}) {
  return {
    a: VALUES,
    b: VALUES,
    perm: IDENTITY,
    sortedIn: [1, 2, 3, 4, 5, 6, 7, 8],
    ...overrides,
  };
}

describe("IsPermutation / SortedCheck (opencircom)", function () {
  let circuit;
  this.timeout(60000);

  before(async () => {
    circuit = await wasm_tester(path.join(__dirname, "circuits", "permutation_test.circom"), {
      output: BUILD,
      recompile: false,
    });
  });

  it("accepts the identity permutation", async () => {
    const w = await circuit.calculateWitness(baseInput(), true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "1");
  });

  it("accepts a real shuffle", async () => {
    const perm = [3, 0, 7, 1, 6, 2, 5, 4];
    const w = await circuit.calculateWitness(baseInput({ perm, b: applyPerm(VALUES, perm) }), true);
    await circuit.checkConstraints(w);
  });

  it("rejects a swapped pair that is not a permutation of a via perm", async () => {
    let failed = false;
    try {
      const b = [20, 10, 30, 40, 50, 60, 70, 80];
      await circuit.calculateWitness(baseInput({ b, perm: IDENTITY }), true);
    } catch (_) {
      failed = true;
    }
    assert.isTrue(failed);
  });

  it("rejects a duplicate perm index", async () => {
    let failed = false;
    try {
      const perm = [0, 0, 2, 3, 4, 5, 6, 7];
      await circuit.calculateWitness(baseInput({ perm, b: applyPerm(VALUES, perm) }), true);
    } catch (_) {
      failed = true;
    }
    assert.isTrue(failed);
  });

  it("SortedCheck=1 for a non-decreasing array", async () => {
    const w = await circuit.calculateWitness(baseInput({ sortedIn: [1, 2, 2, 4, 5, 6, 7, 9] }), true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "1");
  });

  it("SortedCheck=0 for an unsorted array", async () => {
    const w = await circuit.calculateWitness(baseInput({ sortedIn: [1, 3, 2, 4, 5, 6, 7, 8] }), true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "0");
  });
});
