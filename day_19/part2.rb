#!/usr/bin/env ruby

NUM_DIRECTIONS = 48

class Coord
  attr_accessor :x, :y, :z

  def initialize(x, y, z)
    @x = x
    @y = y
    @z = z
  end

  # Transforms a coordinate into a numbered direction
  def transform(d)
    perm_selector = d / 8
    sign_selector = d % 8
    new_x, new_y, new_z = [@x, @y, @z].permutation(3).to_a[perm_selector]
    new_x = new_x * (0 != sign_selector & 0b1 ? -1 : 1)
    new_y = new_y * (0 != sign_selector & 0b10 ? -1 : 1)
    new_z = new_z * (0 != sign_selector & 0b100 ? -1 : 1)
    Coord.new(new_x, new_y, new_z)

  end

  def ==(other)
    @x == other.x && @y == other.y && @z == other.z
  end

  def +(other)
    Coord.new(@x + other.x, @y + other.y, @z + other.z)
  end

  def -(other)
    Coord.new(@x - other.x, @y - other.y, @z - other.z)
  end

  def eql?(other)
    self == other
  end

  def <=>(other)
    if @x != other.x
      return @x <=> other.x
    end
    if @y != other.y
      return @y <=> other.y
    end
    if @z != other.z
      return @z <=> other.z
    end
  end

  def distance(other)
    (@x - other.x).abs + (@y - other.y).abs + (@z - other.z).abs
  end

  def to_s
    "(#{@x}, #{@y}, #{@z})"
  end

  def inspect
    to_s
  end

  def hash
    @x.hash ^ @y.hash ^ @z.hash
  end

  def self.from_string(string)
    x, y, z = string.split(',').map(&:to_i)
    Coord.new(x, y, z)
  end
end

class Distance
  attr_reader :distance

  def initialize(distance)
    @distance = distance
  end

  def ==(other)
    @distance == other.distance
  end

  def eql?(other)
    self == other
  end

  def <=>(other)
    @distance <=> other.distance
  end

  def hash
    @distance.hash
  end

  def to_s
    "#{@distance}"
  end

  def inspect
    to_s
  end
end

class Scanner
  attr_accessor :coords, :distances, :id

  def initialize(coords, id)
    @coords = coords
    @id = id
    # generate a list of distances from each coord to every other coord
    @distances = coords.map do |coord|
      coords.map do |other_coord|
        Distance.new(coord.distance(other_coord))
      end
    end
  end

  def transform(orientation, translation)
    new_coords = coords.map do |coord|
      coord.transform(orientation) + translation
    end
    Scanner.new(new_coords, id)
  end

  def to_s
    "Scanner #{@id}: [#{@coords.map(&:to_s).join(', ')}]"
  end

  def inspect
    to_s
  end

  # Number of distances that overlap with another scanner
  def n_distance_overlap(other)
    this_distances = @distances.flatten.uniq
    other_distances = other.distances.flatten.uniq
    total = this_distances.length + other_distances.length - (this_distances + other_distances).uniq.length
    total.fdiv(this_distances.length + other_distances.length)
  end

  def n_points_overlap(other)
    this_coords = @coords.map(&:to_s).uniq
    other_coords = other.coords.map(&:to_s).uniq
    (this_coords.length + other_coords.length - (this_coords + other_coords).uniq.length)
  end

  # Try to match a scanner to another scanner by the coordinate indexed by
  # this_coord and other_coord. Tweaks orientation of the other scanner. Returns
  # the orientation and diff needed to transform the other scanner to match.
  def try_match(other, this_coord, other_coord)
    # Try each orientation for the other scanner
    (0..NUM_DIRECTIONS-1).each do |orientation|
      # Try each translation for the other scanner
      diff = coords[this_coord] - other.coords[other_coord].transform(orientation)
      transformed = other.transform(orientation, diff)
      n_overlap = n_points_overlap(transformed)
      if n_overlap >= 12
        puts "Diff: #{diff}"
        return orientation, diff
      end
    end
    nil
  end
end

# Find the closest scanner to the given scanner (by index), ignoring some
# scanners. Returns the matched value and index of the scanner.
def match_closest_scanner(scanners, id, ignore)
  scanners.each_with_index.map do |other_scanner, i|
    if ignore.include?(i)
      0
    else
      [scanners[id].n_distance_overlap(other_scanner), i]
    end
  end.sort_by{|x| x[0]}.reverse.each do |x|
    i = x[1]
    if ignore.include?(i)
      next
    end
    t, d = match_scanners(scanners[id], scanners[i])
    if t && d
      return t, d, i
    end
  end
  nil
end

# Try to match scanner1 to scanner2 (by index)
def match_scanners(scanner1, scanner2)
  # Find the overlapping distance values
  this_distances = scanner1.distances.flatten.uniq
  other_distances = scanner2.distances.flatten.uniq
  total = this_distances + other_distances
  dups = total
           .group_by(&:itself)
           .map{|k, v| [k, v.length]}
           .filter{|x| x[1] > 1 && x[0].distance > 0}
           .map{|x| x[0]}
           .sort
           .reverse
  # Only use the top few for speed
  dupsTop = dups.take(10)

  # Find the beacon ids that correspond to the overlapping distances
  table = {}
  scanner1.distances.each_with_index do |other_distances, i|
    other_distances.each_with_index do |distance, j|
      if dupsTop.include?(distance)
        table[distance] = [[i, j]]
      end
    end
  end
  scanner2.distances.each_with_index do |other_distances, i|
    other_distances.each_with_index do |distance, j|
      if dupsTop.include?(distance)
        if table[distance].length == 1
          table[distance] << [i, j]
        end
      end
    end
  end

  # Try matching between pairs of points that share a distance
  table.values.each do |id_pair|
    orientation_and_diff = scanner1.try_match(scanner2, id_pair[0][0], id_pair[1][0])
    if orientation_and_diff
      return orientation_and_diff
    end
    orientation_and_diff = scanner1.try_match(scanner2, id_pair[0][0], id_pair[1][1])
    if orientation_and_diff
      return orientation_and_diff
    end
    orientation_and_diff = scanner1.try_match(scanner2, id_pair[0][1], id_pair[1][0])
    if orientation_and_diff
      return orientation_and_diff
    end
    orientation_and_diff = scanner1.try_match(scanner2, id_pair[0][1], id_pair[1][1])
    if orientation_and_diff
      return orientation_and_diff
    end
  end

  nil
end

def read_scanners
  # Read each paragraph (scanner) individually
  File.readlines('input.txt', "\n\n").map do |paragraph|
    lines = paragraph.strip.split("\n")
    # First line is the name of the scanner
    # extract the id from the name
    id = lines[0].split(' ')[2].to_i
    # The rest of the lines are the coordinates of the scanner
    Scanner.new(lines[1..-1].map do |coord|
                  Coord.from_string(coord)
                end, id)
  end
end

scanners = read_scanners

matched = [0]
match_next = 0

locs = []

while matched.length < scanners.length
  matched.each do |i|
    puts "Try to match with #{i}"
    t, d, match_next = match_closest_scanner(scanners, i, matched)
    if match_next
      puts "Matched with #{match_next}"
      locs << d
      scanners[match_next] = scanners[match_next].transform(t, d)
      matched << match_next
      break
    end
  end
end

# for part 2, find largest distance between two scanner points
dist = locs.combination(2).map do |x, y|
  x.distance(y)
end.max
puts dist
