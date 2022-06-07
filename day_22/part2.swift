#!/usr/bin/env swift

import Foundation

/// Ranges are used to specify a range of values. They include start but not
/// end.
struct IntRange {
    let start: Int
    let end: Int

    init(start: Int, end: Int) {
        if start >= end {
            fatalError("Range start must be less than end")
        }
        self.start = start
        self.end = end
    }

    var size: Int {
        return end - start
    }

    func intersect(with range: IntRange) -> IntRange? {
        let start = max(self.start, range.start)
        let end = min(self.end, range.end)

        if start < end {
            return IntRange(start: start, end: end)
        } else {
            return nil
        }
    }

    func intersects(with range: IntRange) -> Bool {
        return self.start < range.end && self.end > range.start
    }

    /// Returns the 0, 1, or 2 ranges resulting from this - other. That is, the
    /// parts of this that are not in other.
    func subtract(by range: IntRange) -> [IntRange] {
        var result: [IntRange] = []
        if range.intersects(with: self) {
            if self.start < range.start {
                result.append(IntRange(start: self.start, end: range.start))
            }
            if range.end < self.end {
                result.append(IntRange(start: range.end, end: self.end))
            }
        }
        return result
    }
}

struct Cuboid {
    let x: IntRange
    let y: IntRange
    let z: IntRange

    init(x: IntRange, y: IntRange, z: IntRange) {
        self.x = x
        self.y = y
        self.z = z
    }

    /// Subtracts the given cuboid from this one. Returns a list of cuboids that
    /// are the result of the subtraction (since this cuboid may be split into
    /// multiple cuboids).
    ///
    /// - Parameter other: The cuboid to subtract from this one.
    /// - Returns: A list of cuboids that are the result of the subtraction.
    func subtract(other: Cuboid) -> [Cuboid] {
        // There are 3 types of cuboids that can result from this subtraction:
        // 1. Up to two cuboids in the x direction, occupying the full y and z
        //    ranges.
        // 2. Up to two cuboids in the y direction, occupying the x range of the
        //    intersection between the other cuboid and this one, and the full z
        //    range.
        // 3. Up to two cuboids in the z direction, occupying the x and y ranges
        //    of the intersection between the other cuboid and this one.

        // if x, y, and z don't intersect, then the cuboid is unchanged.
        if !self.x.intersects(with: other.x) ||
            !self.y.intersects(with: other.y) ||
            !self.z.intersects(with: other.z) {
            return [self]
        }

        var result: [Cuboid] = []

        // 1. x direction cuboids
        let xRanges = self.x.subtract(by: other.x)
        for xRange in xRanges {
            result.append(Cuboid(x: xRange, y: self.y, z: self.z))
        }

        // 2. y direction cuboids
        let yRange = self.y.subtract(by: other.y)
        for yRange in yRange {
            // we know x range must intersect
            let xRange = self.x.intersect(with: other.x)!
            result.append(Cuboid(x: xRange, y: yRange, z: self.z))
        }

        // 3. z direction cuboids
        let zRange = self.z.subtract(by: other.z)
        for zRange in zRange {
            // we know x and y ranges must intersect
            let xRange = self.x.intersect(with: other.x)!
            let yRange = self.y.intersect(with: other.y)!
            result.append(Cuboid(x: xRange, y: yRange, z: zRange))
        }

        return result
    }

    var volume: Int {
        return x.size * y.size * z.size
    }
}

struct Action {
    let on: Bool
    let region: Cuboid

    init(isOn: Bool, region: Cuboid) {
        self.on = isOn
        self.region = region
    }

    func apply(to cuboids: [Cuboid]) -> [Cuboid] {
        var newCuboids = cuboids.flatMap { $0.subtract(other: region) }
        if on {
            newCuboids.append(region)
        }
        return newCuboids
    }
}

// read the input file
let input = try String(contentsOfFile: "input.txt")
let lines = input.components(separatedBy: "\n")
var actions: [Action] = []
for line in lines {
    let regex = try! NSRegularExpression(pattern: #"(on|off) x=([-0-9]+)\.\.([-0-9]+),y=([-0-9]+)\.\.([-0-9]+),z=([-0-9]+)\.\.([-0-9]+)"#)
    let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))

    if let match = matches.first {
        let on = line[Range(match.range(at: 1), in: line)!] == "on"

        let xStart = Int(line[Range(match.range(at: 2), in: line)!])!
        let xEnd = Int(line[Range(match.range(at: 3), in: line)!])! + 1
        let yStart = Int(line[Range(match.range(at: 4), in: line)!])!
        let yEnd = Int(line[Range(match.range(at: 5), in: line)!])! + 1
        let zStart = Int(line[Range(match.range(at: 6), in: line)!])!
        let zEnd = Int(line[Range(match.range(at: 7), in: line)!])! + 1

        let region = Cuboid(x: IntRange(start: xStart, end: xEnd), y: IntRange(start: yStart, end: yEnd), z: IntRange(start: zStart, end: zEnd))
        let action = Action(isOn: on, region: region)
        actions.append(action)
    }
}

var cuboids: [Cuboid] = []
for action in actions {
    cuboids = action.apply(to: cuboids)
    print("\(cuboids.count) cuboids")
}

let totalVolume = cuboids.reduce(0) { $0 + $1.volume }
print("Total volume: \(totalVolume)")
