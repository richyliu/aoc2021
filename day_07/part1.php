#!/usr/bin/env -S php -f
<?php

$input = file_get_contents('input.txt');

// convert comma separated string to array
$pos = explode(',', $input);

// format array as numeric array
$pos = array_map('intval', $pos);

// find median (this is the position of least movement)
sort($pos);
$median = $pos[floor(count($pos) / 2)];

// sum absolute deviations from median
$cost = 0;
foreach ($pos as $p) {
    $cost += abs($p - $median);
}

echo $cost;

?>
