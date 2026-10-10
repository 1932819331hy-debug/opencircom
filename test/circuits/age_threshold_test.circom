pragma circom 2.0.0;

include "../../circuits/comparators.circom";

template AgeThresholdTest() {
    signal input birthYear;
    signal input currentYear;
    signal input minAge;
    signal output valid;

    component p = AgeThresholdProof(16);
    p.birthYear <== birthYear;
    p.currentYear <== currentYear;
    p.minAge <== minAge;
    valid <== p.valid;
}

component main = AgeThresholdTest();
