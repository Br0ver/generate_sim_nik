/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Buffer and Weight buffer interface
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface axis_to_weight_memory_if#(
    parameter int AXIS_BUS_BIT_WIDTH	    = 64
)();
    logic [AXIS_BUS_BIT_WIDTH-1 : 0]    data;
    logic                               valid;
    logic                               last;
    logic                               ready;
    
    modport master         (output data, valid, last, input ready);
    modport slave          (output data, valid, last, input ready);

    // modport control         (output data, valid, last, input ready);
    // modport weight_memory   (input  data, valid, last, output ready);
endinterface
