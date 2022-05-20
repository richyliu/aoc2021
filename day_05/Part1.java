import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.FileReader;

class Path {
  public int x1;
  public int y1;
  public int x2;
  public int y2;
  public boolean isVertical;

  public Path(int x1, int y1, int x2, int y2) {
    this.x1 = x1 < x2 ? x1 : x2;
    this.y1 = y1 < y2 ? y1 : y2;
    this.x2 = x1 < x2 ? x2 : x1;
    this.y2 = y1 < y2 ? y2 : y1;
    this.isVertical = (x1 == x2);
    // must be a vertical or horizontal path
    assert(x1 == x2 || y1 == y2);
  }

  public String toString() {
    return "(" + x1 + ", " + y1 + ") -> (" + x2 + ", " + y2 + ")";
  }
}

public class Part1 {
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
      // only consider horizontal and vertical paths
      if (p.x1 == p.x2 || p.y1 == p.y2) {
        paths.add(p);
      }
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
      for (int i = p.x1; i <= p.x2; i++) {
        for (int j = p.y1; j <= p.y2; j++) {
          grid[j][i]++;
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
