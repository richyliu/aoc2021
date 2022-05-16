#include <stdio.h>
#include <stdlib.h>

int main() {
    char* fname = "input.txt";
    FILE* fp = fopen(fname, "r");

    // track sliding window of 3 values (and 1 for history)
    // window[0] tracks most recent value
    int window[4] = {-1, -1, -1, -1};
    // count the number of times current is greater than previous
    int count = 0;

    // read number from each line
    while (fscanf(fp, "%d", &window[0]) != EOF) {
        int cur = window[0] + window[1] + window[2];
        int prev = window[1] + window[2] + window[3];
        // if current is greater than previous, increment count
        if (cur > prev && window[3] != -1) {
            count++;
        }
        // shift window
        for (int i = 3; i > 0; i--) {
            window[i] = window[i - 1];
        }
    }

    // print the number of times current is greater than previous
    printf("%d\n", count);
    return 0;
}
