/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: PW convolution data setup
*   Date:   10.02.2022
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

module pw_conv_data_setup #(   
    parameter int ACTIVATION_BIT_WIDTH      = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int CHANNEL_VALUE_BIT_WIDTH   = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int COLUMN_VALUE_BIT_WIDTH    = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ROW_VALUE_BIT_WIDTH       = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,
    parameter int COMBINED_DATA_FIFO_DEPTH  = NVP_v1_constants::COMBINED_DATA_FIFO_DEPTH,
    parameter int PE_DATA_FIFO_DEPTH        = NVP_v1_constants::PE_DATA_FIFO_DEPTH,
    parameter int PW_DATA_FIFO_DEPTH        = NVP_v1_constants::PW_DATA_FIFO_DEPTH,
    parameter int NUMBER_OF_READ_STREAMS    = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int NUMBER_OF_PE_ARRAYS       = NVP_v1_constants::NUMBER_OF_PE_ARRAYS,
    parameter int REGISTER_WIDTH            = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS       = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int WEIGHT_LINE_BUFFER_DEPTH       = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter int COMBINED_DATA_BIT_WIDTH   = NVP_v1_constants::COMBINED_DATA_BIT_WIDTH,
    parameter int VALID_MSB                 = NVP_v1_constants::VALID_MSB,
    parameter int LAST_COLUMN_MSB           = NVP_v1_constants::LAST_COLUMN_MSB,
    parameter int RELATIVE_ROW_MSB          = NVP_v1_constants::RELATIVE_ROW_MSB,
    parameter int CHANNEL_MSB               = NVP_v1_constants::CHANNEL_MSB,
    parameter int TOGGLED_COLUMN_MSB        = NVP_v1_constants::TOGGLED_COLUMN_MSB,
    parameter int ACTIVATION_DATA_MSB       = NVP_v1_constants::ACTIVATION_DATA_MSB,
    parameter int SPARSE_MODE               = NVP_v1_constants::SPARSE_MODE,
    parameter int DENSE_MODE                = NVP_v1_constants::DENSE_MODE
)(
    input logic                                 clk,
    input logic                                 resetn,
    input logic                                 i_pw_fifo_write_valid_condition,
    output logic                                o_pw_fifo_write_ready [NUMBER_OF_READ_STREAMS],
    decoded_data_if                 decoded_data,
    compute_core_data_if            compute_data
);

    // --------------------------------------
    // ------ Buffer the read stream words for PW conv mode.
	// --------------------------------------
    logic [COMBINED_DATA_BIT_WIDTH-1:0] pw_fifo_write_data  [NUMBER_OF_READ_STREAMS];
    logic                               pw_fifo_write_valid [NUMBER_OF_READ_STREAMS];
    logic [COMBINED_DATA_BIT_WIDTH-1:0] pw_fifo_read_data   [NUMBER_OF_READ_STREAMS];
    logic                               pw_fifo_read_valid  [NUMBER_OF_READ_STREAMS];
    logic                               pw_fifo_read_ready  [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS-1:0]  pw_fifo_empty;
    always_comb begin
        for (int i=0; i < NUMBER_OF_READ_STREAMS; i++) begin
            pw_fifo_write_data[i]  = {decoded_data.data[i], decoded_data.toggled_column[i], decoded_data.channel[i], decoded_data.valid[i], decoded_data.last_column[i]};
            pw_fifo_write_valid[i] = (i_pw_fifo_write_valid_condition==1)? decoded_data.valid[i] : '0;
        end

        // set pw_fifo fifo_read ready
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            pw_fifo_read_ready[i] = compute_data.pw_ready[i]; 
        end
    end
    generate 
        for (genvar i=0; i < NUMBER_OF_READ_STREAMS; i++) begin
            axis_fifo_v2 #(
                .AXIS_BUS_WIDTH (COMBINED_DATA_BIT_WIDTH),
                .FIFO_DEPTH     (PW_DATA_FIFO_DEPTH) 
            ) pw_data_fifo (
                .m_axi_aclk     (clk),
                .m_axi_aresetn  (resetn),
                .s_axis_tdata   (pw_fifo_write_data[i]),
                .s_axis_tvalid  (pw_fifo_write_valid[i]),
                .s_axis_tready  (o_pw_fifo_write_ready[i]),
                .m_axis_tdata   (pw_fifo_read_data[i]),
                .m_axis_tvalid  (pw_fifo_read_valid[i]),
                .m_axis_tready  (pw_fifo_read_ready[i]),
                .o_empty        (pw_fifo_empty[i])
            );
        end
    endgenerate

     // set compute_data pw signals 
    always_comb begin
        compute_data.pw_data            = pw_fifo_read_data; 
        compute_data.pw_data_valid      = pw_fifo_read_valid; 
    end

endmodule