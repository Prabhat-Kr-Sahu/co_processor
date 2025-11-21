    .section .text
    .globl _start

_start:
    # Initialize values
    addi x5, x0, 3      # x5 = 3
    addi x6, x0, 4      # x6 = 4

    # Chain of dependent multiplications
    # Without forwarding, each of these would cause a 2-cycle stall.
    mul x7, x5, x6      # x7 = 3 * 4 = 12
    mul x8, x7, x5      # x8 = 12 * 3 = 36
    mul x9, x8, x6      # x9 = 36 * 4 = 144

    # Infinite loop to halt the processor for inspection
end_loop:
    j end_loop

    # (final newline here)
