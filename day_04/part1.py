#!/usr/bin/env python3

drawn_nums = []
boards = []

# read input file
with open('input.txt') as f:
    # read first line into drawn_nums
    drawn_nums = f.readline().strip().split(',')
    # convert to numbers
    drawn_nums = [int(x) for x in drawn_nums]

    # -1 for newline, 0-4 for each line of the board
    line_pos = -1
    cur_board = []
    # read rest of file into boards
    for line in f:
        # get rid of newline
        if line_pos == -1:
            cur_board = []
            line_pos = 0
            continue
        line = line.strip().split()
        cur_board.append([int(x) for x in line])
        line_pos += 1
        if line_pos == 5:
            boards.append(cur_board)
            line_pos = -1

# check if a board has won after drawing drawn nums
def check_win(board, drawn):
    # check rows
    for i in range(5):
        for j in range(5):
            if board[i][j] not in drawn:
                break
        else:
            return True
    # check cols
    for i in range(5):
        for j in range(5):
            if board[j][i] not in drawn:
                break
        else:
            return True
    return False

# calculate the score of a board at the end of the game
def calc_score(board, drawn):
    # find sum of numbers that weren't drawn
    score = 0
    for row in board:
        for num in row:
            if num not in drawn:
                score += num
    # multiply by winning number
    score *= drawn[-1]
    return score

for i in range(len(drawn_nums)):
    # check if any board has won
    won_boards = []
    for board in boards:
        if check_win(board, drawn_nums[:i+1]):
            won_boards.append(board)

    if len(won_boards) == 0:
        continue

    # find best board
    best_board = None
    best_score = 0
    for board in won_boards:
        score = calc_score(board, drawn_nums[:i+1])
        if score > best_score:
            best_board = board
            best_score = score

    print(best_score)
    break
