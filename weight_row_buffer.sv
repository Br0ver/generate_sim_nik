/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Weight row buffer
*   Date:   30.11.2021
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module weight_row_buffer #(   
    parameter int WEIGHT_BANK_BIT_WIDTH       = 64,
    parameter int WEIGHT_BANK_DEPTH           = 512,
    parameter int WEIGHT_BUFFER_BANK_COUNT      = 16,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW   = 3
)(
    input  logic                                                        clk,
    input  logic                                                        resetn,
    input  logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0]  i_weight_memory_data_in,
    input  logic[NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                       i_weight_memory_en,
    input  logic[WEIGHT_BUFFER_BANK_COUNT-1:0]                          i_weight_memory_write_enable,
    input  logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                       i_weight_memory_bus_address_in,
    input  logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                       i_weight_memory_compute_address_in [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0]  o_weight_memory_data_out [NUMBER_OF_PE_ARRAYS_PER_ROW]
);

    generate
        for (genvar i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            // bram_sdp_byte_write #(   
            //     .DEPTH              (WEIGHT_BANK_DEPTH),
            //     .COLUMN_WIDTH       (WEIGHT_BANK_BIT_WIDTH), 
            //     .NUMBER_OF_COLUMNS  (WEIGHT_BUFFER_BANK_COUNT)
            // ) buffer_array (
            //     .clk    (clk),
            //     .ena    (i_weight_memory_en[i]), // write port enable
            //     .wea    (i_weight_memory_write_enable),
            //     .addra  (i_weight_memory_bus_address_in),
            //     .dina   (i_weight_memory_data_in),
            //     .enb    ('1), // read port enable signal //TODO:: fixme: add enable signals.
            //     .addrb  (i_weight_memory_compute_address_in[i]),
            //     .doutb  (o_weight_memory_data_out[i])
            // );
            banked_line_buffer #(   
                .BANK_BIT_WIDTH    (WEIGHT_BANK_BIT_WIDTH),
                .BANK_COUNT        (WEIGHT_BUFFER_BANK_COUNT),
                .BANK_DEPTH        (WEIGHT_BANK_DEPTH)
            ) weight_buffer_i (
                .clk                    (clk),    
                .i_write_port_en        (i_weight_memory_en[i]),                
                .i_write_port_wen       (i_weight_memory_write_enable),                
                .i_write_port_addr      (i_weight_memory_bus_address_in),                
                .i_write_port_data_in   (i_weight_memory_data_in[WEIGHT_BANK_BIT_WIDTH-1:0]),                    
                .i_read_port_en         ('{default:1}),            
                .i_read_port_addr       (i_weight_memory_compute_address_in[i]),                
                .o_read_port_data_out   (o_weight_memory_data_out[i])                       
            );
        end
    endgenerate


    // // Xilinx FPGA: byte width (64) is too high. Maximum supported byte width = 32 (data_only) or 36 (data + parity)
    // localparam int COLUMN_WIDTH = 32;
    // localparam int RATIO        = WEIGHT_BANK_BIT_WIDTH/COLUMN_WIDTH;
    // localparam int NUMBER_OF_COLUMNS = WEIGHT_BUFFER_BANK_COUNT*RATIO;
    // logic [NUMBER_OF_COLUMNS-1:0] wea; //<=> i_weight_memory_write_enable
    // always_comb begin
    //     for (int i=0; i<NUMBER_OF_COLUMNS; i++) begin
    //         wea[i] = i_weight_memory_write_enable[i/RATIO];
    //     end
    // end
    // generate
    //     for (genvar i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
    //         bram_sdp_byte_write #(   
    //             .DEPTH              (WEIGHT_BANK_DEPTH),
    //             .COLUMN_WIDTH       (COLUMN_WIDTH), 
    //             .NUMBER_OF_COLUMNS  (NUMBER_OF_COLUMNS)
    //         ) buffer_array (
    //             .clk    (clk),
    //             .ena    (i_weight_memory_en[i]), // write port enable
    //             .enb    ('1), // read port enable signal //TODO:: fixme: add enable signals.
    //             .wea    (wea),
    //             .addra  (i_weight_memory_bus_address_in),
    //             .addrb  (i_weight_memory_compute_address_in[i]),
    //             .dina   (i_weight_memory_data_in),
    //             .doutb  (o_weight_memory_data_out[i])
    //         );
    //     end
    // endgenerate

endmodule
