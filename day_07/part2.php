#!/usr/bin/env -S php -f
<?php

$input = file_get_contents('input.txt');

// convert comma separated string to array
$pos = explode(',', $input);

// format array as numeric array
$pos = array_map('intval', $pos);

// find mean
$mean = array_sum($pos) / count($pos);

function calc_cost($pos, $target) {
  $cost = 0;
  foreach ($pos as $p) {
    // now the cost is x(x+1)/2
    $diff = abs($p - $target);
    $cost += $diff * ($diff + 1) / 2;
  }
  return $cost;
}

$cost1 = calc_cost($pos, floor($mean));
$cost2 = calc_cost($pos, ceil($mean));

if ($cost1 < $cost2) {
  echo $cost1;
} else {
  echo $cost2;
}

?>
