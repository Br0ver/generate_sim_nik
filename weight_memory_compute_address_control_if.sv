/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Weight Memory and Compute Address Control Interface
*   Date:   19.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface weight_memory_compute_address_control_if #(
    parameter int WEIGHT_BANK_DEPTH           = 8,
    parameter int WEIGHT_BANK_BIT_WIDTH       = 8,
    parameter int WEIGHT_BUFFER_BANK_COUNT      = 8,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW   = 8
)();
    logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                      compute_address [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_data [NUMBER_OF_PE_ARRAYS_PER_ROW];

    modport control (output compute_address, input weight_data);
    modport memory  (input  compute_address, output weight_data);
endinterface