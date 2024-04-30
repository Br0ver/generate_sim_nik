/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Data moving interfaces
*   Date:   14.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface streamed_data_if #(
    parameter int NUMBER_OF_READ_STREAMS	    = 32,
    parameter int ACTIVATION_BANK_BIT_WIDTH	= 32,
    parameter int ACTIVATION_BUFFER_BANK_COUNT	= 32
)();
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1 : 0] data  [NUMBER_OF_READ_STREAMS];
    logic                                                                  valid [NUMBER_OF_READ_STREAMS];
    logic                                                                  ready [NUMBER_OF_READ_STREAMS];
    logic                                                                  ready_from_stream_decoders [NUMBER_OF_READ_STREAMS];
    logic                                                                  ready_from_pre_compute  [NUMBER_OF_READ_STREAMS];

    modport master   (output data, valid, input ready, ready_from_stream_decoders, ready_from_pre_compute);
    modport slave    (input  data, valid, output ready, ready_from_stream_decoders, ready_from_pre_compute);

    // modport activation_buffer   (output data, valid, ready, input ready_from_stream_decoders, ready_from_pre_compute);
    // modport stream_decoder      (input  data, valid, output ready_from_stream_decoders);
    // modport pre_compute         (input  data, valid, output ready_from_pre_compute);
    // modport compute             (input  data, valid);
endinterface

interface decoded_data_if #(
    parameter int NUMBER_OF_READ_STREAMS	= 32,
    parameter int ACTIVATION_BIT_WIDTH	    = 32,
    parameter int COLUMN_VALUE_BIT_WIDTH	= 32,
    parameter int CHANNEL_VALUE_BIT_WIDTH   = 32,
    parameter int ROW_VALUE_BIT_WIDTH       = 32
)();
    logic [ACTIVATION_BIT_WIDTH-1:0]    data           [NUMBER_OF_READ_STREAMS];
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  toggled_column [NUMBER_OF_READ_STREAMS];
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0] channel        [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS-1:0]  last_column;
    logic [ROW_VALUE_BIT_WIDTH-1:0]     relative_row   [NUMBER_OF_READ_STREAMS];
    logic                               valid          [NUMBER_OF_READ_STREAMS];
    logic                               ready          [NUMBER_OF_READ_STREAMS];

    modport master  (output data, toggled_column, channel, relative_row, valid, last_column, input  ready);
    modport slave   (input  data, toggled_column, channel, relative_row, valid, last_column, output ready);

    // modport stream_decoder  (output data, toggled_column, channel, relative_row, valid, last_column, input ready);
    // modport pre_compute     (input  data, toggled_column, channel, relative_row, valid, last_column, output ready);
    // modport compute         (input  data, toggled_column, channel, relative_row, valid, last_column);
endinterface

interface compute_core_data_if #(
    parameter int COMBINED_DATA_BIT_WIDTH       = 32,
    parameter int ACTIVATION_BANK_BIT_WIDTH   = 32,
    parameter int ACTIVATION_BUFFER_BANK_COUNT  = 32,
    parameter int WEIGHT_BANK_BIT_WIDTH       = 32,
    parameter int WEIGHT_BANK_DEPTH       = 32,
    parameter int WEIGHT_BUFFER_BANK_COUNT      = 32,
    parameter int NUMBER_OF_READ_STREAMS        = 32,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW   = 32
)();
    logic[COMBINED_DATA_BIT_WIDTH-1:0]                                      sparse_data;
    logic                                                                   sparse_data_valid;
    logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                                    sparse_buffered_weight_address;
    logic                                                                   sparse_ready;

    logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1 : 0]     dense_data [NUMBER_OF_READ_STREAMS];
    logic                                                                   dense_data_valid [NUMBER_OF_READ_STREAMS];
    logic                                                                   dense_ready [NUMBER_OF_READ_STREAMS];

    logic[COMBINED_DATA_BIT_WIDTH-1:0]                                      pw_data [NUMBER_OF_READ_STREAMS];
    logic                                                                   pw_data_valid [NUMBER_OF_READ_STREAMS];
    logic                                                                   pw_ready [NUMBER_OF_READ_STREAMS];

    logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]       activations [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0]               weights     [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                   valid       [NUMBER_OF_PE_ARRAYS_PER_ROW];
    // logic                                                                   ready;

    logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]     element_wise_add [NUMBER_OF_PE_ARRAYS_PER_ROW];

    modport master (output sparse_data, sparse_data_valid, dense_data, dense_data_valid, pw_data, pw_data_valid, activations, weights, valid, element_wise_add, sparse_ready, dense_ready, pw_ready);
    modport slave (input sparse_data, sparse_data_valid, dense_data, dense_data_valid, pw_data, pw_data_valid, activations, weights, valid, element_wise_add, sparse_ready, dense_ready, pw_ready);
    // modport compute     (input  activations, weights, valid, element_wise_add);
endinterface

