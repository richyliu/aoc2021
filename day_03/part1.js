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

// sum bits for each position
let sum = Array(lines[0].length).fill(0);

for (const line of lines) {
  for (let i = 0; i < line.length; i++) {
    sum[i] += line[i];
  }
}

// find which is most common bit
let gamma = 0;

for (let i = 0; i < sum.length; i++) {
  // only set the bit if it's the most common
  gamma = (gamma << 1) | (sum[i] > lines.length / 2);
}

// epsilon is simply bitwise NOT of gamma
let epsilon = ~gamma & ((1 << sum.length) - 1);

console.log(gamma * epsilon);
