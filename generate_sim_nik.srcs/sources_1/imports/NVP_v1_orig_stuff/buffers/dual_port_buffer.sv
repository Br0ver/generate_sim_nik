/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Dual Port Buffer
*   Date:   02.10.2019
*   Author: hasan
*   Description:  Buffer for Xilinx FPGAs implemented as read-first true dual-port BlockRAM with byte write enable.
*/



`timescale 1ns / 1ps



module dual_port_buffer #(
    parameter int BUFFER_WIDTH = 64,
    parameter int BUFFER_DEPTH = 1024
)(
    // Port A clock
    input logic clk_a,
    
    // Port A memory interface
    input logic[BUFFER_WIDTH-1:0]           il_data_a,
    input logic                             il_enable_a,
    input logic[BUFFER_WIDTH/8-1:0]         il_byte_write_enable_a,
    input logic[$clog2(BUFFER_DEPTH)-1:0]   il_address_a,
    
    output logic[BUFFER_WIDTH-1:0]          ol_data_a,
    
    // Port B clock
    input logic clk_b,
    
    // Port B memory interface
    input logic[BUFFER_WIDTH-1:0]           il_data_b,
    input logic                             il_enable_b,
    input logic[BUFFER_WIDTH/8-1:0]         il_byte_write_enable_b,
    input logic[$clog2(BUFFER_DEPTH)-1:0]   il_address_b,
    
    output logic[BUFFER_WIDTH-1:0]          ol_data_b
);
    
    (* ram_style = "block" *) logic[BUFFER_WIDTH-1:0] memory[0:BUFFER_DEPTH-1];
    
    generate
        genvar i;
        for(i = 0; i < BUFFER_WIDTH/8; i++) begin
            always_ff @(posedge clk_a)
            begin
                if(il_enable_a) begin
                    ol_data_a[i*8 +: 8] <= memory[il_address_a][i*8 +: 8];
                    
                    if(il_byte_write_enable_a[i]) begin
                        memory[il_address_a][i*8 +: 8] <= il_data_a[i*8 +: 8];
                    end
                end
            end
        end
    endgenerate
    
    generate
        for(i = 0; i < BUFFER_WIDTH/8; i++) begin
            always_ff @(posedge clk_b)
            begin
                if(il_enable_b) begin
                    ol_data_b[i*8 +: 8] <= memory[il_address_b][i*8 +: 8];
                    
                    if(il_byte_write_enable_b[i]) begin
                        memory[il_address_b][i*8 +: 8] <= il_data_b[i*8 +: 8];
                    end
                end
            end
        end
    endgenerate
endmodule

