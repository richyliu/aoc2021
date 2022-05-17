#include <iostream>
#include <fstream>

int main() {
    std::ifstream in("input.txt");

    // track horizontal and depth totals
    int horizontal = 0;
    int depth = 0;

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
        } else if (direction == "down") {
            depth += distance;
        } else if (direction == "up") {
            depth -= distance;
        }
    }

    // we want the product of the horizontal and depth totals
    int total = horizontal * depth;
    std::cout << total << std::endl;
}
