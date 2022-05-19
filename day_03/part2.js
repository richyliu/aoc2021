#!/usr/bin/env node

const fs = require('fs');

// read input file
const input = fs.readFileSync('input.txt', 'utf8');

// convert each line into array of bits
const lines = input
  .trim()
  .split('\n')
  .map(line =>
    line
      .trim()
      .split('')
      .map(c => (c === '1' ? 1 : 0))
  );

const nBits = lines[0].length;

// find oxygen rating by considering most frequent bit
let oxygen = [...lines];
for (let bit = 0; bit < nBits; bit++) {
  const bitSum = oxygen.reduce((sum, line) => sum + line[bit], 0);
  const filterBit = bitSum >= oxygen.length / 2 ? 1 : 0;
  oxygen = oxygen.filter(line => line[bit] === filterBit);
  if (oxygen.length === 1) {
    break;
  }
}
const oxygenRating = parseInt(oxygen[0].join(''), 2);

// find co2 rating by considering least frequent bit
let co2 = [...lines];
for (let bit = 0; bit < nBits; bit++) {
  const bitSum = co2.reduce((sum, line) => sum + line[bit], 0);
  const filterBit = bitSum < co2.length / 2 ? 1 : 0;
  co2 = co2.filter(line => line[bit] === filterBit);
  if (co2.length === 1) {
    break;
  }
}
const co2Rating = parseInt(co2[0].join(''), 2);

console.log(oxygenRating * co2Rating);
