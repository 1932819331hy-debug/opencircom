const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const assert = chai.assert;
const BUILD = path.join(__dirname, "..", "build");

describe("AgeThresholdProof (opencircom)", function () {
  let circuit;
  this.timeout(60000);

  before(async () => {
    circuit = await wasm_tester(path.join(__dirname, "circuits", "age_threshold_test.circom"), {
      output: BUILD,
      recompile: false,
    });
  });

  it("valid=1 when age equals minAge", async () => {
    const w = await circuit.calculateWitness({ birthYear: 2000, currentYear: 2018, minAge: 18 }, true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "1");
  });

  it("valid=0 when age is minAge-1", async () => {
    const w = await circuit.calculateWitness({ birthYear: 2000, currentYear: 2017, minAge: 18 }, true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "0");
  });

  it("valid=1 when age is above minAge", async () => {
    const w = await circuit.calculateWitness({ birthYear: 1990, currentYear: 2026, minAge: 18 }, true);
    await circuit.checkConstraints(w);
    assert.equal(w[1].toString(), "1");
  });

  it("fails when birthYear is in the future", async () => {
    let failed = false;
    try {
      await circuit.calculateWitness({ birthYear: 2030, currentYear: 2026, minAge: 18 }, true);
    } catch (_) {
      failed = true;
    }
    assert.isTrue(failed);
  });

  it("fails when a year is outside the n-bit range", async () => {
    let failed = false;
    try {
      await circuit.calculateWitness({ birthYear: 1 << 16, currentYear: 2026, minAge: 18 }, true);
    } catch (_) {
      failed = true;
    }
    assert.isTrue(failed);
  });
});
