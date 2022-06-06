package main

import (
	"fmt"
	"os"
)

// score needed to win
const WINNING_SCORE = 21
// const WINNING_SCORE = 5

type GameState struct {
	// whether or not it is player 1's turn
	player1Turn bool
	// the current position (1-10)
	player1Pos  int
	player2Pos  int
	// the current score, (play until 21)
	player1Score int
	player2Score int
}

// number of ways that player 1 and player 2 can win from a given state
type Wins struct {
	player1Wins uint64
	player2Wins uint64
}

func (w *Wins) add(other Wins) {
	w.player1Wins += other.player1Wins
	w.player2Wins += other.player2Wins
}

func (w *Wins) times(x uint64) {
	w.player1Wins *= x
	w.player2Wins *= x
}

// cache win counts for dynamic programming
var numWins map[GameState]Wins = make(map[GameState]Wins)

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

	// find the number of ways that player 1 and player 2 can win
	wins := countWins(GameState{true, player1Start, player2Start, 0, 0})

	if wins.player1Wins > wins.player2Wins {
		fmt.Println(wins.player1Wins)
	} else {
		fmt.Println(wins.player2Wins)
	}
}

// Count the number of possibilities that player 1 and player 2 can win from a
// given state
func countWins(state GameState) Wins {
	if wins, ok := numWins[state]; ok {
		return wins
	}

	// base case: a player has won
	if state.player1Score >= WINNING_SCORE {
		return Wins{1, 0}
	}
	if state.player2Score >= WINNING_SCORE {
		return Wins{0, 1}
	}

	// recursive step: sum possibilities for each possible dice roll
	totalWins := Wins{0, 0}
	var wins Wins

	// 1 way to roll 3
	wins = countWins(diceRoll(state, 3))
	totalWins.add(wins)

	// 3 ways to roll 4
	wins = countWins(diceRoll(state, 4))
	wins.times(3)
	totalWins.add(wins)

	// 6 ways to roll 5
	wins = countWins(diceRoll(state, 5))
	wins.times(6)
	totalWins.add(wins)

	// 7 ways to roll 6
	wins = countWins(diceRoll(state, 6))
	wins.times(7)
	totalWins.add(wins)

	// 6 ways to roll 7
	wins = countWins(diceRoll(state, 7))
	wins.times(6)
	totalWins.add(wins)

	// 3 ways to roll 8
	wins = countWins(diceRoll(state, 8))
	wins.times(3)
	totalWins.add(wins)

	// 1 way to roll 9
	wins = countWins(diceRoll(state, 9))
	totalWins.add(wins)

	// update table to avoid recalculating
	numWins[state] = totalWins

	return totalWins
}


// simulate a dice roll and advance the state accordingly
func diceRoll(state GameState, roll int) GameState {
	if state.player1Turn {
		state.player1Pos += roll
		state.player1Pos %= 10
		if state.player1Pos == 0 {
			state.player1Pos = 10
		}
		state.player1Score += state.player1Pos
		state.player1Turn = false
	} else {
		state.player2Pos += roll
		state.player2Pos %= 10
		if state.player2Pos == 0 {
			state.player2Pos = 10
		}
		state.player2Score += state.player2Pos
		state.player1Turn = true
	}
	return state
}
