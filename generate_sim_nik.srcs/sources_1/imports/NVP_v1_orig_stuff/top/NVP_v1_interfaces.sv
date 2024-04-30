/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Accelerator Interfaces
*   Date:  05.11.2021
*   Author: hasan
*   Description: All top level interfaces definitions.
*/

`timescale 1ns / 1ps


import NVP_v1_constants::*;
import NVP_v1_constants::*;


interface decoded_word_if#(
    parameter int INPUT_DATA_BIT_WIDTH      = 8,
    parameter int CHANNEL_VALUE_BIT_WIDTH   = 7,
    parameter int COLUMN_VALUE_BIT_WIDTH    = 2,
    parameter int ROW_VALUE_BIT_WIDTH       = 2
    );
    logic [INPUT_DATA_BIT_WIDTH-1:0] decoded_data_word;
    logic [COLUMN_VALUE_BIT_WIDTH-1:0] decoded_word_toggled_column;
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0] decoded_word_channel;
    logic [ROW_VALUE_BIT_WIDTH-1:0] decoded_word_relative_row;

    modport stream_reader(output decoded_data_word, decoded_word_toggled_column, decoded_word_channel, decoded_word_relative_row);
    modport arbiter(input decoded_data_word, decoded_word_toggled_column, decoded_word_channel, decoded_word_relative_row);
endinterface


interface npp_fifo_ff_if#(parameter WORD_NUM_BITS = 128);
    logic[WORD_NUM_BITS-1:0] input_word;
    logic input_valid;
    logic input_enable;
    logic[WORD_NUM_BITS-1:0] output_word;
    logic output_valid;
    logic output_enable;


    modport fifo(input input_word,input_valid,output_enable, output output_word, input_enable,output_valid);
    modport read_requestor(input output_word, output_valid, output output_enable);
    modport write_requestor(input input_enable, output input_valid, input_word);
endinterface

interface pe_group_weight_memory_if#(parameter WORD_NUM_BITS = 128);
    logic[WORD_NUM_BITS-1:0] input_word;
    logic input_valid;
    logic input_enable;
    logic[WORD_NUM_BITS-1:0] output_word;
    logic output_valid;
    logic output_enable;


    modport fifo(input input_word,input_valid,output_enable, output output_word, input_enable,output_valid);
    modport read_requestor(input output_word, output_valid, output output_enable);
    modport write_requestor(input input_enable, output input_valid, input_word);
endinterface