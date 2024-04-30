/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Control Memory (Register file)
*   Date:   09.11.2021
*   Author: hasan
*   Description: Uses axis_mem to build the input buffers. The stream pointers point at the memory address where lines start.
*/


`timescale 1ns / 1ps

module control_memory #(   
    parameter int REGISTER_WIDTH        = 32,
    parameter int NUMBER_OF_REGISTERS   = 10,
    parameter int AXI_DATA_WIDTH        = NVP_v1_constants::CONTROL_AXI_DATA_WIDTH,
    parameter int AXI_ADDR_WIDTH        = NVP_v1_constants::CONTROL_AXI_ADDR_WIDTH
)(
    input logic                         clk,
    input logic                         resetn,
    s_axi_lite_bus                      i_control_bus,
    input [REGISTER_WIDTH-1:0]          i_output_line_end_address,
    output logic [REGISTER_WIDTH-1:0]   o_register_file [0:NUMBER_OF_REGISTERS-1]
);

    

    // --------------------------------------
    // ------ Signal Definitions
	// --------------------------------------
    // Register file signals
    logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];
    logic                                       register_file_write_enable;
    logic[AXI_DATA_WIDTH/8-1:0] register_file_write_strobes; // Write strobes are byte wise
    logic[AXI_DATA_WIDTH-1:0]   register_file_write_data;
    logic[AXI_ADDR_WIDTH-$clog2(AXI_DATA_WIDTH/8)-1:0]   register_file_write_address; // Addresses one word, even though AXI addresses bytes (the address is converted)
    logic[AXI_ADDR_WIDTH-$clog2(AXI_DATA_WIDTH/8)-1:0]   register_file_read_address;
    logic[AXI_DATA_WIDTH-1:0]   register_file_read_data;


    // --------------------------------------
    // ------ Register File
	// --------------------------------------
    axi_register_file_fsm #(
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH)
    ) input_memory_bridge (
        .axi_bus            (i_control_bus),
        .ol_write_enable    (register_file_write_enable),
        .ol_write_strobes   (register_file_write_strobes),
        .ol_data            (register_file_write_data),
        .ol_write_address   (register_file_write_address),
        .il_data            (register_file_read_data),
        .ol_read_address    (register_file_read_address)
    );               
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
                // register_file[i] <= {REGISTER_WIDTH{1'b0}};
                register_file[i] <= '0;
            end                      
        end
        else begin
            if(register_file_write_enable) begin
                register_file[register_file_write_address] <= register_file_write_data;
            end                          

            register_file_read_data <= i_output_line_end_address;
        end                                                                                                                                  
    end

    always_comb o_register_file = register_file;

   
endmodule
