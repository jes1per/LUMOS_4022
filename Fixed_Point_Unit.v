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

        /*
         *  Describe Your Square Root Calculator Circuit Here.
         */

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
