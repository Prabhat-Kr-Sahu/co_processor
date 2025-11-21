
int main() {
    // Assembly:
    //   addi x5, x0, 3      # x5 = 3
    //   addi x6, x0, 4      # x6 = 4
    //
    
    volatile int a = 3; // Corresponds to register x5
    volatile int b = 4; // Corresponds to register x6

    // Assembly:
    //   mul x7, x5, x6      # x7 = 3 * 4 = 12
    volatile int c = a * b; // Corresponds to register x7

    // Assembly:
    //   mul x8, x7, x5      # x8 = 12 * 3 = 36
    volatile int d = c * a; // Corresponds to register x8

    // Assembly:
    //   mul x9, x8, x6      # x9 = 36 * 4 = 144
    volatile int e = d * b; // Corresponds to register x9

    // Assembly:
    // end_loop:
    //   j end_loop
    //
    // This is an infinite loop, which halts the program.
    while (1) {
        // Do nothing, just loop forever.
    }

    // This part is unreachable, but 'main' technically returns an int.
    return 0;
}