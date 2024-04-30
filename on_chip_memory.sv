/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Memory Unit
*   Date:   13.01.2022
*   Author: hasan
*   Description: Simplified version of buffer_unit_v1. Uses axis_mem to build the input buffers. The stream pointers point at the memory address where lines start.
*/

`timescale 1ns / 1ps

module on_chip_memory #(   
    parameter  ACTIVATION_BANK_BIT_WIDTH            = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter  ACTIVATION_LINE_BUFFER_DEPTH         = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH, 
    parameter  ACTIVATION_BUFFER_BANK_COUNT         = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter  NUMBER_OF_ACTIVATION_LINE_BUFFERS    = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    parameter  REGISTER_WIDTH                       = NVP_v1_constants::REGISTER_WIDTH,
    parameter  NUMBER_OF_REGISTERS                  = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter  STREAM_1_PTR_REGISTER                = NVP_v1_constants::STREAM_1_PTR_REGISTER,
    parameter  STREAM_2_PTR_REGISTER                = NVP_v1_constants::STREAM_2_PTR_REGISTER,
    parameter  STREAM_3_PTR_REGISTER                = NVP_v1_constants::STREAM_3_PTR_REGISTER,
    parameter  NUMBER_OF_READ_STREAMS               = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter  WEIGHT_AXI_BUS_BIT_WIDTH             = NVP_v1_constants::WEIGHT_AXI_BUS_BIT_WIDTH,
    parameter  WEIGHT_BANK_BIT_WIDTH                = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH,
    parameter  WEIGHT_LINE_BUFFER_DEPTH             = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter  WEIGHT_BUFFER_BANK_COUNT             = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter  NUMBER_OF_WEIGHT_LINE_BUFFERS        = NVP_v1_constants::NUMBER_OF_WEIGHT_LINE_BUFFERS,
    parameter  NUMBER_OF_PE_ARRAYS_PER_ROW          = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,
    parameter  OUTPUT_WRITER_ADDRESS_BIT_WIDTH      = NVP_v1_constants::OUTPUT_WRITER_ADDRESS_BIT_WIDTH,
    parameter  BIAS_LINE_BUFFER_DEPTH               = NVP_v1_constants::BIAS_LINE_BUFFER_DEPTH,
    parameter  BIAS_BUFFER_BANK_COUNT	            = NVP_v1_constants::BIAS_BUFFER_BANK_COUNT,
    parameter  BIAS_BANK_BIT_WIDTH                  = NVP_v1_constants::BIAS_BANK_BIT_WIDTH,
    localparam CONTROL_FLAGS_REGISTER               = NUMBER_OF_REGISTERS-1,
    localparam LINE_BUFFER_SELECTION_BIT_WIDTH      = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS),
    localparam SPARSE_MODE                          = NVP_v1_constants::SPARSE_MODE
)(
    input logic                                         clk,
    input logic                                         resetn,
    s_axi_bus                                           i_weight_bus,
    s_axi_bus                                           i_data_bus,
    register_file_if                                    reg_file,
    register_file_if                                    latched_reg_file,
    streamed_data_if                                    streamed_data,
    computation_control_if                              computation_ctrl,
    input logic [ACTIVATION_BANK_BIT_WIDTH-1:0]         i_output_array,
    input logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]   i_output_address,
    input logic                                         i_output_valid
);

    // ------ Instantiate interfaces
    activation_buffer_control_if #(
        .ACTIVATION_BANK_BIT_WIDTH	    (ACTIVATION_BANK_BIT_WIDTH),
        .ACTIVATION_BUFFER_BANK_COUNT	    (ACTIVATION_BUFFER_BANK_COUNT),
        .ACTIVATION_LINE_BUFFER_DEPTH            (ACTIVATION_LINE_BUFFER_DEPTH),
        .NUMBER_OF_ACTIVATION_LINE_BUFFERS	(NUMBER_OF_ACTIVATION_LINE_BUFFERS)
    ) activation_buffer_ctrl ();
    weight_buffer_control_if #(
        .WEIGHT_BANK_BIT_WIDTH	        (WEIGHT_BANK_BIT_WIDTH),
        .WEIGHT_BUFFER_BANK_COUNT	    (WEIGHT_BUFFER_BANK_COUNT),
        .WEIGHT_LINE_BUFFER_DEPTH       (WEIGHT_LINE_BUFFER_DEPTH),
        .NUMBER_OF_WEIGHT_LINE_BUFFERS  (NUMBER_OF_WEIGHT_LINE_BUFFERS),
        .BIAS_LINE_BUFFER_DEPTH         (BIAS_LINE_BUFFER_DEPTH),
        .BIAS_BUFFER_BANK_COUNT         (BIAS_BUFFER_BANK_COUNT),
        .BIAS_BANK_BIT_WIDTH            (BIAS_BANK_BIT_WIDTH)
    ) weight_buffer_ctrl ();
    
    // --------------------------------------
    // ------ Activation memory
	// --------------------------------------
    activation_memory #(
        .ACTIVATION_BANK_BIT_WIDTH        (ACTIVATION_BANK_BIT_WIDTH),
        .ACTIVATION_LINE_BUFFER_DEPTH            (ACTIVATION_LINE_BUFFER_DEPTH),
        .ACTIVATION_BUFFER_BANK_COUNT       (ACTIVATION_BUFFER_BANK_COUNT),
        .NUMBER_OF_ACTIVATION_LINE_BUFFERS  (NUMBER_OF_ACTIVATION_LINE_BUFFERS)
    ) activation_memory_unit (
        .clk                    (clk),
        .activation_buffer_ctrl (activation_buffer_ctrl)
    );

    // --------------------------------------
    // ------ Activation buffer read control
	// --------------------------------------
    // ------ set "ready" signal based on execution mode (SPARSE vs DENSE). 
    always_comb begin
        for (int i=0;i<NUMBER_OF_READ_STREAMS; i++) begin
            streamed_data.ready[i] = (latched_reg_file.stream_mode==SPARSE_MODE)? streamed_data.ready_from_stream_decoders[i] : streamed_data.ready_from_pre_compute[i];
        end
    end
    activation_buffer_read_control #(   
        .REGISTER_WIDTH                     (REGISTER_WIDTH),
        .NUMBER_OF_REGISTERS                (NUMBER_OF_REGISTERS),
        .ACTIVATION_BANK_BIT_WIDTH        (ACTIVATION_BANK_BIT_WIDTH),
        .ACTIVATION_LINE_BUFFER_DEPTH            (ACTIVATION_LINE_BUFFER_DEPTH),
        .ACTIVATION_BUFFER_BANK_COUNT       (ACTIVATION_BUFFER_BANK_COUNT),
        .NUMBER_OF_ACTIVATION_LINE_BUFFERS  (NUMBER_OF_ACTIVATION_LINE_BUFFERS),
        .NUMBER_OF_READ_STREAMS             (NUMBER_OF_READ_STREAMS)
    ) activation_buffer_read_control_unit (
        .clk                        (clk),
        .resetn                     (resetn),
        .i_data_bus                 (i_data_bus),
        .latched_reg_file           (latched_reg_file),
        .activation_buffer_ctrl     (activation_buffer_ctrl),
        .streamed_data              (streamed_data)
    );

    // --------------------------------------
    // ------ Activation buffer write control
	// --------------------------------------
    activation_buffer_write_control #(   
        .REGISTER_WIDTH                     (REGISTER_WIDTH),
        .NUMBER_OF_REGISTERS                (NUMBER_OF_REGISTERS),
        .ACTIVATION_BANK_BIT_WIDTH          (ACTIVATION_BANK_BIT_WIDTH),            
        .ACTIVATION_LINE_BUFFER_DEPTH       (ACTIVATION_LINE_BUFFER_DEPTH),
        .ACTIVATION_BUFFER_BANK_COUNT       (ACTIVATION_BUFFER_BANK_COUNT),    
        .NUMBER_OF_ACTIVATION_LINE_BUFFERS  (NUMBER_OF_ACTIVATION_LINE_BUFFERS)        
    ) activation_buffer_write_control_unit (
        .clk                        (clk),
        .resetn                     (resetn),
        .i_data_bus                 (i_data_bus),
        // .i_weight_bus               (i_weight_bus),
        .reg_file                   (reg_file),
        .activation_buffer_ctrl     (activation_buffer_ctrl),
        .i_output_array             (i_output_array),                 
        .i_output_address           (i_output_address),                       
        .i_output_valid             (i_output_valid)                 
    );

    // --------------------------------------
    // ------ Weight memory 
	// --------------------------------------
    weight_memory #(
        .WEIGHT_BANK_BIT_WIDTH          (WEIGHT_BANK_BIT_WIDTH),                        
        .WEIGHT_LINE_BUFFER_DEPTH       (WEIGHT_LINE_BUFFER_DEPTH),    
        .WEIGHT_BUFFER_BANK_COUNT       (WEIGHT_BUFFER_BANK_COUNT),        
        .WEIGHT_AXI_BUS_BIT_WIDTH       (WEIGHT_AXI_BUS_BIT_WIDTH),
        .NUMBER_OF_WEIGHT_LINE_BUFFERS  (NUMBER_OF_WEIGHT_LINE_BUFFERS)  
    ) weight_memory_unit (
        .clk                                        (clk),
        .resetn                                     (resetn),
        .i_weight_bus                               (i_weight_bus),
        .i_reg_file_weight_buffer_address_offset    (latched_reg_file.weight_address_offset[$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]), 
        .weight_buffer_ctrl                         (weight_buffer_ctrl), 
        .computation_ctrl                           (computation_ctrl)
    );

endmodule