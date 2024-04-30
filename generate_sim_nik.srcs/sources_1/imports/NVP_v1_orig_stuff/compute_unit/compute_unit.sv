/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Compute Unit
*   Date:  29.11.2021
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

import NVP_v1_constants::*;

module compute_unit #(    
    parameter int REGISTER_WIDTH                    = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS               = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int ACTIVATION_BIT_WIDTH              = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int WEIGHT_BIT_WIDTH                  = NVP_v1_constants::WEIGHT_BIT_WIDTH,
    parameter int NUMBER_OF_PE_ARRAY_ROWS           = NVP_v1_constants::NUMBER_OF_PE_ARRAY_ROWS,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW       = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,
    parameter int NUMBER_OF_PES_PER_ARRAY           = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,
    parameter int NUMBER_OF_READ_STREAMS            = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int CHANNEL_VALUE_BIT_WIDTH           = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int COLUMN_VALUE_BIT_WIDTH            = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int COMBINED_DATA_BIT_WIDTH           = NVP_v1_constants::COMBINED_DATA_BIT_WIDTH,
    parameter int ACTIVATION_BANK_BIT_WIDTH       = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT      = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int WEIGHT_BANK_BIT_WIDTH           = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH, 
    parameter int WEIGHT_LINE_BUFFER_DEPTH               = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter int WEIGHT_BUFFER_BANK_COUNT          = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter int OUTPUT_WRITER_ADDRESS_BIT_WIDTH   = NVP_v1_constants::OUTPUT_WRITER_ADDRESS_BIT_WIDTH,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH   = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS),
    localparam int NUMBER_OF_PE_ARRAYS              = NUMBER_OF_PE_ARRAY_ROWS*NUMBER_OF_PE_ARRAYS_PER_ROW
)(
    input  logic                                        clk,
    input  logic                                        resetn,
    register_file_if                              global_latched_reg_file, 
    register_file_if                              input_reg_file, 
    register_file_if                             output_reg_file, 
    streamed_data_if                              streamed_data,
    decoded_data_if                               decoded_data,
    computation_control_if                        computation_ctrl,
    compute_core_data_if                          compute_data,
    output logic [ACTIVATION_BANK_BIT_WIDTH-1:0]        o_output_array,
    output logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]  o_output_address,
    output logic                                        o_output_valid,
    output logic                                        o_output_line_stored,
    output logic unsigned [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]    debug_quantized_activations, 
    output logic                                        debug_quantized_activations_valid            

);

    // always_comb compute_data.ready = '1; //TODO:: fixme: should be controlled by the "pre_compute" unit

    
    // --------------------------------------
    // ------ PE rows
	// --------------------------------------
    logic [ACCUMULATOR_BIT_WIDTH-1:0]   output_activations  [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS];
    pe_row row_i (
        .clk                    (clk),
        .resetn                 (resetn),
        .computation_ctrl       (computation_ctrl),
        .compute_data           (compute_data),
        .o_output_activations   (output_activations)
    );

    post_processing post_processing_unit (
        .clk                        (clk),
        .resetn                     (resetn),
        .global_latched_reg_file    (global_latched_reg_file),
        .input_reg_file             (input_reg_file),  
        .output_reg_file            (output_reg_file),  
        .streamed_data              (streamed_data), 
        .decoded_data               (decoded_data),
        .computation_ctrl           (computation_ctrl),            
        .compute_data               (compute_data),        
        .i_output_activations       (output_activations),
        .o_output_array             (o_output_array),
        .o_output_address           (o_output_address),
        .o_output_valid             (o_output_valid),
        .o_output_line_stored       (o_output_line_stored),
        .*
    );


    

endmodule