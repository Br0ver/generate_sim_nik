/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Single Port Buffer
*   Date:   09.11.2019
*   Author: hasan
*   Description:  Buffer for Xilinx FPGAs.
*/



`timescale 1ns / 1ps


module single_port_buffer #(
    parameter int BUFFER_WIDTH = 64,
    parameter int BUFFER_DEPTH = 1024
)(
    input  logic                             clk,
    input  logic[BUFFER_WIDTH-1:0]           data_in,
    input  logic                             en,
    // input  logic                             we,
    input  logic[BUFFER_WIDTH/8-1:0]         byte_en,
    input  logic[$clog2(BUFFER_DEPTH)-1:0]   address_in,
    output logic[BUFFER_WIDTH-1:0]           data_out
);
    
    (* ram_style = "block" *) logic[BUFFER_WIDTH-1:0] memory[0:BUFFER_DEPTH-1];
    
    // always_ff @(posedge clk)
    // begin
    //     if(en) begin
    //         if (we) begin
    //             memory[address_in] <= data_in;
    //         end
    //         data_out <= memory[address_in];
    //     end
    // end
   
    generate
        for(genvar i = 0; i < BUFFER_WIDTH/8; i++) begin
            always_ff @(posedge clk)
            begin
                if(en) begin
                    data_out[i*8 +: 8] <= memory[address_in][i*8 +: 8];
                    
                    if(byte_en[i]) begin
                        memory[address_in][i*8 +: 8] <= data_in[i*8 +: 8];
                    end
                end
            end
        end
    endgenerate


endmodule

