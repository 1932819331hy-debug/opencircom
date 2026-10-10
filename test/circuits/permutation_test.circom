pragma circom 2.0.0;

include "../../circuits/permutation.circom";

template PermutationTest() {
    signal input a[8];
    signal input b[8];
    signal input perm[8];
    signal input sortedIn[8];
    signal output sortedOut;

    component permCheck = IsPermutation(8, 3);
    for (var i = 0; i < 8; i++) {
        permCheck.a[i] <== a[i];
        permCheck.b[i] <== b[i];
        permCheck.perm[i] <== perm[i];
    }

    component sorted = SortedCheck(8, 16);
    for (var i = 0; i < 8; i++) {
        sorted.in[i] <== sortedIn[i];
    }
    sortedOut <== sorted.out;
}

component main = PermutationTest();
