/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  PE Array Arbiter 
*   Date:  18.11.2021
*   Author: hasan
*   Description: The array arbiter distributes the incoming activation streams among the PE groups. 
*           The distribution follows a pre-defined workload balancing, such that different kernels are assigned to each PE group.
*           
*/

`timescale 1ns / 1ps


import NVP_v1_constants::*;

// module combinational_routing_switch #(
//     parameter int INPUT_WORD_BIT_WIDTH = 21
// )(
//     input  logic [INPUT_WORD_BIT_WIDTH-1:0]   i_input,
//     input  logic                                i_routing_code,
//     output logic [INPUT_WORD_BIT_WIDTH-1-1:0] o_output_left,
//     output logic [INPUT_WORD_BIT_WIDTH-1-1:0] o_output_right
// );
//     always_comb begin
//         o_output_left =  (i_routing_code==0)?  input_word : 0;
//         o_output_right = (i_routing_code==1)?  input_word : 0;
//     end
// endmodule

module sequential_routing_switch #(
    parameter int INPUT_WORD_BIT_WIDTH = 8,
    parameter int ROUTING_CODE_BIT_WIDTH = 8
)(
    input  logic                                clk,
    input  logic                                resetn,
    input  logic [INPUT_WORD_BIT_WIDTH-1:0]     i_input,
    input  logic [ROUTING_CODE_BIT_WIDTH-1:0]   i_routing_code,
    output logic [INPUT_WORD_BIT_WIDTH-1:0]     o_output_left,
    output logic [INPUT_WORD_BIT_WIDTH-1:0]     o_output_right,
    output logic [ROUTING_CODE_BIT_WIDTH-1-1:0] o_routing_code_left,
    output logic [ROUTING_CODE_BIT_WIDTH-1-1:0] o_routing_code_right
);

    logic [INPUT_WORD_BIT_WIDTH-1:0] output_left, output_right;
    always_comb o_output_left  = output_left;
    always_comb o_output_right = output_right;
    logic [ROUTING_CODE_BIT_WIDTH-1-1:0] routing_code_left, routing_code_right;
    always_comb o_routing_code_left  = routing_code_left;
    always_comb o_routing_code_right = routing_code_right;
    logic routing_bit;
    always_comb routing_bit = i_routing_code[ROUTING_CODE_BIT_WIDTH-1];
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            output_left         <= '0;
            output_right        <= '0;
            routing_code_left   <= '0;
            routing_code_right  <= '0;
        end
        else begin
            if(routing_bit==0) begin
                output_left         <=  i_input;
                routing_code_left   <=  i_routing_code[ROUTING_CODE_BIT_WIDTH-1-1:0];
                output_right        <=  '0;
                routing_code_right  <=  '0;
            end
            else begin
                output_right        <=  i_input;
                routing_code_right  <=  i_routing_code[ROUTING_CODE_BIT_WIDTH-1-1:0];
                output_left         <=  '0;
                routing_code_left   <=  '0;
            end
        end
    end     
endmodule


module routing_tree #(
    parameter  int INPUT_WORD_BIT_WIDTH             = 8,  //ACTIVATION_BIT_WIDTH,
    parameter  int NUMBER_OF_ROUTING_TREE_OUTPUTS   = 16, //NUMBER_OF_PES_PER_ARRAY,
    localparam int ROUTING_CODE_BIT_WIDTH           = $clog2(NUMBER_OF_ROUTING_TREE_OUTPUTS),
    localparam int NUMBER_OF_ROUTING_TREE_LEVELS    = $clog2(NUMBER_OF_ROUTING_TREE_OUTPUTS)
)(
    input  logic                                 clk,
    input  logic                                 resetn,
    input  logic [INPUT_WORD_BIT_WIDTH-1:0]      i_input,
    input  logic [ROUTING_CODE_BIT_WIDTH-1:0]    i_routing_code,
    output logic [INPUT_WORD_BIT_WIDTH-1:0]      o_outputs [NUMBER_OF_ROUTING_TREE_OUTPUTS]
);

    logic [INPUT_WORD_BIT_WIDTH-1 : 0] data_routing_wires [NUMBER_OF_ROUTING_TREE_LEVELS+1][NUMBER_OF_ROUTING_TREE_OUTPUTS];
    logic [ROUTING_CODE_BIT_WIDTH : 0] code_routing_wires [NUMBER_OF_ROUTING_TREE_LEVELS+1][NUMBER_OF_ROUTING_TREE_OUTPUTS];
    always_comb data_routing_wires[0][0] = i_input;
    always_comb code_routing_wires[0][0] = {i_routing_code, 1'b0};
    
    // ------ Routing tree 
    generate
        for (genvar i=0; i<NUMBER_OF_ROUTING_TREE_LEVELS; i++) begin : level // iterate levels
            for (genvar j=0; j<(2**i); j++) begin : switch // iterate switches
                sequential_routing_switch #(
                    .INPUT_WORD_BIT_WIDTH   (INPUT_WORD_BIT_WIDTH),
                    .ROUTING_CODE_BIT_WIDTH (ROUTING_CODE_BIT_WIDTH+1-i)    
                ) switch_i_j (
                    .clk                    (clk),
                    .resetn                 (resetn),
                    .i_input                (data_routing_wires[i][j]),    
                    .i_routing_code         (code_routing_wires[i][j][ROUTING_CODE_BIT_WIDTH-i:0]),        
                    .o_output_left          (data_routing_wires[i+1][2*j]),       
                    .o_output_right         (data_routing_wires[i+1][2*j+1]),        
                    .o_routing_code_left    (code_routing_wires[i+1][2*j][ROUTING_CODE_BIT_WIDTH-(i+1):0]),    
                    .o_routing_code_right   (code_routing_wires[i+1][2*j+1][ROUTING_CODE_BIT_WIDTH-(i+1):0])          
                );
            end
        end
    endgenerate

    always_comb begin
        for (int i=0; i<NUMBER_OF_ROUTING_TREE_OUTPUTS; i++) begin
            o_outputs[i] = data_routing_wires[NUMBER_OF_ROUTING_TREE_LEVELS][i];
        end
    end

endmodule