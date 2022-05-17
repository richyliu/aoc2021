#include <stdio.h>
#include <stdlib.h>

int main() {
    char* fname = "input.txt";
    FILE* fp = fopen(fname, "r");

    // track the current and previous values
    int prev = -1;
    int cur;
    // count the number of times current is greater than previous
    int count = 0;

    // read number from each line
    while (fscanf(fp, "%d", &cur) != EOF) {
        // if current is greater than previous, increment count
        if (cur > prev && prev != -1) {
            count++;
        }
        // update previous and current
        prev = cur;
    }

    // print the number of times current is greater than previous
    printf("%d\n", count);
    return 0;
}
