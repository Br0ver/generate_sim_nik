/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Control and Weight Buffer units interface
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface weight_buffer_control_if#(
    parameter int WEIGHT_BANK_BIT_WIDTH	                = 64,
    parameter int WEIGHT_BUFFER_BANK_COUNT	            = 8,
    parameter int WEIGHT_LINE_BUFFER_DEPTH	            = 512,
    parameter int NUMBER_OF_WEIGHT_LINE_BUFFERS	        = 6,
    parameter int BIAS_LINE_BUFFER_DEPTH                = 32,
    parameter int BIAS_BUFFER_BANK_COUNT	            = 4,
    parameter int BIAS_BANK_BIT_WIDTH                   = 64
)();
    logic                                                     write_port_enable  [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    logic[WEIGHT_BANK_BIT_WIDTH-1:0]                          write_port_data_in [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    logic[WEIGHT_BUFFER_BANK_COUNT-1:0]                       write_port_wen     [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    logic[$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]               write_port_addr    [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    logic[$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]               read_port_addr     [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] read_port_data_out [NUMBER_OF_WEIGHT_LINE_BUFFERS];


    logic[BIAS_BANK_BIT_WIDTH-1:0]                          bias_write_port_data_in;
    logic[$clog2(BIAS_LINE_BUFFER_DEPTH)-1:0]               bias_write_port_addr;
    logic[BIAS_BUFFER_BANK_COUNT-1:0]                       bias_write_port_wen;
    logic                                                   bias_write_port_enable;
    logic[$clog2(BIAS_LINE_BUFFER_DEPTH)-1:0]               bias_read_port_addr;
    logic[BIAS_BANK_BIT_WIDTH*BIAS_BUFFER_BANK_COUNT-1:0]   bias_read_port_data_out;

    modport master (output write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, input  read_port_data_out);
    modport slave (input write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, output  read_port_data_out);

    // modport control (output write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, input  read_port_data_out);
    // modport buffer  (input  write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, output read_port_data_out);
endinterface
