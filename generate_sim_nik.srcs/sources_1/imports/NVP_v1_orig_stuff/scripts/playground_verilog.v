`timescale 1ns / 1ps

module playground_verilog #(    
    parameter integer WIDTH = 8
)(
    input  wire                clk,
    input  wire                resetn,
    input  wire [WIDTH-1:0]    i_data
);

    // typedef enum {FIRST, SECOND} test_type_t;
    // test_type_t test;

endmodule