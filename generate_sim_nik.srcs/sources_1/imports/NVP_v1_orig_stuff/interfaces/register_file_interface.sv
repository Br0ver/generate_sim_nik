/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Register File interface
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface register_file_if#(
    parameter int REGISTER_WIDTH	    = 32
)();
    logic                       execution_flag;
    logic                       stream_mode;
    logic                       pw_conv;
    logic                       strided_conv;
    logic                       enable_element_wise_buffer; 
    logic                       element_wise_add; 
    logic                       bias_enable;
    logic                       relu;
    // logic                       weight_ping_or_pong; 
    logic [REGISTER_WIDTH-1:0]  q_scale; 
    logic [REGISTER_WIDTH-1:0]  weight_address_offset; 
    // logic                       padding;  TODO:: remove me
    logic [REGISTER_WIDTH-1:0]  kernel_steps_minus_1;
    logic [REGISTER_WIDTH-1:0]  number_of_output_slicing_steps; // if(number_of_kernels>=number_of_PEs_per_array) -> number_of_PEs_per_array/activation_bit_width,  else number_of_kernels/activation_bit_width
    logic [REGISTER_WIDTH-1:0]  expected_total_number_of_outputs;
    logic [REGISTER_WIDTH-1:0]  channel_steps;
    logic [REGISTER_WIDTH-1:0]  bias_steps;
    logic [REGISTER_WIDTH-1:0]  number_of_channels;
    logic [REGISTER_WIDTH-1:0]  channels_minus_8;
    logic [REGISTER_WIDTH-1:0]  number_of_conv_layer_columns;
    logic [REGISTER_WIDTH-1:0]  stream_1_ptr;
    logic [REGISTER_WIDTH-1:0]  stream_2_ptr;
    logic [REGISTER_WIDTH-1:0]  stream_3_ptr;
    logic [REGISTER_WIDTH-1:0]  stream_writer_ptr;
    logic                       stream_1_enable;
    logic                       stream_2_enable;
    logic                       stream_3_enable;
    logic                       start_stream_readers;
    logic                       local_resetn;
    logic [REGISTER_WIDTH-1:0]  output_line_end_address;

    modport master (output execution_flag, 
        stream_mode, 
        pw_conv, 
        strided_conv,
        enable_element_wise_buffer,
        element_wise_add,
        bias_enable,
        // weight_ping_or_pong, 
        q_scale,
        relu,
        weight_address_offset,
        kernel_steps_minus_1,
        number_of_output_slicing_steps,
        expected_total_number_of_outputs,
        channel_steps,
        bias_steps,
        channels_minus_8,
        number_of_channels,
        number_of_conv_layer_columns,
        stream_writer_ptr,
        stream_1_ptr,
        stream_2_ptr,
        stream_3_ptr,
        stream_1_enable,
        stream_2_enable,
        stream_3_enable,
        start_stream_readers,
        local_resetn,
        output_line_end_address
    );

    modport slave (input execution_flag, 
        stream_mode, 
        pw_conv, 
        strided_conv,
        enable_element_wise_buffer,
        element_wise_add,
        bias_enable,
        q_scale,
        relu,
        // weight_ping_or_pong, 
        weight_address_offset,
        kernel_steps_minus_1,
        number_of_output_slicing_steps,
        expected_total_number_of_outputs,
        channel_steps,
        bias_steps,
        channels_minus_8,
        number_of_channels,
        number_of_conv_layer_columns,
        stream_writer_ptr,
        stream_1_ptr,
        stream_2_ptr,
        stream_3_ptr,
        stream_1_enable,
        stream_2_enable,
        stream_3_enable,
        start_stream_readers,
        local_resetn,
        output_line_end_address
    );
endinterface
