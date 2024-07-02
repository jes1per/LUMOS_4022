`include "Defines.vh"

module Fixed_Point_Unit 
#(
    parameter WIDTH = 32,
    parameter FBITS = 10
)
(
    input wire clk,
    input wire reset,
    
    input wire [WIDTH - 1 : 0] operand_1,
    input wire [WIDTH - 1 : 0] operand_2,
    
    input wire [ 1 : 0] operation,

    output reg [WIDTH - 1 : 0] result,
    output reg ready
);

    always @(*)
    begin
        case (operation)
            `FPU_ADD    : begin result <= operand_1 + operand_2; ready <= 1; end
            `FPU_SUB    : begin result <= operand_1 - operand_2; ready <= 1; end
            `FPU_MUL    : begin result <= product[WIDTH + FBITS - 1 : FBITS]; ready <= product_ready; end
            `FPU_SQRT   : begin result <= root; ready <= root_ready; end
            default     : begin result <= 'bz; ready <= 0; end
        endcase
    end

    always @(posedge reset)
    begin
        if (reset)  ready = 0;
        else        ready = 'bz;
    end
    // ------------------- //
    // Square Root Circuit //
    // ------------------- //
    reg [WIDTH - 1 : 0] root;
    reg root_ready;

    // Square Root Calculator
    reg [WIDTH-1:0] radicand, sqrt, remainder, next_remainder;
    reg [5:0] iter_count;
    reg [1:0] sqrt_state;

    // BitCounter #(WIDTH) bit_counter_inst (
    //     .data(radicand),
    //     .bit_count(bit_count)
    // );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            root <= 0;
            root_ready <= 0;
            sqrt_state <= 0;
            iter_count <= 0;
            radicand <= 0;
            sqrt <= 0;
            remainder <= 0;
            next_remainder <= 0;
        end else if (operation == `FPU_SQRT) begin
            case (sqrt_state)
                0: begin // Initialize
                    // if (bit_count % 2 == 0) begin
                    radicand <= operand_1; // if bit_count is even
                    // end
                    // else begin
                    //     radicand <= operand_1 << 1; // if bit_count is odd
                    // end
                    sqrt <= 0;
                    remainder <= 0;
                    next_remainder <= 0;
                    iter_count <= 0;
                    sqrt_state <= 1;
                end
                1: begin // Main calculation loop
                    if (iter_count < (WIDTH + FBITS) / 2 && radicand != 0) begin
                        next_remainder <= {remainder, radicand[WIDTH-1:WIDTH-2]};
                        radicand <= {radicand[WIDTH-3:0], 2'b00};
                        
                        remainder <= next_remainder - {sqrt, 2'b01};

                        if (remainder[WIDTH-1] == 1'b1) begin
                            // Remainder is negative, revert subtraction and append 0
                            remainder <= next_remainder;
                            sqrt <= {sqrt, 1'b0};
                        end else begin
                            // Remainder is positive or zero, append 1
                            sqrt <= {sqrt, 1'b1};
                        end
                        
                        iter_count <= iter_count + 1;
                    end else begin
                        sqrt_state <= 2;
                    end
                end
                2: begin // Finalize
                    root <= sqrt << 10;
                    root_ready <= 1;
                    sqrt_state <= 0;
                end
            endcase
        end
    end

    // ------------------ //
    // Multiplier Circuit //
    // ------------------ //   
    reg [64 - 1 : 0] product;
    reg product_ready;

    reg [2:0] mul_state;
    
    reg [15 : 0] mul_op1, mul_op2;
    wire [31 : 0] mul_result;

    reg [31 : 0] P1, P2, P3, P4;

    Multiplier multiplier
    (
        .operand_1(mul_op1),
        .operand_2(mul_op2),
        .product(mul_result)
    );

    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            mul_state <= 0;
            product_ready <= 0;
            product <= 0;
            {P1, P2, P3, P4} <= 0;
            {mul_op1, mul_op2} <= 0;
        end
        else if (operation == `FPU_MUL) begin
            case (mul_state)
                0: begin // A1 * B1
                    mul_op1 <= operand_1[15:0];
                    mul_op2 <= operand_2[15:0];
                    mul_state <= 1;
                end
                1: begin // A2 * B1
                    P1 <= mul_result;
                    mul_op1 <= operand_1[31:16];
                    mul_op2 <= operand_2[15:0];
                    mul_state <= 2;
                end
                2: begin // A1 * B2
                    P2 <= mul_result << 16;
                    mul_op1 <= operand_1[15:0];
                    mul_op2 <= operand_2[31:16];
                    mul_state <= 3;
                end
                3: begin // A2 * B2
                    P3 <= mul_result << 16;
                    mul_op1 <= operand_1[31:16];
                    mul_op2 <= operand_2[31:16];
                    mul_state <= 4;
                end
                4: begin // Combine results
                    P4 <= mul_result << 32;
                    mul_state <= 5;
                end
                5: begin
                    product <= P1 + P2 + P3 + P4;
                    product_ready <= 1;
                    mul_state <= 0;
                end
                default: mul_state <= 0;
            endcase
        end
    end
endmodule

module Multiplier
(
    input wire [15 : 0] operand_1,
    input wire [15 : 0] operand_2,

    output reg [31 : 0] product
);

    always @(*)
    begin
        product <= operand_1 * operand_2;
    end
endmodule

// module BitCounter #(parameter WIDTH = 32) (
//     input wire [WIDTH-1:0] data,
//     output reg [5:0] bit_count
// );
//     reg [5:0] i;
//     integer a;

//     always @(*) begin
//         bit_count = 0;
//         a = 1;
//         for (i = WIDTH-1; i >= 0; i = i - 1) begin
//             if (data[i] && a) begin
//                 bit_count = i + 1;
//                 a = 0;
//             end
//         end
//     end
// endmodule