package main

import (
	"fmt"
	"os"
)

func main() {
	// open input file
	file, err := os.Open("input.txt")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer file.Close()

	// read input file
	var player1Start, player2Start int
	fmt.Fscanf(file, "Player 1 starting position: %d", &player1Start)
	fmt.Fscanf(file, "Player 2 starting position: %d", &player2Start)

	// simulate game
	player1Position := player1Start
	player2Position := player2Start
	player1Score := 0
	player2Score := 0
	player1Turn := true
	dice := 1
	numRolls := 0
	for {
		// roll dice
		move := dice*3 + 3
		dice += 3
		if dice > 100 {
			dice -= 100
		}
		numRolls += 3
		// fmt.Printf("Dice: %d ", dice)

		// move player
		if player1Turn {
			player1Position += move
			player1Position %= 10
			if (player1Position == 0) {
				player1Position = 10
			}
			player1Score += player1Position
			player1Turn = false
		} else {
			player2Position += move
			player2Position %= 10
			if (player2Position == 0) {
				player2Position = 10
			}
			player2Score += player2Position
			player1Turn = true
		}

		// check if game is over
		if player1Score >= 1000 || player2Score >= 1000 {
			break
		}

		// fmt.Printf("Player 1: %d, Player 2: %d\n", player1Score, player2Score)
		// if (numRolls > 10) {
		// 	break
		// }
	}

	// print results
	var loser int
	if (player1Score > player2Score) {
		loser = player2Score
	} else {
		loser = player1Score
	}
	fmt.Println("Part 1:", loser * numRolls)
}
