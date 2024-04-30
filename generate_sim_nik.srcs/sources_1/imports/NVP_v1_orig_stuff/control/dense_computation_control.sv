/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: SPARSE conv3x3 convolution computation control. 
*   Date:   07.04.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module dense_conv_computation_control #(   
    parameter int REGISTER_WIDTH                        = NVP_v1_constants::REGISTER_WIDTH,
    parameter int SPARSE_MODE                           = NVP_v1_constants::SPARSE_MODE,
    parameter int DENSE_MODE                            = NVP_v1_constants::DENSE_MODE,
    parameter int ACTIVATION_BANK_BIT_WIDTH             = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT          = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int ACTIVATION_BIT_WIDTH                  = NVP_v1_constants::ACTIVATION_BIT_WIDTH,    
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW           = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,             
    parameter int NUMBER_OF_READ_STREAMS                = NVP_v1_constants::NUMBER_OF_READ_STREAMS,            
    parameter int NUMBER_OF_PES_PER_ARRAY               = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,        
    parameter int COLUMN_VALUE_BIT_WIDTH                = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,        
    parameter int CHANNEL_VALUE_BIT_WIDTH               = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,        
    parameter int ROW_VALUE_BIT_WIDTH                   = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,    
    parameter int WEIGHT_LINE_BUFFER_DEPTH              = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,    
    parameter int TOGGLED_COLUMN_MSB                    = NVP_v1_constants::TOGGLED_COLUMN_MSB,    
    parameter int CHANNEL_MSB                           = NVP_v1_constants::CHANNEL_MSB,
    parameter int RELATIVE_ROW_MSB                      = NVP_v1_constants::RELATIVE_ROW_MSB,
    parameter int LAST_COLUMN_MSB                       = NVP_v1_constants::LAST_COLUMN_MSB,
    parameter int ACTIVATION_DATA_MSB                   = NVP_v1_constants::ACTIVATION_DATA_MSB,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    parameter int SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS),
    localparam int CHANNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS)
)(
    input logic                                                                 clk,
    input logic                                                                 resetn,
    // input logic                                                              i_latched_reg_file_stream_mode,
    input logic                                                                 i_input_reg_file_start_stream_readers,
    register_file_if                                                            latched_reg_file,
    compute_core_data_if                                                        compute_data,
    output logic                                                                o_dense_shift_output_steps_counter_finished_flag,
    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                           o_dense_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                         o_dense_weight_address_systolic      [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_dense_delayed_shift_partial_result_flag,
    output logic                                                                o_dense_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_dense_reset_accumulator_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]   o_dense_activations_systolic         [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_dense_valid_systolic               [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                           o_dense_kernel_step_index_systolic   [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_dense_ready                        [NUMBER_OF_READ_STREAMS],
    output logic                                                                o_dense_update_latched_reg_file_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                           o_post_processing_dense_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_post_processing_dense_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                o_post_processing_dense_shift_output_steps_counter_finished_flag

);

    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0] dense_kernel_steps_counter;


        // compute_data.dense_data         = streamed_data.data; 
        // compute_data.dense_data_valid   = streamed_data.valid; 

    enum {IDLE, ONE, TWO, THREE} dense_control_fsm;
    always_ff @(posedge clk) begin
        if (resetn==0) begin          
            o_dense_ready       <= '{default:0};
            dense_control_fsm   <= IDLE;
        end
        else begin
            case (dense_control_fsm) 
            IDLE: begin
                // if(latched_reg_file.stream_mode==DENSE_MODE && compute_data.dense_data_valid[0]==1) begin 
                if(latched_reg_file.stream_mode==DENSE_MODE && i_input_reg_file_start_stream_readers==1) begin 
                    if(latched_reg_file.stream_1_enable==1) begin
                        dense_control_fsm <= ONE;
                        o_dense_ready[0] <= 1;
                        o_dense_ready[1] <= 0;
                        o_dense_ready[2] <= 0;
                    end
                    else begin
                        if(latched_reg_file.stream_2_enable==1) begin
                            dense_control_fsm <= TWO;
                            o_dense_ready[0] <= 0;
                            o_dense_ready[1] <= 1;
                            o_dense_ready[2] <= 0;
                        end
                        else begin
                            dense_control_fsm <= THREE;
                            o_dense_ready[0] <= 0;
                            o_dense_ready[1] <= 0;
                            o_dense_ready[2] <= 1;
                        end
                    end
                    
                end
            end
            ONE: begin
                if(dense_kernel_steps_counter==latched_reg_file.kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin 
                    if(latched_reg_file.stream_2_enable==1) begin
                        dense_control_fsm <= TWO;
                        o_dense_ready[0]    <= 0;
                        o_dense_ready[1]    <= 1;
                        o_dense_ready[2]    <= 0;
                    end
                    else begin
                        if(latched_reg_file.stream_3_enable==1) begin
                            dense_control_fsm <= THREE;
                            o_dense_ready[0]    <= 0;
                            o_dense_ready[1]    <= 0;
                            o_dense_ready[2]    <= 1;
                        end
                        else begin
                            dense_control_fsm <= ONE;
                            o_dense_ready[0]    <= 1;
                            o_dense_ready[1]    <= 0;
                            o_dense_ready[2]    <= 0;
                        end
                    end                
                end
            end
            TWO: begin
                if(dense_kernel_steps_counter==latched_reg_file.kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0])begin
                    if(latched_reg_file.stream_3_enable==1) begin
                        dense_control_fsm <= THREE;
                        o_dense_ready[0]    <= 0;
                        o_dense_ready[1]    <= 0;
                        o_dense_ready[2]    <= 1;
                    end
                    else begin
                        if(latched_reg_file.stream_1_enable==1) begin
                            dense_control_fsm <= ONE;
                            o_dense_ready[0]    <= 1;
                            o_dense_ready[1]    <= 0;
                            o_dense_ready[2]    <= 0;
                        end
                        else begin
                            dense_control_fsm <= THREE;
                            o_dense_ready[0]    <= 0;
                            o_dense_ready[1]    <= 0;
                            o_dense_ready[2]    <= 1;
                        end
                    end
                end
            end
            THREE: begin
                if(dense_kernel_steps_counter==latched_reg_file.kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0])begin
                    if(latched_reg_file.stream_1_enable==1) begin
                        dense_control_fsm <= ONE;
                        o_dense_ready[0]    <= 1;
                        o_dense_ready[1]    <= 0;
                        o_dense_ready[2]    <= 0;
                    end
                    else begin
                        if(latched_reg_file.stream_2_enable==1) begin
                            dense_control_fsm <= TWO;
                            o_dense_ready[0]    <= 0;
                            o_dense_ready[1]    <= 1;
                            o_dense_ready[2]    <= 0;
                        end
                        else begin
                            dense_control_fsm <= THREE;
                            o_dense_ready[0]    <= 0;
                            o_dense_ready[1]    <= 0;
                            o_dense_ready[2]    <= 1;
                        end
                    end
                end
            end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (resetn==0) begin
            o_dense_shift_output_steps_counter_finished_flag                    <= '0;
            o_dense_shift_output_steps_counter_systolic                         <= '{default:0};
            o_dense_weight_address_systolic                                     <= '{default:0};
            o_dense_delayed_shift_partial_result_flag                           <= '0;
            o_dense_shift_partial_result_systolic                               <= '{default:0};
            o_dense_reset_accumulator_systolic                                  <= '{default:0};
            o_dense_activations_systolic                                        <= '{default:0};
            o_dense_valid_systolic                                              <= '{default:0};
            o_dense_kernel_step_index_systolic                                  <= '{default:0};
            o_dense_update_latched_reg_file_systolic                            <= '{default:0};
            o_post_processing_dense_shift_output_steps_counter_systolic         <= '{default:0};
            o_post_processing_dense_shift_partial_result_systolic               <= '{default:0};
            o_post_processing_dense_shift_output_steps_counter_finished_flag    <= '0;
        end
        else begin
            
        end
        
    end

    always_ff @(posedge clk) begin
        if(resetn==0) begin
            dense_kernel_steps_counter <= '{default:0};
        end
        else begin
            if(dense_control_fsm!=IDLE) begin
                if(dense_kernel_steps_counter==latched_reg_file.kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin // steps >= 2
                    dense_kernel_steps_counter <= '{default:0};
                end
                else begin
                    dense_kernel_steps_counter <= dense_kernel_steps_counter + 1;
                end
            end
        end
    end

    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0] dense_weight_address;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH+1-1:0] kernel_steps;
    logic [CHANNEL_STEPS_COUNTER_BIT_WIDTH+1-1:0] channel_steps;
    logic [1:0] relative_row;
    always_comb begin
        case (dense_control_fsm)
        IDLE:  relative_row = 0;
        ONE:   relative_row = 0;
        TWO:   relative_row = 1;
        THREE: relative_row = 2;
        endcase
    end
    always_comb channel_steps                   = latched_reg_file.channel_steps; 
    always_comb kernel_steps                    = channel_steps; 
    // always_comb valid_fifo_write_weight_address = (unsigned'(dissected_write_valid_channel)*unsigned'(kernel_steps)) + (unsigned'(dissected_write_valid_row)*unsigned'(kernel_steps)*unsigned'(latched_reg_file.number_of_channels));
    always_comb begin 
        dense_weight_address = dense_kernel_steps_counter + relative_row*kernel_steps;
    end

endmodule