/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Computation Control
*   Date:   17.01.2022
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

module computation_control #(   
    parameter int REGISTER_WIDTH                    = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS               = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int WEIGHT_LINE_BUFFER_DEPTH               = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter int CHANNEL_VALUE_BIT_WIDTH           = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int SPARSE_MODE                       = NVP_v1_constants::SPARSE_MODE,
    parameter int DENSE_MODE                        = NVP_v1_constants::DENSE_MODE,
    parameter int NUMBER_OF_READ_STREAMS            = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int ACTIVATION_BANK_BIT_WIDTH       = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT      = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int WEIGHT_BANK_BIT_WIDTH           = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH,
    parameter int WEIGHT_BUFFER_BANK_COUNT          = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW       = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,
    parameter int COLUMN_VALUE_BIT_WIDTH            = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ROW_VALUE_BIT_WIDTH               = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,
    parameter int TOGGLED_COLUMN_MSB                = NVP_v1_constants::TOGGLED_COLUMN_MSB,
    parameter int CHANNEL_MSB                       = NVP_v1_constants::CHANNEL_MSB,
    parameter int RELATIVE_ROW_MSB                  = NVP_v1_constants::RELATIVE_ROW_MSB,
    parameter int VALID_MSB                         = NVP_v1_constants::VALID_MSB,
    parameter int LAST_COLUMN_MSB                   = NVP_v1_constants::LAST_COLUMN_MSB,
    parameter int ACTIVATION_DATA_MSB               = NVP_v1_constants::ACTIVATION_DATA_MSB,
    parameter int ACTIVATION_BIT_WIDTH              = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int NUMBER_OF_PES_PER_ARRAY           = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH   = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS)
)(
    input logic             clk,
    input logic             resetn,
    input logic             i_input_reg_file_start_stream_readers,
    register_file_if        latched_reg_file,
    streamed_data_if        streamed_data,
    compute_core_data_if    compute_data,
    computation_control_if  computation_ctrl,
    output logic            o_update_latched_reg_file
);

    // --------------------------------------
    // ------ Sparse mode control
	// -------------------------------------- 
    logic                                                                    sparse_shift_output_steps_counter_finished_flag;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               sparse_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                             sparse_weight_address_systolic      [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                    sparse_delayed_shift_partial_result_flag;
    logic                                                                    sparse_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                    sparse_reset_accumulator_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]       sparse_activations_systolic         [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                    sparse_valid_systolic               [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               sparse_kernel_step_index_systolic   [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                    sparse_ready;
    logic                                                                    sparse_update_latched_reg_file_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               post_processing_sparse_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                    post_processing_sparse_shift_output_steps_counter_finished_flag;
    logic                                                                    post_processing_sparse_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW];
    sparse_conv_computation_control sparse_control (
        .clk                                                                (clk),
        .resetn                                                             (resetn),
        .compute_data                                                       (compute_data),
        .i_sparse_kernel_steps_minus_1                                      (latched_reg_file.kernel_steps_minus_1), 
        .i_sparse_number_of_channels                                        (latched_reg_file.number_of_channels),
        .o_sparse_shift_output_steps_counter_finished_flag                  (sparse_shift_output_steps_counter_finished_flag),                          
        .o_sparse_shift_output_steps_counter_systolic                       (sparse_shift_output_steps_counter_systolic),                    
        .o_sparse_weight_address_systolic                                   (sparse_weight_address_systolic),        
        .o_sparse_delayed_shift_partial_result_flag                         (sparse_delayed_shift_partial_result_flag),                
        .o_sparse_shift_partial_result_systolic                             (sparse_shift_partial_result_systolic),            
        .o_sparse_reset_accumulator_systolic                                (sparse_reset_accumulator_systolic),            
        .o_sparse_activations_systolic                                      (sparse_activations_systolic),    
        .o_sparse_valid_systolic                                            (sparse_valid_systolic),
        .o_sparse_kernel_step_index_systolic                                (sparse_kernel_step_index_systolic),
        .o_sparse_ready                                                     (sparse_ready),
        .o_sparse_update_latched_reg_file_systolic                          (sparse_update_latched_reg_file_systolic),
        .o_post_processing_sparse_shift_output_steps_counter_finished_flag  (post_processing_sparse_shift_output_steps_counter_finished_flag),                          
        .o_post_processing_sparse_shift_partial_result_systolic             (post_processing_sparse_shift_partial_result_systolic),            
        .o_post_processing_shift_output_steps_counter_systolic              (post_processing_sparse_shift_output_steps_counter_systolic)
    );
    
    // --------------------------------------
    // ------ Dense (DW) mode control 
	// -------------------------------------- 
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]    dense_activations_systolic                                        [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 dense_valid_systolic                                              [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 dense_delayed_shift_partial_result_flag;
    logic                                                                 dense_shift_partial_result_systolic                               [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                          dense_weight_address_systolic                                     [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 dense_weight_address_valid;
    logic                                                                 dense_ready                                                       [NUMBER_OF_READ_STREAMS];
    logic                                                                 dense_shift_output_steps_counter_finished_flag;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                            dense_shift_output_steps_counter_systolic                         [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 dense_reset_accumulator_systolic                                  [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                            dense_kernel_step_index_systolic                                  [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 dense_update_latched_reg_file_systolic                            [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                            post_processing_dense_shift_output_steps_counter_systolic         [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 post_processing_dense_shift_output_steps_counter_finished_flag;
    logic                                                                 post_processing_dense_shift_partial_result_systolic               [NUMBER_OF_PE_ARRAYS_PER_ROW];
    dense_conv_computation_control dense_control (
        .clk                                                                (clk),
        .resetn                                                             (resetn),
        .i_input_reg_file_start_stream_readers                              (i_input_reg_file_start_stream_readers),                       
        .latched_reg_file                                                   (latched_reg_file),
        .compute_data                                                       (compute_data), 
        .o_dense_shift_output_steps_counter_finished_flag                   (dense_shift_output_steps_counter_finished_flag),                                                   
        .o_dense_shift_output_steps_counter_systolic                        (dense_shift_output_steps_counter_systolic),                                
        .o_dense_weight_address_systolic                                    (dense_weight_address_systolic),                    
        .o_dense_delayed_shift_partial_result_flag                          (dense_delayed_shift_partial_result_flag),                            
        .o_dense_shift_partial_result_systolic                              (dense_shift_partial_result_systolic),                        
        .o_dense_reset_accumulator_systolic                                 (dense_reset_accumulator_systolic),                    
        .o_dense_activations_systolic                                       (dense_activations_systolic),                
        .o_dense_valid_systolic                                             (dense_valid_systolic),        
        .o_dense_kernel_step_index_systolic                                 (dense_kernel_step_index_systolic),                    
        .o_dense_ready                                                      (dense_ready),
        .o_dense_update_latched_reg_file_systolic                           (dense_update_latched_reg_file_systolic),                            
        .o_post_processing_dense_shift_output_steps_counter_systolic        (post_processing_dense_shift_output_steps_counter_systolic),                                                
        .o_post_processing_dense_shift_partial_result_systolic              (post_processing_dense_shift_partial_result_systolic),                                        
        .o_post_processing_dense_shift_output_steps_counter_finished_flag   (post_processing_dense_shift_output_steps_counter_finished_flag)
    );

    // --------------------------------------
    // ------ PW mode control // TODO:: fixme
	// -------------------------------------- 
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]    pw_activations_comb;
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]    pw_activations_ff [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 pw_delayed_shift_partial_result_flag;
    logic                                                                 pw_ready              [NUMBER_OF_READ_STREAMS];
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            pw_activations_comb <= '{default:0};
            pw_activations_ff <= '{default:0};
            pw_delayed_shift_partial_result_flag <= 0;
            pw_ready <= '{default:0};
        end
        else begin
            
        end
    end

    // --------------------------------------
    // ------ Set compute_data interface signals
	// -------------------------------------- 
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]    activations_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                                                 valid_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW]; 
    always_comb begin
        // data signals
        compute_data.activations    = activations_systolic;
        compute_data.weights        = computation_ctrl.weight_memory_data;
        compute_data.valid          = valid_systolic;

        // ready signals
        compute_data.sparse_ready   = sparse_ready;   
        compute_data.dense_ready    = dense_ready;
        compute_data.pw_ready       = pw_ready;
    end

    // --------------------------------------
    // ------ Use execution mode to select computation_ctrl and compute_data signals
	// -------------------------------------- 
    // always_comb begin
    //     if (latched_reg_file.pw_conv==1) begin // PW mode
    //         computation_ctrl.weight_memory_address = '{default:0};
    //     end 
    //     else begin
    //         case (latched_reg_file.stream_mode) 
    //             SPARSE_MODE: begin // SPARSE mode
    //                 computation_ctrl.weight_memory_address = sparse_weight_address_systolic;
    //             end
    //             DENSE_MODE: begin // DENSE mode
    //                 computation_ctrl.weight_memory_address = '{default:0};

    //             end
    //         endcase
    //     end
    // end

    always_ff @(posedge clk) begin
        if (resetn==0) begin
            activations_systolic                                            <= '{default:0}; 
                valid_systolic                                              <= '{default:0};
                computation_ctrl.delayed_shift_partial_result_flag          <= '0;
                computation_ctrl.shift_partial_result                       <= '{default:0};
                computation_ctrl.weight_memory_address                      <= '{default:0};
                computation_ctrl.reset_accumulators                         <= '{default:0};
                computation_ctrl.shift_output_steps_counter                 <= '{default:0};
                computation_ctrl.shift_output_steps_counter_finished_flag   <= '0;
                computation_ctrl.last_column_finished                       <= '0;
                computation_ctrl.kernel_step_index                          <= '{default:0};
                o_update_latched_reg_file                                   <= '0;

                computation_ctrl.post_processing_shift_output_steps_counter                 <= '{default:0};
                computation_ctrl.post_processing_shift_output_steps_counter_finished_flag   <= 0;
                computation_ctrl.post_processing_shift_partial_result                       <= '{default:0};
        end
        else begin
            if (latched_reg_file.pw_conv==1) begin // PW mode
                activations_systolic                                        <= '{default:0}; 
                valid_systolic                                              <= '{default:0};
                computation_ctrl.delayed_shift_partial_result_flag          <= '0;
                computation_ctrl.shift_partial_result                       <= '{default:0};
                computation_ctrl.weight_memory_address                      <= '{default:0};
                computation_ctrl.reset_accumulators                         <= '{default:0};
                computation_ctrl.shift_output_steps_counter                 <= '{default:0};
                computation_ctrl.shift_output_steps_counter_finished_flag   <= '0;
                computation_ctrl.last_column_finished                       <= '0;
                computation_ctrl.kernel_step_index                          <= '{default:0};
                o_update_latched_reg_file                                   <= '0;

                computation_ctrl.post_processing_shift_output_steps_counter                 <= '{default:0};
                computation_ctrl.post_processing_shift_output_steps_counter_finished_flag   <= 0;
                computation_ctrl.post_processing_shift_partial_result                       <= '{default:0};
            end 
            else begin
                case (latched_reg_file.stream_mode) 
                    SPARSE_MODE: begin // SPARSE mode
                        activations_systolic                                        <= sparse_activations_systolic;
                        valid_systolic                                              <= sparse_valid_systolic;
                        computation_ctrl.weight_memory_address                      <= sparse_weight_address_systolic;
                        computation_ctrl.delayed_shift_partial_result_flag          <= sparse_delayed_shift_partial_result_flag;
                        computation_ctrl.shift_partial_result                       <= sparse_shift_partial_result_systolic;
                        computation_ctrl.reset_accumulators                         <= sparse_reset_accumulator_systolic;
                        computation_ctrl.shift_output_steps_counter                 <= sparse_shift_output_steps_counter_systolic;
                        computation_ctrl.shift_output_steps_counter_finished_flag   <= sparse_shift_output_steps_counter_finished_flag;
                        computation_ctrl.last_column_finished                       <= sparse_reset_accumulator_systolic[1]; // used to enable reading last output from pe_array_1
                        computation_ctrl.kernel_step_index                          <= sparse_kernel_step_index_systolic;
                        o_update_latched_reg_file                                   <= sparse_update_latched_reg_file_systolic[2]; 

                        computation_ctrl.post_processing_shift_output_steps_counter                 <= post_processing_sparse_shift_output_steps_counter_systolic;
                        computation_ctrl.post_processing_shift_output_steps_counter_finished_flag   <= post_processing_sparse_shift_output_steps_counter_finished_flag;
                        computation_ctrl.post_processing_shift_partial_result                       <= post_processing_sparse_shift_partial_result_systolic;

                    end
                    DENSE_MODE: begin // DENSE mode
                        activations_systolic                                        <= dense_activations_systolic; 
                        valid_systolic                                              <= dense_valid_systolic;
                        computation_ctrl.delayed_shift_partial_result_flag          <= dense_delayed_shift_partial_result_flag;
                        computation_ctrl.shift_partial_result                       <= dense_shift_partial_result_systolic;
                        computation_ctrl.weight_memory_address                      <= dense_weight_address_systolic;
                        computation_ctrl.reset_accumulators                         <= dense_reset_accumulator_systolic;
                        computation_ctrl.shift_output_steps_counter                 <= dense_shift_output_steps_counter_systolic;
                        computation_ctrl.shift_output_steps_counter_finished_flag   <= dense_shift_output_steps_counter_finished_flag;
                        computation_ctrl.last_column_finished                       <= dense_reset_accumulator_systolic[1];
                        computation_ctrl.kernel_step_index                          <= dense_kernel_step_index_systolic;
                        o_update_latched_reg_file                                   <= dense_update_latched_reg_file_systolic[2];

                        computation_ctrl.post_processing_shift_output_steps_counter                 <= post_processing_dense_shift_output_steps_counter_systolic;
                        computation_ctrl.post_processing_shift_output_steps_counter_finished_flag   <= post_processing_dense_shift_output_steps_counter_finished_flag;
                        computation_ctrl.post_processing_shift_partial_result                       <= post_processing_dense_shift_partial_result_systolic;
                    end
                endcase
            end
        end
    end

endmodule