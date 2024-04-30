/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Control and Activation Buffer units interface
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps 

interface activation_buffer_control_if#(
    parameter int ACTIVATION_BANK_BIT_WIDTH	        = 64,
    parameter int ACTIVATION_BUFFER_BANK_COUNT	    = 8,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH	    = 512,
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS	= 6
)();
    logic                                                             write_port_enable  [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[ACTIVATION_BANK_BIT_WIDTH-1:0]                              write_port_data_in [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[ACTIVATION_BUFFER_BANK_COUNT-1:0]                           write_port_wen     [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]                   write_port_addr    [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]                   read_port_addr     [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0] read_port_data_out [NUMBER_OF_ACTIVATION_LINE_BUFFERS];

    modport master (output write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, input  read_port_data_out);
    modport slave (input write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, output  read_port_data_out);

    // modport control (output write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, input  read_port_data_out);
    // modport buffer  (input  write_port_enable, write_port_data_in, write_port_wen, write_port_addr, read_port_addr, output read_port_data_out);
endinterface
