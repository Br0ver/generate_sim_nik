/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Control and Compressed Stream Decoder interface
*   Date:   14.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface control_and_stream_decoder_if();
    logic last_column_flag_and;
    logic last_column_flag_nor;

    modport master     (output last_column_flag_and, last_column_flag_nor);
    modport slave     (input last_column_flag_and, last_column_flag_nor);
    // modport pre_compute (input last_column_flag_and, last_column_flag_nor);
endinterface
