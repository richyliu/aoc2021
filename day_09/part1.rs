use std::fs;

fn main() {
    // read input as grid of digits
    let contents = fs::read_to_string("input.txt").expect("Could not read file");
    let grid: Vec<Vec<u32>> = contents
        .lines()
        .map(|line| {
            line.chars()
                .map(|c| c.to_digit(10).expect("Not a digit"))
                .collect()
        })
        .collect();

    // find low points (they are points that are less than adjacent points)
    // sum up the risk leivel for each low point
    //   - risk level is 1 plus the point's value
    let mut risk_level = 0;
    for y in 0..grid.len() {
        for x in 0..grid[y].len() {
            if x > 0 && grid[y][x] >= grid[y][x - 1] {
                continue;
            }
            if y > 0 && grid[y][x] >= grid[y - 1][x] {
                continue;
            }
            if x < grid[y].len() - 1 && grid[y][x] >= grid[y][x + 1] {
                continue;
            }
            if y < grid.len() - 1 && grid[y][x] >= grid[y + 1][x] {
                continue;
            }

            risk_level += grid[y][x] + 1;
        }
    }

    println!("Risk level: {}", risk_level);
}
