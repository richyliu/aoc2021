import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.FileReader;

enum Direction {
  HORIZONTAL, VERTICAL, DIAGONAL_DOWN, DIAGONAL_UP
}

class Path {
  public int x1;
  public int y1;
  public int x2;
  public int y2;
  public Direction dir;

  public Path(int x1, int y1, int x2, int y2) {
    if (x1 == x2 || y1 == y2) {
      this.x1 = x1 < x2 ? x1 : x2;
      this.y1 = y1 < y2 ? y1 : y2;
      this.x2 = x1 < x2 ? x2 : x1;
      this.y2 = y1 < y2 ? y2 : y1;
      if (x1 == x2) {
        this.dir = Direction.VERTICAL;
      } else {
        this.dir = Direction.HORIZONTAL;
      }
    } else {
      // sort points by x direction
      if (x1 < x2) {
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
      } else {
        this.x1 = x2;
        this.y1 = y2;
        this.x2 = x1;
        this.y2 = y1;
      }
      if (this.y1 < this.y2) {
        this.dir = Direction.DIAGONAL_DOWN;
      } else {
        this.dir = Direction.DIAGONAL_UP;
      }
    }
  }

  public String toString() {
    return "(" + x1 + ", " + y1 + ") -> (" + x2 + ", " + y2 + ")";
  }
}

public class Part2 {
  public static void main(String[] args) throws Exception {
    FileReader fr = new FileReader("input.txt");
    BufferedReader br = new BufferedReader(fr);

    // read all lines in the form of "x1,y1 -> x2,y2"
    String line;
    ArrayList<Path> paths = new ArrayList<Path>();
    while ((line = br.readLine()) != null) {
      String[] parts = line.split(" -> ");
      String[] start = parts[0].split(",");
      String[] end = parts[1].split(",");
      Path p = new Path(
          Integer.parseInt(start[0]),
          Integer.parseInt(start[1]),
          Integer.parseInt(end[0]),
          Integer.parseInt(end[1]));
      paths.add(p);
    }

    // initialize grid
    int gridSize = 1000;
    int[][] grid = new int[gridSize][gridSize];
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        grid[i][j] = 0;
      }
    }

    // mark all paths
    for (Path p : paths) {
      if (p.dir == Direction.HORIZONTAL || p.dir == Direction.VERTICAL) {
        // this loops over the path regardless of direction
        for (int i = p.x1; i <= p.x2; i++) {
          for (int j = p.y1; j <= p.y2; j++) {
            grid[i][j]++;
          }
        }
      } else {
        // we know all paths have x1 < x2, but y depends on direction
        int i = p.x1;
        int j = p.y1;
        while (i <= p.x2) {
          grid[i][j]++;
          i++;
          j += (p.dir == Direction.DIAGONAL_DOWN ? 1 : -1);
        }
      }
    }

    // count overlaps
    int overlaps = 0;
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        // System.out.print(grid[i][j] + " ");
        if (grid[i][j] > 1) {
          overlaps++;
        }
      }
      // System.out.println();
    }

    System.out.println(overlaps);
  }
}

