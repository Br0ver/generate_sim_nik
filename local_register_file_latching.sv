/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Local Register File Latching
*   Date:   10.02.2022
*   Author: hasan
*   Description: This module latches the input register file locally inside each compute stage. 
*/


`timescale 1ns / 1ps

module local_reg_file_latching #(   
    parameter int REGISTER_WIDTH      = NVP_v1_constants::REGISTER_WIDTH
    
)(
    input logic         clk,
    input logic         resetn,
    input logic         i_first_latching_condition,
    input logic         i_update_latching_condition,
    register_file_if    input_reg_file,
    register_file_if    latched_reg_file,
    register_file_if    output_reg_file
);

    // logic update_latched_reg_file; 
    enum logic {FIRST_LATCH, OTHERS} local_latching_fsm; 
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            local_latching_fsm <= FIRST_LATCH;

            latched_reg_file.stream_mode                    <= '0;
            latched_reg_file.pw_conv                        <= '0;
            latched_reg_file.strided_conv                   <= '0;
            latched_reg_file.enable_element_wise_buffer     <= '0;
            latched_reg_file.element_wise_add               <= '0;
            latched_reg_file.bias_enable                    <= '0;
            latched_reg_file.q_scale                        <= '0;
            latched_reg_file.relu                           <= '0;
            // latched_reg_file.weight_ping_or_pong            <= '0;
            latched_reg_file.weight_address_offset          <= '0;
            latched_reg_file.number_of_channels             <= '0;
            latched_reg_file.channels_minus_8               <= '0;
            latched_reg_file.kernel_steps_minus_1           <= '0;
            latched_reg_file.number_of_output_slicing_steps <= '0;
            latched_reg_file.channel_steps                  <= '0;
            latched_reg_file.bias_steps                     <= '0;
            latched_reg_file.number_of_conv_layer_columns   <= '0;
            latched_reg_file.expected_total_number_of_outputs   <= '0;
            latched_reg_file.stream_writer_ptr              <= '0;
            latched_reg_file.stream_1_ptr                   <= '0;
            latched_reg_file.stream_2_ptr                   <= '0;
            latched_reg_file.stream_3_ptr                   <= '0;
            latched_reg_file.stream_1_enable                <= '0;
            latched_reg_file.stream_2_enable                <= '0;
            latched_reg_file.stream_3_enable                <= '0;
            latched_reg_file.execution_flag                 <= 0;
            latched_reg_file.start_stream_readers           <= 0;  

        end else begin
            case (local_latching_fsm)
                FIRST_LATCH: begin
                    // if (input_reg_file.execution_flag) begin i_first_latching_condition
                    if (i_first_latching_condition) begin 
                        latched_reg_file.stream_mode                    <= input_reg_file.stream_mode;    
                        latched_reg_file.pw_conv                        <= input_reg_file.pw_conv;
                        latched_reg_file.strided_conv                   <= input_reg_file.strided_conv;
                        latched_reg_file.enable_element_wise_buffer     <= input_reg_file.enable_element_wise_buffer;
                        latched_reg_file.element_wise_add               <= input_reg_file.element_wise_add;
                        latched_reg_file.bias_enable                    <= input_reg_file.bias_enable;
                        latched_reg_file.q_scale                        <= input_reg_file.q_scale;
                        latched_reg_file.relu                           <= input_reg_file.relu;
                        // latched_reg_file.weight_ping_or_pong            <= input_reg_file.weight_ping_or_pong;            
                        latched_reg_file.weight_address_offset          <= input_reg_file.weight_address_offset;
                        latched_reg_file.number_of_channels             <= input_reg_file.number_of_channels;        
                        latched_reg_file.channels_minus_8               <= input_reg_file.channels_minus_8;        
                        latched_reg_file.kernel_steps_minus_1           <= input_reg_file.kernel_steps_minus_1;        
                        latched_reg_file.number_of_output_slicing_steps <= input_reg_file.number_of_output_slicing_steps;        
                        latched_reg_file.channel_steps                  <= input_reg_file.channel_steps;        
                        latched_reg_file.bias_steps                     <= input_reg_file.bias_steps;        
                        latched_reg_file.number_of_conv_layer_columns   <= input_reg_file.number_of_conv_layer_columns;      
                        latched_reg_file.expected_total_number_of_outputs   <= input_reg_file.expected_total_number_of_outputs;      
                        
                        latched_reg_file.stream_writer_ptr              <= input_reg_file.stream_writer_ptr;
                        latched_reg_file.stream_1_ptr                   <= input_reg_file.stream_1_ptr;    
                        latched_reg_file.stream_2_ptr                   <= input_reg_file.stream_2_ptr;    
                        latched_reg_file.stream_3_ptr                   <= input_reg_file.stream_3_ptr;    
                        latched_reg_file.stream_1_enable                <= input_reg_file.stream_1_enable;    
                        latched_reg_file.stream_2_enable                <= input_reg_file.stream_2_enable;    
                        latched_reg_file.stream_3_enable                <= input_reg_file.stream_3_enable;  

                        latched_reg_file.start_stream_readers           <= input_reg_file.start_stream_readers;  
                        latched_reg_file.execution_flag                 <= input_reg_file.execution_flag;
                          
                        
                        local_latching_fsm <= OTHERS;
                    end
                end
                OTHERS: begin
                    //TODO:: fixme: check second condition. is it correct when there is a long gap between triggers?
                    // if (i_update_latching_condition==1 && input_reg_file.execution_flag) begin // condition == when previous mode's computes are done -> check empty fifos and weight address delay... 
                    if (i_update_latching_condition==1) begin // condition == when previous mode's computes are done -> check empty fifos and weight address delay... 
                        latched_reg_file.stream_mode                    <= input_reg_file.stream_mode;    
                        latched_reg_file.pw_conv                        <= input_reg_file.pw_conv;
                        latched_reg_file.strided_conv                   <= input_reg_file.strided_conv;
                        latched_reg_file.enable_element_wise_buffer     <= input_reg_file.enable_element_wise_buffer;
                        latched_reg_file.element_wise_add               <= input_reg_file.element_wise_add;
                        latched_reg_file.bias_enable                    <= input_reg_file.bias_enable;
                        latched_reg_file.q_scale                        <= input_reg_file.q_scale;
                        latched_reg_file.relu                           <= input_reg_file.relu;
                        // latched_reg_file.weight_ping_or_pong            <= input_reg_file.weight_ping_or_pong;            
                        latched_reg_file.weight_address_offset          <= input_reg_file.weight_address_offset;
                        latched_reg_file.number_of_channels             <= input_reg_file.number_of_channels;        
                        latched_reg_file.channels_minus_8               <= input_reg_file.channels_minus_8;        
                        latched_reg_file.kernel_steps_minus_1           <= input_reg_file.kernel_steps_minus_1;  
                        latched_reg_file.number_of_output_slicing_steps <= input_reg_file.number_of_output_slicing_steps;      
                        latched_reg_file.channel_steps                  <= input_reg_file.channel_steps;        
                        latched_reg_file.bias_steps                     <= input_reg_file.bias_steps;        
                        latched_reg_file.number_of_conv_layer_columns   <= input_reg_file.number_of_conv_layer_columns;  
                        latched_reg_file.expected_total_number_of_outputs   <= input_reg_file.expected_total_number_of_outputs;  
                        
                        latched_reg_file.stream_writer_ptr              <= input_reg_file.stream_writer_ptr;                     
                        latched_reg_file.stream_1_ptr                   <= input_reg_file.stream_1_ptr;    
                        latched_reg_file.stream_2_ptr                   <= input_reg_file.stream_2_ptr;    
                        latched_reg_file.stream_3_ptr                   <= input_reg_file.stream_3_ptr;    
                        latched_reg_file.stream_1_enable                <= input_reg_file.stream_1_enable;    
                        latched_reg_file.stream_2_enable                <= input_reg_file.stream_2_enable;    
                        latched_reg_file.stream_3_enable                <= input_reg_file.stream_3_enable;  
                        latched_reg_file.start_stream_readers           <= input_reg_file.start_stream_readers;  
                        latched_reg_file.execution_flag                 <= input_reg_file.execution_flag;  
                    end
                end
            endcase
        end
    end

    always_comb begin
        output_reg_file.stream_mode                     = latched_reg_file.stream_mode;    
        output_reg_file.pw_conv                         = latched_reg_file.pw_conv;
        output_reg_file.strided_conv                    = latched_reg_file.strided_conv;
        output_reg_file.enable_element_wise_buffer      = latched_reg_file.enable_element_wise_buffer;
        output_reg_file.element_wise_add                = latched_reg_file.element_wise_add;
        output_reg_file.bias_enable                     = latched_reg_file.bias_enable;
        output_reg_file.q_scale                         = latched_reg_file.q_scale;
        output_reg_file.relu                            = latched_reg_file.relu;
        // output_reg_file.weight_ping_or_pong             = latched_reg_file.weight_ping_or_pong;            
        output_reg_file.weight_address_offset           = latched_reg_file.weight_address_offset;
        output_reg_file.number_of_channels              = latched_reg_file.number_of_channels;        
        output_reg_file.channels_minus_8                = latched_reg_file.channels_minus_8;        
        output_reg_file.kernel_steps_minus_1            = latched_reg_file.kernel_steps_minus_1;    
        output_reg_file.number_of_output_slicing_steps  = latched_reg_file.number_of_output_slicing_steps;    
        output_reg_file.channel_steps                   = latched_reg_file.channel_steps;        
        output_reg_file.bias_steps                      = latched_reg_file.bias_steps;        
        output_reg_file.number_of_conv_layer_columns    = latched_reg_file.number_of_conv_layer_columns;  
        output_reg_file.expected_total_number_of_outputs    = latched_reg_file.expected_total_number_of_outputs;  
        output_reg_file.stream_writer_ptr               = latched_reg_file.stream_writer_ptr;                     
        output_reg_file.stream_1_ptr                    = latched_reg_file.stream_1_ptr;    
        output_reg_file.stream_2_ptr                    = latched_reg_file.stream_2_ptr;    
        output_reg_file.stream_3_ptr                    = latched_reg_file.stream_3_ptr;    
        output_reg_file.stream_1_enable                 = latched_reg_file.stream_1_enable;    
        output_reg_file.stream_2_enable                 = latched_reg_file.stream_2_enable;    
        output_reg_file.stream_3_enable                 = latched_reg_file.stream_3_enable;  
        output_reg_file.start_stream_readers            = latched_reg_file.start_stream_readers;  
        output_reg_file.execution_flag                  = latched_reg_file.execution_flag;       
        output_reg_file.output_line_end_address         = latched_reg_file.output_line_end_address;       
    end

endmodule