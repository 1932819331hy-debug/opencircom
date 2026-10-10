pragma circom 2.0.0;

include "comparators.circom";
include "gates.circom";
include "muxn.circom";

/**
 * @title SortedCheck
 * @notice Returns 1 if in[] is non-decreasing (in[i] <= in[i+1] for all i).
 * @dev Each element is StrictNum2Bits(nBits). Adjacent pairs use LessEqThan(nBits); results AND together. For n==1, only the range check applies and out=1.
 * @param n Array length (>= 1).
 * @param nBits Bit width of each value (<= 251).
 * @custom:input in[n] Values to check (each in [0, 2^nBits - 1]).
 * @custom:output out 1 if sorted ascending, else 0.
 * @custom:complexity n×StrictNum2Bits(nBits) + (n-1)×LessEqThan(nBits) + MultiAND(n-1). O(n * nBits). Measured: n=8,nBits=16 → 389 constraints; n=32,nBits=16 → 1613 constraints.
 * @custom:security Values must fit nBits; out=0 is a valid witness for an unsorted array (does not hard-fail).
 */
template SortedCheck(n, nBits) {
    assert(n >= 1 && nBits >= 1 && nBits <= 251);
    signal input in[n];
    signal output out;

    component bits[n];
    for (var i = 0; i < n; i++) {
        bits[i] = StrictNum2Bits(nBits);
        bits[i].in <== in[i];
    }

    if (n == 1) {
        out <== 1;
    } else {
        component leq[n - 1];
        component all = MultiAND(n - 1);
        for (var i = 0; i < n - 1; i++) {
            leq[i] = LessEqThan(nBits);
            leq[i].in[0] <== in[i];
            leq[i].in[1] <== in[i + 1];
            all.in[i] <== leq[i].out;
        }
        out <== all.out;
    }
}

/**
 * @title IsPermutation
 * @notice Constrains b[] to be a reordering of a[] via a private index permutation.
 * @dev For each i, b[i] === a[perm[i]]. Each perm[i] is range-checked by SelectByIndex(n, nBits). Pairwise AssertNotEqual on perm[] enforces a bijection (multiset-preserving; duplicate values allowed if they appear in both arrays).
 * @param n Array length (>= 2).
 * @param nBits Bit width for perm indices; must satisfy 2^nBits >= n.
 * @custom:input a[n] Source array (field elements).
 * @custom:input b[n] Claimed permutation of a.
 * @custom:input perm[n] Private indices; must be a permutation of 0..n-1.
 * @custom:complexity n×SelectByIndex(n, nBits) + n(n-1)/2 AssertNotEqual. O(n^2). Measured: n=8,nBits=3 → 308 constraints; n=32,nBits=5 → 4112 constraints.
 * @custom:security perm is private (order not revealed). Invalid or duplicate indices fail constraints. Does not sort; pair with SortedCheck when a sorted image is required.
 */
template IsPermutation(n, nBits) {
    assert(n >= 2 && nBits >= 1);
    signal input a[n];
    signal input b[n];
    signal input perm[n];

    component sel[n];
    for (var i = 0; i < n; i++) {
        sel[i] = SelectByIndex(n, nBits);
        for (var j = 0; j < n; j++) {
            sel[i].inputs[j] <== a[j];
        }
        sel[i].index <== perm[i];
        b[i] === sel[i].out;
    }

    component uniq[n * (n - 1) / 2];
    var k = 0;
    for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
            uniq[k] = AssertNotEqual();
            uniq[k].in[0] <== perm[i];
            uniq[k].in[1] <== perm[j];
            k += 1;
        }
    }
}
