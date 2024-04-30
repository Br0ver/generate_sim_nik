/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Banked Line Buffer
*   Date:   16.02.2022
*   Author: hasan
*   Description: 
*/

    // single bank width = AXI_WIDTH
    // number of banks = PES_PER_ARRAY*ACTIVATION_WIDTH/AXI_WIDTH
    //
    // Example: 
    // ____________________________________________
    //|                                  | bank 1  | AXI_WIDTH=128 |
    //|                                  |_________|_______________|
    //|                                  | bank 2  | AXI_WIDTH=128 |  
    //|a single activation line buffer   |_________|_______________| a single PE_ARRAY word = 512 -> goes to a single stream reader
    //|                                  | bank 3  | AXI_WIDTH=128 |
    //|                                  |_________|_______________|
    //|                                  | bank 4  | AXI_WIDTH=128 |
    //|__________________________________|_________|               |


`timescale 1ns / 1ps

module banked_line_buffer #(   
    parameter int BANK_BIT_WIDTH    = 64,
    parameter int BANK_COUNT        = 4,
    parameter int BANK_DEPTH        = 128  
)(
    input  logic                                clk,
    input  logic                                i_write_port_en,
    input  logic[BANK_COUNT-1:0]                i_write_port_wen,
    input  logic[$clog2(BANK_DEPTH)-1:0]        i_write_port_addr,
    input  logic[BANK_BIT_WIDTH-1:0]            i_write_port_data_in,
    input  logic                                i_read_port_en,
    input  logic[$clog2(BANK_DEPTH)-1:0]        i_read_port_addr,
    output logic[BANK_BIT_WIDTH*BANK_COUNT-1:0] o_read_port_data_out
);

    logic [BANK_BIT_WIDTH-1:0] read_port_data_out [BANK_COUNT];
    always_comb begin
        // for (int i=0; i<BANK_COUNT; i++) begin
        //     o_read_port_data_out[(i+1)*BANK_BIT_WIDTH-1 -: BANK_BIT_WIDTH] = read_port_data_out[i];
        // end
        for (int i=0; i<BANK_COUNT; i++) begin
            o_read_port_data_out[(i+1)*BANK_BIT_WIDTH-1 -: BANK_BIT_WIDTH] = read_port_data_out[BANK_COUNT-1-i];
        end
    end
  
    generate
        for (genvar i=0; i<BANK_COUNT; i++) begin
              (* ram_style = "block" *)
            bram_sdp #(
                .BRAM_DATA_BIT_WIDTH    (BANK_BIT_WIDTH),
                .BRAM_DEPTH             (BANK_DEPTH)
            ) bank_i (
                .clk    (clk),
                .ena    (i_write_port_en),
                .wea    (i_write_port_wen[i]),
                .addra  (i_write_port_addr),
                .dia    (i_write_port_data_in),
                .enb    (i_read_port_en),
                .addrb  (i_read_port_addr),
                .dob    (read_port_data_out[i])
            );
        end
    endgenerate

     
endmodule
