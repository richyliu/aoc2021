#!/usr/bin/env pwsh

# Read input.txt
$rawInput = Get-Content "input.txt"

# Split input into array of digits by removing newline characters
$lines = $rawInput -split "\n"

$width = $lines[0].Length
$height = $lines.Length
$bigWidth = $width * 5
$bigHeight = $height * 5

# Populate the array
$grid = New-Object 'int[,]' $bigHeight, $bigWidth
$i = 0
foreach ($line in $lines) {
    $j = 0
    foreach ($digit in [char[]]$line) {
        $grid[$i, $j] = [int]$digit.ToString()
        $j++
    }
    $i++
}

# Expand the grid 5 times in each direction
for ($i = 0; $i -lt 5; $i++) {
    for ($j = 0; $j -lt 5; $j++) {
        for ($x = 0; $x -lt $width; $x++) {
            for ($y = 0; $y -lt $height; $y++) {
                $newX = $x + $i * $width
                $newY = $y + $j * $height
                $grid[$newX, $newY] = ($grid[$x, $y] - 1 + $i + $j) % 9 + 1
            }
        }
    }
}

$width = $bigWidth
$height = $bigHeight

# # Print the grid
# for ($y = 0; $y -lt $height; $y++) {
#     for ($x = 0; $x -lt $width; $x++) {
#         Write-Host -NoNewline $grid[$y, $x]
#     }
#     Write-Host ""
# }

# Array of best risk values
$best = New-Object 'int[,]' $height, $width
for ($i = 0; $i -lt $height; $i++) {
    for ($j = 0; $j -lt $width; $j++) {
        $best[$i, $j] = [int]::MaxValue
    }
}

# Run modified Dijkstra's algorithm to find the best risk value for each square

# Queue of x, y coordinates
$queue = New-Object 'System.Collections.Queue'

$queue.Enqueue((0, 0))
$best[0, 0] = 0

$i = 0
while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    $x = $current[0]
    $y = $current[1]
    $risk = $best[$x, $y]

    # Write-Host "Current: $x, $y, $risk"

    # Add adjacent squares to the queue if we can do better from here
    if ($x -gt 0 -and $risk + $grid[[int]($x -1), $y] -lt $best[[int]($x -1), $y]) {
        $best[[int]($x -1), $y] = $risk + $grid[[int]($x -1), $y]
        $queue.Enqueue(([int]($x - 1), $y))
    }
    if ($x -lt $height -1 -and $risk + $grid[[int]($x +1), $y] -lt $best[[int]($x +1), $y]) {
        $best[[int]($x +1), $y] = $risk + $grid[[int]($x +1), $y]
        $queue.Enqueue(([int]($x + 1), $y))
    }
    if ($y -gt 0 -and $risk + $grid[$x, [int]($y -1)] -lt $best[$x, [int]($y -1)]) {
        $best[$x, [int]($y - 1)] = $risk + $grid[$x, [int]($y - 1)]
        $queue.Enqueue(($x, [int]($y - 1)))
    }
    if ($y -lt $width -1 -and $risk + $grid[$x, [int]($y +1)] -lt $best[$x, [int]($y +1)]) {
        $best[$x, [int]($y + 1)] = $risk + $grid[$x, [int]($y + 1)]
        $queue.Enqueue(($x, [int]($y + 1)))
    }

    # Update the best risk value for this square
    $best[$x, $y] = $risk

    # Track progress for debugging
    $i++
    if ($i % 100000 -eq 0) {
        Write-Host $i
    }
}
Write-Host "Note: visited $i squares"

# Risk value of the target square (bottom-right corner)
$lastRisk = $best[[int]($height -1), [int]($width -1)]
Write-Host "Last risk: $lastRisk"
