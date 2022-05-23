const fs = require('fs');

// read input.txt
const raw = fs.readFileSync('input.txt', 'utf-8');
const lines = raw.trim().split('\n');

// for part 1, we only care about the unique digits (part after ' | ')
let digits = 0;
const uniqueDigitValues = [2, 3, 4, 7];
for (const line of lines) {
  const digitValues = line.split(' | ')[1];
  for (const v of digitValues.split(' ')) {
    if (uniqueDigitValues.includes(v.length)) {
      digits++;
    }
  }
}

console.log(digits);
