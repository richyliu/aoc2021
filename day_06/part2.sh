#!/usr/bin/env bash

input=$(<input.txt)

# store fish population as an array of indicies 0..8
# each index corresponds to the number of fish with that timer value
arr=()
for i in {0..8}; do
  arr+=( 0 )
done

# read the comma separated values
for num in ${input//,/ }; do
  ((arr[$num]++))
done

days=256

for (( day=1; day<=$days; day++ )); do
  # a single iteration (day)

  # save number of finish that reproduce
  zeros=${arr[0]}

  # shift all the fish timers (to simulate 1 day passing)
  for i in {1..8}; do
    ((arr[$i-1]=arr[$i]))
  done

  # add new fish
  # (each 0-day fish resets to 6-day fish and births a new 8-day fish)
  ((arr[8]=zeros))
  ((arr[6]+=zeros))

  # echo "Day $day: ${arr[@]}"
done

# sum the fish population
nfish=0
for num in ${arr[@]}; do
  ((nfish+=$num))
done
echo $nfish
