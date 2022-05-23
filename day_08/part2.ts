const fs = require('fs');

type Segment = string;

// these are the correct LCD segment mappings for an entry
// they map raw LCD segments to the correct segments (and to the correct digit)
class LCDMapping {
  public a: Segment;
  public b: Segment;
  public c: Segment;
  public d: Segment;
  public e: Segment;
  public f: Segment;
  public g: Segment;

  constructor() {
    this.a = this.b = this.c = this.d = this.e = this.f = this.g = ' ';
  }

  toString(): string {
    return `${this.a}${this.b}${this.c}${this.d}${this.e}${this.f}${this.g}`;
  }

  prettyPrint(): string {
    return ` ${this.a.repeat(4)} 
${this.b}    ${this.c}
${this.b}    ${this.c}
 ${this.d.repeat(4)} 
${this.e}    ${this.f}
${this.e}    ${this.f}
 ${this.g.repeat(4)} 
`;
  }

  toDigit(segments: Segment[]): number {
    // digits uniquely identified by number of segments
    if (segments.length == 2) {
      return 1;
    }
    if (segments.length == 3) {
      return 7;
    }
    if (segments.length == 4) {
      return 4;
    }
    if (segments.length == 7) {
      return 8;
    }

    if (segments.length == 5) {
      // must be 2, 3, or 5
      if (segments.includes(this.b)) {
        return 5;
      }
      if (segments.includes(this.e)) {
        return 2;
      }
      return 3;
    }

    if (segments.length == 6) {
      // must be 0, 6, 9
      if (segments.includes(this.d)) {
        // must be 6 or 9
        if (segments.includes(this.e)) {
          return 6;
        }
        return 9;
      }
      return 0;
    }

    throw new Error(`Unknown segments: ${segments}. Mapping: ${this}`);
  }
}

// these are raw LCD segments (might not be matched to correct segments)
class LCD {
  private segments: Segment[];

  constructor(raw: string) {
    this.segments = [];
    for (const c of raw.split('')) {
      if ('a' <= c && c <= 'g') {
        this.segments.push(c);
      } else {
        throw new Error(`Unknown segment character: ${c}`);
      }
    }
  }

  numSegments(): number {
    return this.segments.length;
  }

  has(segment: Segment): boolean {
    return this.segments.includes(segment);
  }

  // find the segments difference between two LCD groups
  sub(other: LCD): Segment[] {
    return this.segments.filter(s => !other.has(s));
  }

  getSegments(): Segment[] {
    return this.segments;
  }

  // Get the segment that appears n times in all the LCDs
  // If there are multiple segments that appear n times, return the first one
  // Ignores segments in ignore
  static countSegments(lcds: LCD[], n: number, ignore: Segment[] = []): Segment {
    const allSegments = lcds.reduce<Segment[]>((acc, lcd) => [...acc, ...lcd.segments], []);
    let count: ({[index: Segment]: number}) = {};
    for (const s of allSegments) {
      if (count[s] == null) {
        count[s] = 0;
      }
      count[s]++;
    }
    for (const s in count) {
      if (count[s] == n && !ignore.includes(s)) {
        return s;
      }
    }
    throw new Error(`Could not find segment with ${n} appearances`);
  }
}

// solve for the 4 output digits of a single entry, given unique segment
// patterns
function solveEntry(digits: LCD[], output: LCD[]): number {
  let mapping = new LCDMapping();
  // digits 1, 4, 7, 8 have unique patterns, so we can identify those immediately
  let digit1, digit4, digit7, digit8;
  for (const digit of digits) {
    if (digit.numSegments() == 2) {
      digit1 = digit;
    } else if (digit.numSegments() == 4) {
      digit4 = digit;
    } else if (digit.numSegments() == 3) {
      digit7 = digit;
    } else if (digit.numSegments() == 7) {
      digit8 = digit;
    }
  }
  if (digit1 === undefined || digit4 === undefined || digit7 === undefined || digit8 === undefined) {
    throw new Error('Could not find all digits');
  }
  // we can easily identify certain segments by subtracting LCD groups
  // 7 - 1 => top segment
  let sub = digit7.sub(digit1);
  if (sub.length != 1) {
    throw new Error('Could not find top segment');
  }
  mapping.a = sub[0];

  // segment e only appears 4 times
  mapping.e = LCD.countSegments(digits, 4);
  
  // segment b only appears 6 times
  mapping.b = LCD.countSegments(digits, 6);

  // for LCDs that have e, only g (excluding e and a) appears 4 times
  mapping.g = LCD.countSegments(digits.filter(d => d.has(mapping.e)), 4, [mapping.e, mapping.a]);

  // for LCDs that have b and g, only c (excluding e) appears 3 times
  mapping.c = LCD.countSegments(digits.filter(d => d.has(mapping.b) && d.has(mapping.g)), 3, [mapping.e]);

  // segment f only appears 9 times
  mapping.f = LCD.countSegments(digits, 9);

  // segment d is the last segment
  const source = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
  const alreadyUsed = [mapping.a, mapping.b, mapping.c, mapping.e, mapping.f, mapping.g];
  const possible = source.filter(s => !alreadyUsed.includes(s));
  if (possible.length !== 1) {
    throw new Error(`Extraneous segments: ${possible}`);
  }
  mapping.d = possible[0];

  // convert digits to number
  let num = 0;
  for (const n of output) {
    num *= 10;
    num += mapping.toDigit(n.getSegments());
  }

  // console.log(mapping.prettyPrint());
  // console.log(num);

  return num;
}

function main() {
  // read input.txt
  const raw = fs.readFileSync('input.txt', 'utf-8');
  const lines = raw.trim().split('\n');

  // we want the sum of the output digits
  let sum = 0;
  for (const line of lines) {
    // each line has raw digits and output digits separated by ' | '
    const [rawDigits, rawOutput] = line.split(' | ');
    // parse each segment group for known digits and output
    const digits = rawDigits.split(' ').map((d: string) => new LCD(d));
    const output = rawOutput.split(' ').map((d: string) => new LCD(d));
    sum += solveEntry(digits, output);
  }
  console.log(sum);
}

main();
