/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Line Buffer
*   Date:   01.12.2021
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

module activation_line_buffer #(   
    parameter int ACTIVATION_BANK_BIT_WIDTH        = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH            = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH,  
    parameter int ACTIVATION_BUFFER_BANK_COUNT       = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT
)(
    input logic                                                                 clk,
    input logic                                                                 resetn,
    input  logic[ACTIVATION_BANK_BIT_WIDTH-1:0]                               i_activation_buffer_data_in,
    input  logic                                                                i_activation_buffer_write_port_en,
    input  logic[ACTIVATION_BUFFER_BANK_COUNT-1:0]                              i_activation_buffer_write_enable,
    input  logic[$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]                           i_activation_buffer_address_in_bus,
    input  logic[$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]                           i_activation_buffer_address_in_compute,
    output logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]  o_activation_buffer_data_out
);
  
    logic[ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]         data_in; 
    
    always_comb begin
        // data in
        // broadcast axis data. write_enable will only enable the correct column/bank.
        for (int i=0; i<ACTIVATION_BUFFER_BANK_COUNT; i++) begin
            data_in[(i+1)*ACTIVATION_BANK_BIT_WIDTH-1 -:ACTIVATION_BANK_BIT_WIDTH] = i_activation_buffer_data_in;
        end
    end


    // generate
    //     bram_sdp_byte_write #(   
    //         .DEPTH              (ACTIVATION_LINE_BUFFER_DEPTH),
    //         .COLUMN_WIDTH       (ACTIVATION_BANK_BIT_WIDTH), // "COLUMN_WIDTH" is the smallest write enable byte-wide granularity
    //         .NUMBER_OF_COLUMNS  (ACTIVATION_BUFFER_BANK_COUNT)
    //     ) buffer_bank (
    //         .clk    (clk),
    //         .ena    (i_activation_buffer_write_port_en), 
    //         .enb    ('1), //TODO:: fixme: add separate enable signals?
    //         .wea    (i_activation_buffer_write_enable),
    //         .addra  (i_activation_buffer_address_in_bus),
    //         .addrb  (i_activation_buffer_address_in_compute),
    //         .dina   (data_in),
    //         // .dina   (data_in_ff),
    //         .doutb  (o_activation_buffer_data_out)
    //     );
    // endgenerate

    // Xilinx FPGA: byte width (64) is too high. Maximum supported byte width = 32 (data_only) or 36 (data + parity)
    localparam int COLUMN_WIDTH = 32;
    localparam int RATIO        = ACTIVATION_BANK_BIT_WIDTH/COLUMN_WIDTH;
    localparam int NUMBER_OF_COLUMNS = ACTIVATION_BUFFER_BANK_COUNT*RATIO;
    logic [NUMBER_OF_COLUMNS-1:0] wea; //<=> i_activation_buffer_write_enable
    always_comb begin
        for (int i=0; i<NUMBER_OF_COLUMNS; i++) begin
            wea[i] = i_activation_buffer_write_enable[i/RATIO];
        end
    end


    // single bank width = AXI_WIDTH
    // number of banks = PES_PER_ARRAY*ACTIVATION_WIDTH/AXI_WIDTH
    // ____________________________________________
    //|                                  | bank 1  | AXI_WIDTH=128 |
    //|                                  |_________|_______________|
    //|                                  | bank 2  | AXI_WIDTH=128 |  
    //|a single activation line buffer   |_________|_______________| a single PE_ARRAY word = 512 -> goes to a single stream reader
    //|                                  | bank 3  | AXI_WIDTH=128 |
    //|                                  |_________|_______________|
    //|                                  | bank 4  | AXI_WIDTH=128 |
    //|__________________________________|_________|               |

    generate
        bram_sdp_byte_write #(   
            .DEPTH              (ACTIVATION_LINE_BUFFER_DEPTH),
            .COLUMN_WIDTH       (COLUMN_WIDTH), // "COLUMN_WIDTH" is the smallest write enable byte-wide granularity
            .NUMBER_OF_COLUMNS  (NUMBER_OF_COLUMNS)
        ) buffer_bank (
            .clk    (clk),
            .ena    (i_activation_buffer_write_port_en), 
            .enb    ('1), //TODO:: fixme: add separate enable signals?
            .wea    (wea),
            .addra  (i_activation_buffer_address_in_bus),
            .addrb  (i_activation_buffer_address_in_compute),
            .dina   (data_in),
            // .dina   (data_in_ff),
            .doutb  (o_activation_buffer_data_out)
        );
    endgenerate



     
endmodule
