#include <iostream>
#include <fstream>

int main() {
    std::ifstream in("input.txt");

    // track horizontal and depth totals
    int horizontal = 0;
    int depth = 0;
    // part 2 also tracks the "aim"
    int aim = 0;

    while (in.good()) {
        // read in direction and distance pairs
        std::string direction;
        int distance;
        in >> direction >> distance;

        if (in.eof()) {
            break;
        }

        // increment horizontal or depth based on direction
        if (direction == "forward") {
            horizontal += distance;
            // in part 2, depth increases with aim * distance
            depth += aim * distance;
        } else if (direction == "down") {
            aim += distance;
        } else if (direction == "up") {
            aim -= distance;
        }
    }

    // we want the product of the horizontal and depth totals
    int total = horizontal * depth;
    std::cout << total << std::endl;
}
