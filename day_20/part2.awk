#!/usr/bin/env -S awk -f

# Note: local variables in functions are placed in the arguments with 4 spaces
# before them

BEGIN {}

NR == 1 {
    lookup_table = $1
}

NR > 2 {
    n = split($1, line, "")
    for (i = 1; i <= n; i++) {
        grid[NR-2, i] = line[i]
    }
    width = n
}


END {
    height = NR-2
    # what character the infinite grid background is
    background = "."

    for (c = 0; c < 50; c++) {
        update_grid()
    }

    # count pixels in final grid
    print count_pixels()
}


function count_pixels() {
    n = 0
    for (i = 1; i <= height; i++) {
        for (j = 1; j <= width; j++) {
            if (grid[i, j] == "#") {
                n++
            }
        }
    }
    return n
}


function print_grid() {
    for (i = 1; i <= height; i++) {
        for (j = 1; j <= width; j++) {
            printf("%c", grid[i, j])
        }
        printf("\n")
    }
}

function copy_grid(from, to) {
    for (i = 1; i <= height; i++) {
        for (j = 1; j <= width; j++) {
            to[i, j] = from[i, j]
        }
    }
}

# Enlarges grid by 1 row and 1 column in each direction and fills with
# background
function enlarge_grid(    new_grid) {
    # copy grid to new grid
    for (i = 1; i <= height; i++) {
        for (j = 1; j <= width; j++) {
            new_grid[i+1, j+1] = grid[i, j]
        }
    }
    height += 2
    width += 2

    # fill new grid with background
    for (i = 1; i <= height; i++) {
        new_grid[i, 1] = background
        new_grid[i, width] = background
    }
    for (j = 1; j <= width; j++) {
        new_grid[1, j] = background
        new_grid[height, j] = background
    }

    copy_grid(new_grid, grid)
}

# Lookup the 3x3 square of characters around the given position and return the
# value it corresponds to in the lookup_table.
function lookup_square(i, j) {
    # get the 3x3 square of characters around the given position as an integer
    # (. is 0, # is 1)
    square = 0
    for (k = -1; k <= 1; k++) {
        for (l = -1; l <= 1; l++) {
            square = square * 2
            if (i+k > 0 && i+k <= height && j+l > 0 && j+l <= width) {
                square += grid[i+k, j+l] == "#"
            } else {
                square += background == "#"
            }
        }
    }
    return substr(lookup_table, square+1, 1)
}

function update_grid(    new_grid) {
    enlarge_grid()
    for (i = 1; i <= height; i++) {
        for (j = 1; j <= width; j++) {
            new_grid[i, j] = lookup_square(i, j)
        }
    }
    copy_grid(new_grid, grid)
    if (background == "#") {
        background = substr(lookup_table, 512, 1)
    } else {
        background = substr(lookup_table, 1, 1)
    }
}
