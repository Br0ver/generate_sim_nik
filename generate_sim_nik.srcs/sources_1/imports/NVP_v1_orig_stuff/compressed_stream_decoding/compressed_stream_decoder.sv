/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Compressed Stream Decoder
*   Date:   15.11.2021
*   Author: hasan
*   Description: This module instantiates the stream reader fsm and connects it to the corresponding FSM.  
*/

`timescale 1ns / 1ps

module compressed_stream_decoder #(   
    parameter int ACTIVATION_BIT_WIDTH          = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int ACTIVATION_BANK_BIT_WIDTH   = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT  = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int CHANNEL_VALUE_BIT_WIDTH       = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int COLUMN_VALUE_BIT_WIDTH        = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ROW_VALUE_BIT_WIDTH           = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,
    parameter int REGISTER_WIDTH                = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS           = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int CHANNELS_MINUS_8_REGISTER     = NVP_v1_constants::CHANNELS_MINUS_8_REGISTER,
    parameter int CONTROL_FLAGS_REGISTER        = NVP_v1_constants::CONTROL_FLAGS_REGISTER,
    parameter int STREAM_RELATIVE_ROW_MSB        = NVP_v1_constants::STREAM_RELATIVE_ROW_MSB,
    parameter int STREAM_RELATIVE_ROW_LSB        = NVP_v1_constants::STREAM_RELATIVE_ROW_LSB,
    parameter int SUPPORTED_MAX_NUMBER_OF_COLUMNS         = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_COLUMNS
)(
    input logic                                                                 clk,
    input logic                                                                 resetn,
    input logic                                                                 i_global_synchronization_resume,
    input logic [REGISTER_WIDTH-1:0]                                            i_reg_file_number_of_channels_minus_8,
    input logic [REGISTER_WIDTH-1:0]                                            i_reg_file_number_of_conv_layer_columns,
    input logic [REGISTER_WIDTH-1:0]                                            i_reg_file_stream_ptr,
    input logic                                                                 i_reg_file_start_stream_readers,
    input  logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]   i_stream_read_data,
    input  logic                                                                i_stream_read_valid,
    output logic                                                                o_stream_read_ready,
    output logic [ACTIVATION_BIT_WIDTH-1:0]                                     o_decoded_data_word,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]                                   o_decoded_word_toggled_column,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0]                                  o_decoded_word_channel,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]                                      o_decoded_word_relative_row,
    output logic                                                                o_decoded_word_valid,
    input  logic                                                                i_decoded_word_ready,
    output logic                                                                o_ctrl_last_column
);

    // logic [CHANNEL_VALUE_BIT_WIDTH-1:0] reg_file_number_of_channels_minus_8;
    // always_comb reg_file_number_of_channels_minus_8 = i_reg_file_number_of_channels_minus_8[CHANNEL_VALUE_BIT_WIDTH-1:0];

    // logic [$clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS)-1:0] reg_file_number_of_conv_layer_columns;
    // always_comb reg_file_number_of_conv_layer_columns = i_reg_file_number_of_conv_layer_columns[$clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS)-1:0];

    // logic start_stream_readers;
    // always_comb start_stream_readers = i_reg_file_start_stream_readers; 
    logic stream_read_ready;
    // always_comb o_stream_read_ready = stream_read_ready & i_reg_file_start_stream_readers & i_decoded_word_ready; // TODO:: check me. probably nned to change the i_reg with the ff signal instead of the flag signal.
    always_comb o_stream_read_ready = stream_read_ready && i_decoded_word_ready; 

    compressed_stream_decoder_fsm #(   
        .ACTIVATION_BIT_WIDTH               (ACTIVATION_BIT_WIDTH),
        .ACTIVATION_BANK_BIT_WIDTH        (ACTIVATION_BANK_BIT_WIDTH),
        .ACTIVATION_BUFFER_BANK_COUNT       (ACTIVATION_BUFFER_BANK_COUNT),
        .CHANNEL_VALUE_BIT_WIDTH            (CHANNEL_VALUE_BIT_WIDTH),
        .COLUMN_VALUE_BIT_WIDTH             (COLUMN_VALUE_BIT_WIDTH),
        .ROW_VALUE_BIT_WIDTH                (ROW_VALUE_BIT_WIDTH),
        .SUPPORTED_MAX_NUMBER_OF_COLUMNS    (SUPPORTED_MAX_NUMBER_OF_COLUMNS)
    ) compressed_stream_decoder_fsm_1 (
        .clk                                    (clk),
        .resetn                                 (resetn),
        .i_global_synchronization_resume        (i_global_synchronization_resume),
        .i_reg_file_number_of_channels_minus_8  (i_reg_file_number_of_channels_minus_8[CHANNEL_VALUE_BIT_WIDTH-1:0]),
        .i_reg_file_number_of_conv_layer_columns(i_reg_file_number_of_conv_layer_columns[$clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS)-1:0]),
        .i_reg_file_start_stream_readers        (i_reg_file_start_stream_readers),
        .i_reg_file_stream_ptr_relative_row     (i_reg_file_stream_ptr[STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]),
        .i_stream_read_data                     (i_stream_read_data),
        .i_stream_read_valid                    (i_stream_read_valid),
        .o_stream_read_ready                    (stream_read_ready),
        .o_decoded_data_word                    (o_decoded_data_word),
        .o_decoded_word_toggled_column          (o_decoded_word_toggled_column),
        .o_decoded_word_channel                 (o_decoded_word_channel),
        .o_decoded_word_relative_row            (o_decoded_word_relative_row),
        .o_decoded_word_valid                   (o_decoded_word_valid),
        .i_decoded_word_ready                   (i_decoded_word_ready),
        .o_ctrl_last_column                     (o_ctrl_last_column)
    );


    
endmodule



