#!/usr/bin/env bash

input=$(<input.txt)

parsed=""
for num in ${input//,/ }; do
  parsed+=" $num"
done

days=80

for (( day=1; day<=$days; day++ )); do
  # a single iteration (day)
  next=""
  for num in $parsed; do
    # reset to 6 and spawn a new 8 once we reach 0
    if (( num == 0 )); then
      next+=" 6 8"
    else
      next+=" $(($num - 1))"
    fi
  done
  echo $day
  parsed=$next
done

nfish=0
for num in $parsed; do
  ((nfish++))
done
echo $nfish
