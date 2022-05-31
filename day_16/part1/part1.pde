class Packet {
  int version;
  int id;
  int length; // in bits

  Packet(int version, int id, int length) {
    this.version = version;
    this.id = id;
    this.length = length;
  }
}

class LiteralPacket extends Packet {
  ArrayList<Integer> data;

  LiteralPacket(int version, int id, int length, ArrayList<Integer> data) {
    super(version, id, length);
    this.data = data;
  }

  String toString() {
    return "LiteralPacket: version=" + version + ", id=" + id + ", length=" + length + ", data=" + data;
  }
}

class OperatorPacket extends Packet {
  ArrayList<Packet> subPackets;

  OperatorPacket(int version, int id, int length, ArrayList<Packet> subPackets) {
    super(version, id, length);
    this.subPackets = subPackets;
  }

  String toString() {
    String str = "OperatorPacket: version=" + version + ", id=" + id + ", length=" + length + ", numSubPackets=" + subPackets.size();
    for (Packet p : subPackets) {
      for (String line : p.toString().split("\n")) {
        str += "\n  " + line;
      }
    }
    return str;
  }
}

class PacketParser {
  ArrayList<Integer> bits;

  PacketParser(ArrayList<Integer> bits) {
    this.bits = bits;
  }

  private int toInt(int start, int length) {
    int result = 0;
    for (int i = 0; i < length; i++) {
      result = (result << 1) + bits.get(start + i);
    }
    return result;
  }

  private Packet parsePacket(int offset) {
    int version = toInt(offset, 3);
    int id = toInt(offset + 3, 3);
    if (id == 4) {
      // literal value
      int pos = offset + 6;
      ArrayList<Integer> data = new ArrayList<>();
      while (bits.get(pos) == 1) {
        data.addAll(bits.subList(pos + 1, pos + 5));
        pos += 5;
      }
      data.addAll(bits.subList(pos + 1, pos + 5));
      pos += 5;
      return new LiteralPacket(version, id, pos - offset, data);
    } else {
      // operator
      int pos = offset + 6;
      ArrayList<Packet> subPackets = new ArrayList<>();
      if (bits.get(pos) == 1) {
        // count number of subpackets
        pos++;
        int totalSubPackets = toInt(pos, 11);
        pos += 11;
        for (int i = 0; i < totalSubPackets; i++) {
          subPackets.add(parsePacket(pos));
          pos += subPackets.get(i).length;
        }
      } else {
        // count subpackets by total length
        pos++;
        int totalLength = toInt(pos, 15);
        pos += 15;
        int length = 0;
        while (length < totalLength) {
          subPackets.add(parsePacket(pos));
          length += subPackets.get(subPackets.size() - 1).length;
          pos += subPackets.get(subPackets.size() - 1).length;
        }
      }
      return new OperatorPacket(version, id, pos - offset, subPackets);
    }
  }

  Packet parse() {
    return parsePacket(0);
  }
}

ArrayList<Integer> readFile() {
  // all data is on one line
  String[] lines = loadStrings("input.txt");
  // convert hex string to binary bit array
  ArrayList<Integer> bits = new ArrayList<Integer>();
  for (char c : lines[0].toCharArray()) {
    int b = unhex(str(c));
    bits.add((b >> 3) & 1);
    bits.add((b >> 2) & 1);
    bits.add((b >> 1) & 1);
    bits.add(b & 1);
  }
  return bits;
}

int sumVersion(Packet packet) {
  int sum = packet.version;
  if (packet instanceof OperatorPacket) {
    for (Packet p : ((OperatorPacket) packet).subPackets) {
      sum += sumVersion(p);
    }
  }
  return sum;
}

void setup() {
  ArrayList<Integer> bits = readFile();

  Packet packet = new PacketParser(bits).parse();
  println(packet);

  // sum version numbers
  println("Sum of version numbers: " + sumVersion(packet));

  exit();
}
