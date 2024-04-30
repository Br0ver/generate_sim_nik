/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Output Stage 
*   Date:  14.02.2022
*   Author: hasan
*   Description: Compression (if needed) and output commit. 
*/

`timescale 1ns / 1ps

module output_stage #(
    parameter int DATA_BIT_WIDTH                = 8,
    parameter int ACTIVATION_BANK_BIT_WIDTH   = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    localparam int INPUT_ARRAY_WIDTH            = DATA_BIT_WIDTH, 
    localparam int DATA_AND_SM_ARRAY_WIDTH      = DATA_BIT_WIDTH+1, // the output array includes the Sparsity Map (SM)
    localparam int DATA_AND_SM_BIT_WIDTH        = DATA_BIT_WIDTH+1
    // localparam int DATA_AND_STATUS_BIT_WIDTH    = DATA_BIT_WIDTH+1 // one extra bit for status 
)(
    input  logic                                    clk,
    input  logic                                    resetn,
    input  logic                                    i_clear_output_stage,
    input  logic                                    i_sm_valid, 
    input  logic [DATA_BIT_WIDTH-1:0]               i_sm,
    input  logic [DATA_BIT_WIDTH-1:0]               i_input_array [INPUT_ARRAY_WIDTH], 
    output logic                                    o_output_stage_ready, 
    output logic [ACTIVATION_BANK_BIT_WIDTH-1:0]  o_output_array,
    output logic                                    o_output_valid,
    output logic                                    o_output_last
);

    // --------------------------------------
    // ------ Compression stage 
	// --------------------------------------
    logic                               next_stage_ready;
    logic [DATA_AND_SM_BIT_WIDTH-1:0]   compressed_array [DATA_AND_SM_ARRAY_WIDTH];
    logic                               clear_commit_stage;
    sm_compression_routing_mesh #( 
        .DATA_BIT_WIDTH    (DATA_BIT_WIDTH)
    ) compression_unit (
        .clk                        (clk),
        .resetn                     (resetn),
        .i_clear_compression_stage  (i_clear_output_stage),
        .i_commit_stage_ready       (next_stage_ready), // TODO:: check me
        .i_sm_valid                 (i_sm_valid),        
        .i_sm                       (i_sm),        
        .i_input_array              (i_input_array),          
        .o_output_array             (compressed_array),
        .o_clear_commit_stage       (clear_commit_stage)
    );
    // better debug visibility 
    logic [DATA_BIT_WIDTH-1:0]   debug_compressed_array [DATA_AND_SM_ARRAY_WIDTH];
    logic [DATA_AND_SM_ARRAY_WIDTH-1:0] debug_compressed_array_valid_array;
    always_comb begin 
        for (int i = 0; i < DATA_AND_SM_ARRAY_WIDTH; i++) begin
            debug_compressed_array[i] = compressed_array[i][DATA_AND_SM_BIT_WIDTH-1:1];
            debug_compressed_array_valid_array[i] = compressed_array[i][0];
        end
    end
    
    // --------------------------------------
    // ------ Commit stage 
	// --------------------------------------
    logic                                                commit_input_valid;
    logic                                                commit_stage_ready;
    logic [$clog2(DATA_AND_SM_ARRAY_WIDTH)-1:0]          commit_input_array_pop_count;
    logic [DATA_AND_SM_ARRAY_WIDTH*DATA_BIT_WIDTH-1:0]   commit_input_array; // including sm
    commit_stage #(
        .DATA_BIT_WIDTH                 (DATA_BIT_WIDTH),
        .ACTIVATION_BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH)
    ) commit_output_unit (
        .clk                        (clk),                            
        .resetn                     (resetn),
        .i_clear_commit_stage       (clear_commit_stage),
        .i_valid                    (commit_input_valid),
        .o_ready                    (commit_stage_ready),
        .i_input_array_pop_count    (commit_input_array_pop_count),                
        .i_input_array              (commit_input_array),    
        .o_output_array             (o_output_array),
        .o_output_valid             (o_output_valid),
        .o_output_last              (o_output_last)
    );
    // connect compression and commit stages
    always_comb begin
        commit_input_valid = debug_compressed_array_valid_array[$left(debug_compressed_array_valid_array)];

        commit_input_array_pop_count = '0;
        for (int i=0; i<DATA_AND_SM_ARRAY_WIDTH; i++) begin
            commit_input_array_pop_count += debug_compressed_array_valid_array[i]; // pop count of all valid words, including the sm
        end

        for (int i=0; i<DATA_AND_SM_ARRAY_WIDTH; i++) begin
            commit_input_array[(i+1)*DATA_BIT_WIDTH-1 -: DATA_BIT_WIDTH] = debug_compressed_array[i];
        end

        next_stage_ready = commit_stage_ready;
    end

    always_comb o_output_stage_ready = commit_stage_ready;

endmodule