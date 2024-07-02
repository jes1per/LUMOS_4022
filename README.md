# Computer Organization - Spring 2024
## Iran University of Science and Technology
### Project
- **Team Members:** Parsa Amiri, Rasa Ghorbanalizade, Mohammad Amin Mirzaabbasi
- **Date:** 2/7/2024
---
## Report 📝

### 1. Multiplication Result Bit Selection 🧮

In the given Verilog code, the "multiplication segment" handles the case where the operation is `FPU_MUL`. Here's the relevant portion of the code:

```verilog
`FPU_MUL    : begin result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= product_ready; end
```
In the multiplication operation, the result signal takes its value from selected bits of the product signal. the reason why is when multiplying two fixed-point or floating-point numbers, the resulting `product` will have more bits than the original operands. Specifically:
- If each operand is `WIDTH` bits wide and has `FBITS` fractional bits,
- Then the product will have a bit width of `2 * WIDTH`.

To normalize the result back to the original fixed-point format (i.e., maintaining the same number of bits as the operands), a subset of these bits needs to be selected. The subset `product[WIDTH + FBITS - 1 : FBITS]` effectively captures the most significant bits of the product while maintaining the same fractional precision.

#### in the code:
1. The `product` signal is 64 bits wide (twice the width of the 32-bit operands).
2. `WIDTH` is 32 (total bits in each operand).
3. `FBITS` is 10 (fractional bits in Q22.10 format).

By selecting `product[WIDTH + FBITS - 1 : FBITS]`, we're effectively:
- Discarding the least significant 10 bits (extra precision beyond Q22.10).
- Taking the next 32 bits, which align with our Q22.10 fixed-point representation.

This selection ensures that the result maintains the Q22.10 format, preserving the correct balance of 22 integer bits and 10 fractional bits.

Thus, the line `result <= product[WIDTH + FBITS - 1 : FBITS];` extracts the appropriate portion of the product, ensuring the final `result` has the same format (width and fractional bits) as the original operands.

---
### 2. 32-bit Multiplier Circuit Implementation ✖️

The 32-bit multiplier circuit is implemented using a state machine approach to perform the multiplication over 5 clock cycles using a 16-bit multiplier. This design is optimized for the Q22.10 fixed-point format.

####  Main Components
1. 16x16 Multiplier Module
2. State Machine for Controlling Multiplication Steps
3. Partial Product Registers

#### Detailed Explanation

1. **16x16 Multiplier Module**:
   - A separate module `Multiplier` is instantiated to perform 16x16 bit multiplication.
   - It takes two 16-bit inputs and produces a 32-bit output.

2. **State Machine**:
   - Uses a 3-bit `mul_state` to control the multiplication process.
   - Goes through 5 states (0 to 4) to complete the 32x32 multiplication.

3. **Multiplication Process**:
   - State 0: Multiply lower halves (A1 * B1)
   - State 1: Multiply upper half of A with lower half of B (A2 * B1)
   - State 2: Multiply lower half of A with upper half of B (A1 * B2)
   - State 3: Multiply upper halves (A2 * B2)
   - State 4: Prepare final partial product, and Combine all partial products

4. **Partial Products**:
   - Four 32-bit registers (P1, P2, P3, P4) store the partial products.
   - These are combined in the final state to produce the 64-bit result.

This implementation allows for a 32x32 bit multiplication using a smaller 16x16 multiplier, optimized for the Q22.10 fixed-point format.

![Multiplier](https://github.com/jes1per/LUMOS_4022/blob/main/Multiplier.jpg)

---
### 3. Square Root Calculator Implementation 📐

The square root calculator is implemented using an iterative algorithm based on the code from [Project F's Square Root in Verilog](https://projectf.io/posts/square-root-in-verilog/). The implementation has been adapted to work with the Q22.10 fixed-point format.

####  Main Components
1. State Machine for Controlling Square Root Calculation
2. Iterative Calculation Logic
3. Result Registers and Control Signals

#### Detailed Explanation

1. **State Machine**:
   - Uses states IDLE, START, CALCULATE, and DONE to control the calculation process.
   - Transitions between states based on the operation and iteration count.

2. **Calculation Logic**:
   - Implements the iterative square root algorithm (Long Division), adjusted for Q22.10 format.
   - Uses registers for the current remainder (x), current result (q), and accumulator (ac).
   - Performs test subtractions and updates the result in each iteration.

3. **Control and Output**:
   - `sqrt_busy` signal indicates when calculation is in progress.
   - `root_ready` signal indicates when the result is available.
   - The final result is stored in the `root` register in Q22.10 format.

4. **Iteration Process**:
   - The calculation is performed over multiple clock cycles.
   - The number of iterations is determined by `(WIDTH + FBITS) >> 1`, which is 21 for Q22.10 format.

This implementation provides an efficient method for calculating square roots in Q22.10 fixed-point format using only addition, subtraction, and bit shifting operations.

![Square Root](https://github.com/jes1per/LUMOS_4022/blob/main/Square%20Root.jpg)

---
### 4. Assembly.s Explanation 🗺️

The assembly code calculates the total distance of a path connecting 50 points in a Cartesian plane, using the Q22.10 fixed-point format for calculations.

####  Main Components
1. Initialization
2. Main Loop
3. Distance Calculation
4. Loop Control and Termination

#### Detailed Explanation

1. **Initialization**:
   ```assembly
   li          sp,     0x3C00
   addi        gp,     sp,     392
   ```
    1. **`li sp, 0x3C00`**: Loads the immediate value `0x3C00` into the stack pointer register (`sp`). This sets up the stack pointer to point to the memory location `0x3C00`.
    2. **`addi gp, sp, 392`**: Adds the immediate value `392` (49 * 8) to the current value of `sp` and stores the result in the global pointer register (`gp`). This sets up a limit for the loop, marking the memory region containing 50 points.

2. **Loop to Compute Distance**:
   ```assembly
    loop:
        flw         f1,     0(sp)        # Load the word at address sp into floating point register f1
        flw         f2,     4(sp)        # Load the word at address sp + 4 into floating point register f2
        
        fmul.s      f10,    f1,     f1   # Multiply f1 by itself and store the result in f10 (x^2)
        fmul.s      f20,    f2,     f2   # Multiply f2 by itself and store the result in f20 (y^2)
        fadd.s      f30,    f10,    f20  # Add f10 and f20, storing the result in f30 (x^2 + y^2)
        fsqrt.s     x3,     f30          # Compute the square root of f30 and store the result in x3
        fadd.s      f0,     f0,     f3   # Add f3 to f0 and store the result in f0 (accumulate distances)

        addi        sp,     sp,     8    # Increment sp by 8 to point to the next pair of coordinates
        blt         sp,     gp,     loop # Branch to 'loop' if sp is less than gp
    ```
    1. **`flw f1, 0(sp)`**: Loads the floating-point value from the address pointed to by `sp` into the floating-point register `f1`. This represents the x-coordinate of a distance.
    2. **`flw f2, 4(sp)`**: Loads the floating-point value from the address `sp + 4` into the floating-point register `f2`. This represents the y-coordinate of a distance.
    3. **`fmul.s f10, f1, f1`**: Multiplies `f1` by itself and stores the result in `f10`. This computes \( x^2 \) in Q22.10 format.
    4. **`fmul.s f20, f2, f2`**: Multiplies `f2` by itself and stores the result in `f20`. This computes \( y^2 \) in Q22.10 format.
    5. **`fadd.s f30, f10, f20`**: Adds `f10` and `f20`, and stores the result in `f30`. This computes \( x^2 + y^2 \) in Q22.10 format.
    6. **`fsqrt.s x3, f30`**: Computes the square root of `f30` and stores the result in `x3`. This computes \( \sqrt{x^2 + y^2} \) in Q22.10 format.
    7. **`fadd.s f0, f0, f3`**: Adds the value of `f3` to `f0` and stores the result in `f0`. This accumulates the distances if `f3` holds the computed distance.
    8. **`addi sp, sp, 8`**: Increments `sp` by 8 to move to the next pair of coordinates.
    9. **`blt sp, gp, loop`**: Branches back to the `loop` label if `sp` is less than `gp`. This ensures that the loop continues until all points are processed.

3. **Termination**:
   ```assembly
   ebreak
   ```
   - **`ebreak`**: This is a breakpoint instruction used for debugging. It stops the program execution.

The final result (total path distance) is stored in floating-point register f0 in Q22.10 format.

#### The Output of our Code
![LOMUS](https://github.com/jes1per/LUMOS_4022/blob/main/LUMOS.jpg)

---