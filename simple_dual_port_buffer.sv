/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  axis fifo
*   Date:  05.11.2021
*   Author: ... 
*   Description: adapted from EdgeDRNN code. 
*/

/******************************
 * bram_sdp.sv
 ******************************/
/* FUNCTION:
 * Block RAM in SDP mode
 *
 * VERSION DESCRIPTION:
 * V1.0
 */
`timescale 1ns/1ps
//`define SIM_DEBUG

module bram_sdp #(
    parameter BRAM_DATA_BIT_WIDTH = 32,
    parameter BRAM_DEPTH = 64
)(
    input  logic                            clk,
    input  logic                            ena,
    input  logic                            wea,
    input  logic [$clog2(BRAM_DEPTH)-1:0]   addra,
    input  logic [BRAM_DATA_BIT_WIDTH-1:0]  dia,
    input  logic                            enb,
    input  logic [$clog2(BRAM_DEPTH)-1:0]   addrb,
    output logic [BRAM_DATA_BIT_WIDTH-1:0]  dob
);
   
    // Memory
    (* ram_style = "block" *)  logic signed [BRAM_DATA_BIT_WIDTH-1:0] mem_data [BRAM_DEPTH-1:0];
        
    // port a
    always_ff @ (posedge clk) begin
        if (ena) begin
            if(wea) begin
                mem_data[addra] <= dia;
            end
        end
    end

        
    // port b
    always_ff @ (posedge clk) begin
        if (enb) begin
            dob <= mem_data[addrb];
        end
    end

endmodule