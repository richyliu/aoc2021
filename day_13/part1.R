#!/usr/bin/env Rscript

# read the list of coordinates, followed by list of folding directions
f <- file("input.txt", "r")

# read the list of coordinates
coords <- matrix(nrow=2, ncol=0)
max_x <- 0
max_y <- 0

# row 0 is 0 for x direction, 1 for y direction
# row 1 is for fold amount
dirs <- matrix(nrow=2, ncol=0)

while(TRUE) {
  line <- readLines(f, n=1)
  if (length(line) == 0) {
    break
  }
  # once there equal signs, we read folding directions
  if (grepl("=", line)) {
    after <- strsplit(line, " ")[[1]][3]
    parts <- strsplit(after, "=")[[1]]
    dir <- c(if (parts[1] == "x") 0 else 1, strtoi(parts[2]))
    dir <- matrix(dir, nrow=2)
    dirs <- cbind(dirs, dir)
  } else if (grepl(",", line)) {
    # split line into coordinates by commma
    coord <- strsplit(line, ",")[[1]]
    # convert to integers
    coord <- strtoi(coord)
    # update max values
    max_x <- max(max_x, coord[1])
    max_y <- max(max_y, coord[2])
    # add to coords matrix
    coord <- matrix(coord, nrow=2)
    coords <- cbind(coords, coord)
  }
}

# create matrix from coordinates
grid <- matrix(0, nrow=max_y+1, ncol=max_x+1)
for (i in 1:ncol(coords)) {
  grid[coords[2,i]+1, coords[1,i]+1] <- 1
}


# "fold" the grid
dir <- dirs[1,1]
line <- dirs[2,1]
if (dir == 0) {
  # fold in x direction
  new_grid <- grid[,c(ncol(grid):1)]
  # overlap the fold
  grid <- grid | new_grid
  # remove extra
  grid <- grid[,c(1:line)]
} else {
  # fold in y direction
  new_grid <- grid[c(nrow(grid):1),]
  # overlap the fold
  grid <- grid | new_grid
  # remove extra
  grid <- grid[c(1:line),]
}

# sum up the grid
print(sum(grid))
