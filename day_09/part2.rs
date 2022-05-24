use std::collections::VecDeque;
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
    let width = grid[0].len();
    let height = grid.len();

    // loop over the entire grid, looking for contiguous regions
    let mut visited = vec![vec![false; width]; height];
    let mut group_sizes = vec![];
    for y in 0..height {
        for x in 0..width {
            if !visited[y][x] {
                // 9's are the boundary of the regions
                if grid[y][x] == 9 {
                    visited[y][x] = true;
                    continue;
                }
                // BFS for region size
                let mut group_size = 0;
                let mut queue = VecDeque::new();
                queue.push_back((x, y));
                while let Some((x, y)) = queue.pop_front() {
                    if !visited[y][x] {
                        visited[y][x] = true;
                        // ignore 9's because they are the boundary of the regions
                        if grid[y][x] == 9 {
                            continue;
                        }
                        group_size += 1;
                        // add neighbors to queue for BFS
                        for (dx, dy) in &[(0, 1), (0, -1), (1, 0), (-1, 0)] {
                            let (nx, ny) = (x as i32 + dx, y as i32 + dy);
                            if nx >= 0 && nx < width as i32 && ny >= 0 && ny < height as i32 {
                                queue.push_back((nx as usize, ny as usize));
                            }
                        }
                    }
                }
                group_sizes.push(group_size);
            }
        }
    }

    // sort the group sizes and multiply the 3 largest together
    let mut group_sizes = group_sizes.clone();
    group_sizes.sort();
    let mut product = 1;
    for i in group_sizes.len() - 3..group_sizes.len() {
        product *= group_sizes[i];
    }
    println!("Product: {}", product);
}
