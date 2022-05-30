all: part1 part2

part1: part1.o
	gcc -no-pie part1.o -o part1

part2: part2.o
	gcc -no-pie part2.o -o part2

part1.o: part1.asm
	nasm -felf64 part1.asm

part2.o: part2.asm
	nasm -felf64 part2.asm

clean:
	rm -f part1 part1.o part2 part2.o
