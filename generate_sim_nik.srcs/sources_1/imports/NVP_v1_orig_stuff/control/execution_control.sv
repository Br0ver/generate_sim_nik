/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Execution Control
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps
    
module execution_control #(   
    parameter int REGISTER_WIDTH       = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS  = NVP_v1_constants::NUMBER_OF_REGISTERS
)(
    input logic clk,
    input logic resetn,
    register_file_if reg_file,
    register_file_if latched_reg_file,
    control_and_stream_decoder_if stream_decoder_ctrl,

    output logic o_push_sync_word,
    output logic o_next_command_interrupt

);
 
    // --------------------------------------
    // ------ Control Logic
	// --------------------------------------
    // Computation trigger control
    // enum {IDLE, } computation_trigger_fsm 
    // //-- start stream readers
    // //-- end of line and start of next line
    // //-- control of stream readers
    // //-- control of output transfers to dram ? 
    // // i_ctrl_last_column

    logic next_command_interrupt, push_sync_word;
    always_comb o_next_command_interrupt = next_command_interrupt;
    always_comb o_push_sync_word = push_sync_word;

    // --------------------------------------
    // ------ Execution control logic 
	// --------------------------------------
    logic local_resetn, register_file_latched_flag; 
    enum logic[1:0] {IDLE, LATCH_REG_FILE, EXECUTING, LAST_COLUMN}    execution_state_fsm;
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            execution_state_fsm     <= IDLE;
            local_resetn            <= 1;
            next_command_interrupt  <= 0;
            push_sync_word          <= 0;

            latched_reg_file.execution_flag                     <= '0;
            latched_reg_file.stream_mode                        <= '0;
            latched_reg_file.pw_conv                            <= '0;
            latched_reg_file.strided_conv                       <= '0;
            latched_reg_file.enable_element_wise_buffer         <= '0;
            latched_reg_file.element_wise_add                   <= '0;
            latched_reg_file.bias_enable                        <= '0;
            latched_reg_file.q_scale                            <= '0;
            latched_reg_file.relu                               <= '0;
            // latched_reg_file.weight_ping_or_pong                <= '0;
            latched_reg_file.weight_address_offset              <= '0;
            latched_reg_file.number_of_output_slicing_steps     <= '0;
            latched_reg_file.number_of_channels                 <= '0;
            latched_reg_file.channels_minus_8                   <= '0;
            latched_reg_file.kernel_steps_minus_1               <= '0;
            latched_reg_file.channel_steps                      <= '0;
            latched_reg_file.bias_steps                         <= '0;
            latched_reg_file.number_of_conv_layer_columns       <= '0;
            latched_reg_file.expected_total_number_of_outputs   <= '0;
            latched_reg_file.stream_writer_ptr                  <= '0;
            latched_reg_file.stream_1_ptr                       <= '0;
            latched_reg_file.stream_2_ptr                       <= '0;
            latched_reg_file.stream_3_ptr                       <= '0;
            latched_reg_file.stream_1_enable                    <= '0;
            latched_reg_file.stream_2_enable                    <= '0;
            latched_reg_file.stream_3_enable                    <= '0;

        end
        else begin 
            case (execution_state_fsm)
                IDLE: begin
                    push_sync_word          <= 0;
                    next_command_interrupt  <= 0;
                    local_resetn            <= 1;

                    if (reg_file.execution_flag == 1) begin
                        execution_state_fsm <= LATCH_REG_FILE;
                    end
                end
                LATCH_REG_FILE: begin
                    latched_reg_file.execution_flag                     <= 1;
                    latched_reg_file.stream_mode                        <= reg_file.stream_mode;    
                    latched_reg_file.pw_conv                            <= reg_file.pw_conv;
                    latched_reg_file.strided_conv                       <= reg_file.strided_conv;
                    latched_reg_file.enable_element_wise_buffer         <= reg_file.enable_element_wise_buffer;
                    latched_reg_file.element_wise_add                   <= reg_file.element_wise_add;
                    latched_reg_file.bias_enable                        <= reg_file.bias_enable;
                    latched_reg_file.q_scale                            <= reg_file.q_scale;
                    latched_reg_file.relu                               <= reg_file.relu;
                    // latched_reg_file.weight_ping_or_pong                <= reg_file.weight_ping_or_pong;   
                    latched_reg_file.weight_address_offset              <= reg_file.weight_address_offset;
                    latched_reg_file.number_of_output_slicing_steps     <= reg_file.number_of_output_slicing_steps;         
                    latched_reg_file.number_of_channels                 <= reg_file.number_of_channels;        
                    latched_reg_file.channels_minus_8                   <= reg_file.channels_minus_8;        
                    latched_reg_file.kernel_steps_minus_1               <= reg_file.kernel_steps_minus_1;        
                    latched_reg_file.channel_steps                      <= reg_file.channel_steps;        
                    latched_reg_file.bias_steps                         <= reg_file.bias_steps;
                    latched_reg_file.number_of_conv_layer_columns       <= reg_file.number_of_conv_layer_columns;  
                    latched_reg_file.expected_total_number_of_outputs   <= reg_file.expected_total_number_of_outputs;   
                    latched_reg_file.stream_writer_ptr                  <= reg_file.stream_writer_ptr;
                    latched_reg_file.stream_1_ptr                       <= reg_file.stream_1_ptr;    
                    latched_reg_file.stream_2_ptr                       <= reg_file.stream_2_ptr;    
                    latched_reg_file.stream_3_ptr                       <= reg_file.stream_3_ptr;    
                    latched_reg_file.stream_1_enable                    <= reg_file.stream_1_enable;    
                    latched_reg_file.stream_2_enable                    <= reg_file.stream_2_enable;    
                    latched_reg_file.stream_3_enable                    <= reg_file.stream_3_enable;    

                    execution_state_fsm <= EXECUTING;     
                end
                EXECUTING: begin
                    if (stream_decoder_ctrl.last_column_flag_and==1) begin 
                        execution_state_fsm <= LAST_COLUMN;
                    end
                end
                LAST_COLUMN: begin
                    if (stream_decoder_ctrl.last_column_flag_nor==1) begin
                            execution_state_fsm             <= IDLE;
                            latched_reg_file.execution_flag <= 0;
                            local_resetn                    <= 0; 
                            next_command_interrupt          <= 1;    
                            push_sync_word                  <= 1;    
                    end  
                end
                default: begin
                    execution_state_fsm <= IDLE;
                end
            endcase
        end
    end

    // assign outputs 
    always_comb reg_file.local_resetn = local_resetn; 
    always_comb latched_reg_file.local_resetn = local_resetn; 
    always_comb latched_reg_file.start_stream_readers = reg_file.start_stream_readers;       
    // always_comb latched_reg_file.execution_flag = (execution_state_fsm==EXECUTING || )? 1 : 0;
   
endmodule
