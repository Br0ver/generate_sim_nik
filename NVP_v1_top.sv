/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP Accelerator v1 Top Module
*   Date:  05.11.2021
*   Author: hasan
*   Description: The Accelerator's top level module. Connects all the submodules.  
*/

// next steps:
// 1. use simpler muxing inside PE -> i_partial result and accumulators
// 2. share a single dsp between two pes
// 3. group-systolic PE operation

// To test/implement:
// 1. dilated conv
// 2. DENSE mode address generation
// 3. PW address generation

// minor optimizations
// 1. buffer a flag instead of "output_fifo_read_concatenated_flags" 
// 2. reduce post_processing latency -> remove output slicing?? 





`timescale 1ns / 1ps

import NVP_v1_constants::*;

module NVP_v1_top 
( 
    input logic     clk,
    input logic     resetn,
    s_axi_bus       i_data_bus,
    s_axi_bus       i_weight_bus,
    s_axi_lite_bus  i_control_bus,
    output logic    o_next_command_interrupt,
    output logic    o_output_line_stored,

    output logic [NUMBER_OF_READ_STREAMS-1:0]  debug_last_column    ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_0_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_0_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_0_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_0_relative_row   ,
    output logic                               debug_0_valid          ,
    output logic                               debug_0_ready          ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_1_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_1_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_1_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_1_relative_row   ,
    output logic                               debug_1_valid          ,
    output logic                               debug_1_ready          ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_2_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_2_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_2_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_2_relative_row   ,
    output logic                               debug_2_valid          ,
    output logic                               debug_2_ready          ,
    output logic unsigned [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]    debug_quantized_activations, 
    output logic                                        debug_quantized_activations_valid
);

    // --------------------------------------
    // ------ Instantiate Interfaces (data and control interfaces) 
	// --------------------------------------
    register_file_if #(.REGISTER_WIDTH(REGISTER_WIDTH)) reg_file ();
    register_file_if #(.REGISTER_WIDTH(REGISTER_WIDTH)) global_latched_reg_file ();
    register_file_if #(.REGISTER_WIDTH(REGISTER_WIDTH)) pre_compute_latched_reg_file ();
    register_file_if #(.REGISTER_WIDTH(REGISTER_WIDTH)) compute_latched_reg_file ();
    control_and_stream_decoder_if stream_decoder_ctrl();
    streamed_data_if #(
        .NUMBER_OF_READ_STREAMS                 (NUMBER_OF_READ_STREAMS), 
        .ACTIVATION_BANK_BIT_WIDTH              (ACTIVATION_BANK_BIT_WIDTH),
        .ACTIVATION_BUFFER_BANK_COUNT           (ACTIVATION_BUFFER_BANK_COUNT)
    ) streamed_data();
    decoded_data_if #(
        .NUMBER_OF_READ_STREAMS                 (NUMBER_OF_READ_STREAMS),
        .ACTIVATION_BIT_WIDTH                   (ACTIVATION_BIT_WIDTH),
        .COLUMN_VALUE_BIT_WIDTH                 (COLUMN_VALUE_BIT_WIDTH),
        .CHANNEL_VALUE_BIT_WIDTH                (CHANNEL_VALUE_BIT_WIDTH),
        .ROW_VALUE_BIT_WIDTH                    (ROW_VALUE_BIT_WIDTH)
    ) decoded_data();
    compute_core_data_if #(
        .COMBINED_DATA_BIT_WIDTH                (COMBINED_DATA_BIT_WIDTH),
        .ACTIVATION_BANK_BIT_WIDTH              (ACTIVATION_BANK_BIT_WIDTH),        
        .ACTIVATION_BUFFER_BANK_COUNT           (ACTIVATION_BUFFER_BANK_COUNT),        
        .WEIGHT_BANK_BIT_WIDTH                  (WEIGHT_BANK_BIT_WIDTH),    
        .WEIGHT_BANK_DEPTH                      (WEIGHT_LINE_BUFFER_DEPTH),    
        .WEIGHT_BUFFER_BANK_COUNT               (WEIGHT_BUFFER_BANK_COUNT),    
        .NUMBER_OF_READ_STREAMS                 (NUMBER_OF_READ_STREAMS),
        .NUMBER_OF_PE_ARRAYS_PER_ROW            (NUMBER_OF_PE_ARRAYS_PER_ROW)        
    ) compute_data();
    computation_control_if #(
        .WEIGHT_BANK_DEPTH                      (WEIGHT_LINE_BUFFER_DEPTH),
        .WEIGHT_BANK_BIT_WIDTH                  (WEIGHT_BANK_BIT_WIDTH),    
        .WEIGHT_BUFFER_BANK_COUNT               (WEIGHT_BUFFER_BANK_COUNT),
        .NUMBER_OF_PE_ARRAYS_PER_ROW            (NUMBER_OF_PE_ARRAYS_PER_ROW),
        .SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS   (SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS),
        .BIAS_LINE_BUFFER_DEPTH                 (BIAS_LINE_BUFFER_DEPTH),
        .BIAS_BANK_BIT_WIDTH                    (BIAS_BANK_BIT_WIDTH),
        .BIAS_BUFFER_BANK_COUNT                 (BIAS_BUFFER_BANK_COUNT)
    ) computation_ctrl();

    // --------------------------------------
    // ------ Control Unit
	// --------------------------------------
    logic push_sync_word;
    control_unit control_unit_i (
        .clk                        (clk),
        .resetn                     (resetn),
        .i_control_bus              (i_control_bus),
        .reg_file                   (reg_file),
        .latched_reg_file           (global_latched_reg_file),
        .compute_latched_reg_file   (compute_latched_reg_file),
        .stream_decoder_ctrl        (stream_decoder_ctrl),
        .o_push_sync_word           (push_sync_word),
        .o_next_command_interrupt   (o_next_command_interrupt)
    );

    // --------------------------------------
    // ------ On-Chip Memory 
	// --------------------------------------
    logic [ACTIVATION_BANK_BIT_WIDTH-1:0]       output_array;
    logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0] output_address;
    logic                                       output_valid;
	on_chip_memory memory_i (
        .clk                (clk),
        .resetn             (resetn),
        .i_data_bus         (i_data_bus),
        .i_weight_bus       (i_weight_bus),
        .reg_file           (reg_file), // needed here to properly buffer incoming data from DRAM.
        .latched_reg_file   (global_latched_reg_file), // needed here to properly stream/read stored data.
        .streamed_data      (streamed_data),      
        .computation_ctrl   (computation_ctrl),
        .i_output_array     (output_array), // output results from compute unit
        .i_output_address   (output_address),
        .i_output_valid     (output_valid)
    );

    // --------------------------------------
    // ------ Compressed stream decoders
	// --------------------------------------    
    compressed_stream_decoder_wrapper compressed_stream_decoder (
        .clk                    (clk),
        .resetn                 (resetn),
        .latched_reg_file       (global_latched_reg_file),
        .streamed_data          (streamed_data),
        .decoded_data           (decoded_data),
        .stream_decoder_ctrl    (stream_decoder_ctrl)
    );

    // --------------------------------------
    // ------ Pre-compute compressed data interface
    // ------ Takes the decoded compressed data as input from the stream readers, and filters out the invalid data (due to sm processing) and buffers the non-zero pixels for processing. 
    // ------ In PW conv mode, the three stream readers work independently and in parallel. There is no need to schedule one word. 
	// --------------------------------------
    pre_compute_scheduler pre_compute_unit (
        .clk                (clk),
        .resetn             (resetn),
        .input_reg_file     (global_latched_reg_file), // this gets latched locally, to ensure proper control. 
        .output_reg_file    (pre_compute_latched_reg_file), // the locally latched register file (pipelined) is forwarded to next stage (compute unit)
        .streamed_data      (streamed_data),
        .decoded_data       (decoded_data),
        .compute_data       (compute_data),
        .computation_ctrl   (computation_ctrl),
        .i_push_sync_word   (push_sync_word)
    );

    // --------------------------------------
    // ------ Compute Core
	// --------------------------------------
    compute_unit compute_unit_i ( 
        .clk                        (clk),
        .resetn                     (resetn),
        .global_latched_reg_file    (global_latched_reg_file), //used to read "enable_element_wise_add" buffer flag
        .input_reg_file             (pre_compute_latched_reg_file), // this gets latched locally, to ensure proper control. 
        .output_reg_file            (compute_latched_reg_file),
        .streamed_data              (streamed_data),
        .decoded_data               (decoded_data),
        .computation_ctrl           (computation_ctrl),
        .compute_data               (compute_data),
        .o_output_array             (output_array),
        .o_output_address           (output_address),
        .o_output_valid             (output_valid),
        .o_output_line_stored       (o_output_line_stored),
        .*
     );
    
    always_comb begin 
        debug_last_column       = decoded_data.last_column;

        debug_0_data              = decoded_data.data[0]; 
        debug_0_toggled_column    = decoded_data.toggled_column[0];
        debug_0_channel           = decoded_data.channel[0];
        debug_0_relative_row      = decoded_data.relative_row[0];
        debug_0_valid             = decoded_data.valid[0];
        debug_0_ready             = decoded_data.ready[0];

        debug_1_data              = decoded_data.data[1]; 
        debug_1_toggled_column    = decoded_data.toggled_column[1];
        debug_1_channel           = decoded_data.channel[1];
        debug_1_relative_row      = decoded_data.relative_row[1];
        debug_1_valid             = decoded_data.valid[1];
        debug_1_ready             = decoded_data.ready[1];

        debug_2_data              = decoded_data.data[2]; 
        debug_2_toggled_column    = decoded_data.toggled_column[2];
        debug_2_channel           = decoded_data.channel[2];
        debug_2_relative_row      = decoded_data.relative_row[2];
        debug_2_valid             = decoded_data.valid[2];
        debug_2_ready             = decoded_data.ready[2];

    end

endmodule
