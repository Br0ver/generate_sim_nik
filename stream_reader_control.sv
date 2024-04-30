/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Buffer Stream Reader Control
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module stream_reader_control #(   
    parameter int REGISTER_WIDTH                        = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS                   = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH               = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH, 
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS     = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    localparam LINE_BUFFER_SELECTION_BIT_WIDTH  = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS)
)(
    input  logic                                            clk,
    input  logic                                            resetn,
    register_file_if                                        latched_reg_file,
    input  logic                                            i_stream_read_enable,
    input  logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0] i_stream_read_start_address, 
    output logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0] o_stream_read_address_ff, 
    output logic                                            o_streamed_data_valid,
    input  logic                                            i_streamed_data_ready
);

    logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0] stream_read_address_ff;
    logic stream_read_valid_ff;

    // connect output of the selected line buffers
    always_comb begin
        // o_stream_read_data  = i_data_out;
        o_streamed_data_valid = stream_read_valid_ff; 
    end

    logic stream_readers_on;
    // stream read logic (when to start and increment address, and handshake with next module).
    always_ff @(posedge clk) begin
        if (resetn==0) begin 
            stream_read_valid_ff   <= 0;
            stream_read_address_ff <= 0;
            stream_readers_on <= 0;
        end else begin
            if (latched_reg_file.local_resetn==0) begin //TODO:: check local reset
                stream_read_valid_ff   <= 0;
                stream_readers_on <= 0;
            end
            else begin
                if(i_stream_read_enable==1) begin
                    if(i_streamed_data_ready==1 && stream_readers_on==1) begin
                        stream_read_valid_ff    <= 1;
                        stream_read_address_ff  <= (stream_read_valid_ff)? stream_read_address_ff + 1 : stream_read_address_ff;
                    end

                    if(latched_reg_file.start_stream_readers==1) begin
                        stream_readers_on       <= 1;
                        stream_read_address_ff  <= i_stream_read_start_address;
                    end

                end
            end
            
            
        end
    end
    
    // assign output
    always_comb o_stream_read_address_ff = stream_read_address_ff;
endmodule