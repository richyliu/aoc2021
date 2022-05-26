#!/usr/bin/env lua

-- debug print table
function print_table(t)
  for i = 1, 10 do
    for j = 1, 10 do
      io.write(t[i][j])
    end
    io.write("\n")
  end
  io.write("\n")
end

function read_file()
  -- read grid of 10x10 digits from input.txt
  local file = io.open("input.txt", "r")
  local grid = {}
  for i = 1, 10 do
    grid[i] = {}
    for j = 1, 10 do
      grid[i][j] = tonumber(file:read(1))
    end
    file:read(1)
  end
  file:close()
  return grid
end

-- The octopus at the cell "flashes"
-- Increment the neighbors (if they haven't flashed) and reset the cell to 0
function flash_cell(grid, i, j)
  for x = i - 1, i + 1 do
    for y = j - 1, j + 1 do
      if x == i and y == j then
        -- reset current cell to 0
        grid[i][j] = 0
      elseif x >= 1 and x <= 10 and y >= 1 and y <= 10 then
        if grid[x][y] ~= 0 then
          grid[x][y] = grid[x][y] + 1
        end
      end
    end
  end
end

-- Step the octopus grid once, counting any cells that reach level past 9 and
-- reset to 0
-- This modifies the grid in place
function step(grid)
  -- first, increment all cells
  for i = 1, 10 do
    for j = 1, 10 do
      grid[i][j] = grid[i][j] + 1
    end
  end

  -- loop while any cells reach past level 9
  local changed = true
  while changed do
    changed = false
    for i = 1, 10 do
      for j = 1, 10 do
        if grid[i][j] > 9 then
          flash_cell(grid, i, j)
          changed = true
        end
      end
    end
  end

  -- count cells that flashed (were reset to 0)
  local count = 0
  for i = 1, 10 do
    for j = 1, 10 do
      if grid[i][j] == 0 then
        count = count + 1
      end
    end
  end

  return count
end

function main()
  local grid = read_file()
  local c = 0
  local steps = 100
  for i = 1, steps do
    c = c + step(grid)
  end
  print("Flashes: " .. c)
end

main()
