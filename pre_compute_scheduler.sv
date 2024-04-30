/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Pre-compute Scheduler
*   Date:   26.11.2021
*   Author: hasan
*   Description: This module performs two tasks; synchronizes the stream reader FSM using the decoded column values, and 
*       broadcasts the decoded data to the PE arrays. 
*/

/*  
    SPARSE mode: 
        - conv 3x3: 
            1.  Unrolled output pixels: 
                    - Each PE computes a different output_channel. (different kernels)
                    - Each PE_ARRAY computes a different output_column. 
            2.  Kernel steps: The non-zero activation's channel is used to fetch the corresponding channel group. This means that the kernels are unrolled across the PE_array. 
                    This might require kernel steps when the number of kernels is larger than the number of PEs in a PE_ARRAY.
        - pw: 
            1.  Unrolled output pixels: 
                    - Each PE computes a different output_channel. (different kernels)
                    - Each PE_ARRAY computes a different output_row.
            2.  Kernel steps: same as conv 3x3.
        - dilated conv: 
            1.  Unrolled output pixels: same as conv 3x3.
            2.  Kernel steps: same as conv 3x3.

    DENSE mode:
        - dw conv:
            1.  Unrolled output pixels: 
                    - Each PE computes a different output_channel. (different kernels)
                    - Each PE_ARRAY computes a different output_column.
            2.  Kernel steps: (Kernel_steps == channel_steps): Multiple activations are sent in parallel from different channels, and each PE uses one channel (==one kernel).
        - dw dilated conv: 
            1.  Unrolled output pixels: same as dw conv.
            2.  Kernel steps: same as dw conv.
        - conv 3x3:
            1.  Unrolled output pixels: 
                    - Each PE computes the same output_channel. (same kernel, different input channels)
                    - Each PE_ARRAY computes a different output_column. 
            2.  Kernel steps: Different PEs use different channels from the same kernel. This means that all the kernels are iterated one by one.
            3.  Channel steps: Multiple activations are sent in parallel from different channels, and each PE uses one channel. This might require channel steps when the number of channels is larger thant the number of PEs in a PE_ARRAY.
        - pw conv:
            1.  Unrolled output pixels: 
                    - Each PE computes the same output_channel. (same kernel, different input channels)
                    - Each PE_ARRAY computes a different output_row. 
            2.  Kernel steps:  Different PEs use different channels from the same kernel. This means that all the kernels are iterated one by one.
            3.  Channel steps: Multiple activations are sent in parallel from different channels, and each PE uses one channel. This might require channel steps when the number of channels is larger thant the number of PEs in a PE_ARRAY.
    */

`timescale 1ns / 1ps

module pre_compute_scheduler #(   
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
    register_file_if                      input_reg_file,
    register_file_if                     output_reg_file,
    streamed_data_if                streamed_data,
    decoded_data_if                 decoded_data,
    compute_core_data_if            compute_data,
    computation_control_if              computation_ctrl,
    input logic                     i_push_sync_word
);
    // -------------------------------------- 
    // ------ local reg_file latching
    // This is needed due to the dataflow nature of the accelerator.  
	// -------------------------------------- 
    logic update_latched_reg_file; 
    register_file_if #(.REGISTER_WIDTH(REGISTER_WIDTH)) latched_reg_file ();
    local_reg_file_latching latching_unit (
        .clk                            (clk),
        .resetn                         (resetn),    
        .i_first_latching_condition     (input_reg_file.execution_flag),
        .i_update_latching_condition    (update_latched_reg_file),
        .input_reg_file                 (input_reg_file),
        .latched_reg_file               (latched_reg_file),
        .output_reg_file                (output_reg_file)
    );

    // --------------------------------------
    // ------ PW conv fifos. 
    // This module sets compute_data.pw_data & compute_data.pw_valid
	// --------------------------------------
    logic pw_fifo_write_valid_condition; // i_pw_fifo_write_valid_condition <==> latched_reg_file.pw_conv
    // always_comb pw_fifo_write_valid_condition = latched_reg_file.pw_conv;
    always_comb pw_fifo_write_valid_condition = input_reg_file.pw_conv;
    logic pw_fifo_write_ready [NUMBER_OF_READ_STREAMS]; // used to control decoded_data stage, when pw conv is handled control.
    pw_conv_data_setup pw_data_setup (
        .clk                                (clk),
        .resetn                             (resetn),
        .i_pw_fifo_write_valid_condition    (pw_fifo_write_valid_condition),          
        .o_pw_fifo_write_ready              (pw_fifo_write_ready),                  
        .decoded_data                       (decoded_data),        
        .compute_data                       (compute_data)        
    );

    // --------------------------------------
    // ------ sparse conv fifos. 
    // This module sets compute_data.sparse_daata & compute_data.sparse_valid
	// --------------------------------------
    logic combined_fifo_write_valid_condition; // i_combined_fifo_write_valid_condition <==> latched_reg_file.stream_mode==SPARSE_MODE
    // always_comb combined_fifo_write_valid_condition = (latched_reg_file.stream_mode==SPARSE_MODE)? 1 : 0; 
    always_comb combined_fifo_write_valid_condition = (input_reg_file.stream_mode==SPARSE_MODE)? 1 : 0; 
    logic combined_fifo_write_ready; // used to control decoded_data stage, when sparse conv is handled control.
    sparse_conv_data_setup sparse_data_setup (
        .clk                                    (clk),
        .resetn                                 (resetn),
        .i_combined_fifo_write_valid_condition  (combined_fifo_write_valid_condition),          
        .o_combined_fifo_write_ready            (combined_fifo_write_ready),                  
        .i_push_sync_word                       (i_push_sync_word),
        .latched_reg_file                       (latched_reg_file),
        .decoded_data                           (decoded_data),        
        .compute_data                           (compute_data)        
    );

    // --------------------------------------
    // ------ dense conv setup. (no fifos) 
	// --------------------------------------
    // set compute_data dense signals 
    always_comb begin 
        compute_data.dense_data         = streamed_data.data; 
        compute_data.dense_data_valid   = streamed_data.valid; 
    end

    // --------------------------------------
    // ------ Set previous stages' "ready" signal(s). (decoded_data.ready - streamed_data.ready_from_pre_compute)
	// --------------------------------------
    always_comb begin
        // stream decoder stage (in SPARSE mode)
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            if (input_reg_file.pw_conv==1) begin // in pw SPARSE mode, the decoded streams use the pw_fifos -> pe_arrays.
                decoded_data.ready[i] = pw_fifo_write_ready[i];
            end
            else begin
                if(input_reg_file.stream_mode==SPARSE_MODE) begin // in other SPARSE modes (e.g. 3x3 conv), the decoded streams follow the combined_fifo -> valid_fifo -> pe_arrays pipeline. 
                    decoded_data.ready[i] = combined_fifo_write_ready;
                end
                else begin
                    decoded_data.ready[i] = 0;
                end
            end
        end

        // stream reader stage (in DENSE mode)
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            streamed_data.ready_from_pre_compute[i] = compute_data.dense_ready[i]; 
        end

    end

    // --------------------------------------
    // ------ Computation control unit 
	// -------------------------------------- 
    computation_control #(
        .REGISTER_WIDTH             (REGISTER_WIDTH),
        .NUMBER_OF_REGISTERS        (NUMBER_OF_REGISTERS),        
        .WEIGHT_LINE_BUFFER_DEPTH        (WEIGHT_LINE_BUFFER_DEPTH),        
        .CHANNEL_VALUE_BIT_WIDTH    (CHANNEL_VALUE_BIT_WIDTH)  
    ) computation_control_i(
        .clk                                    (clk),                                        
        .resetn                                 (resetn),    
        .i_input_reg_file_start_stream_readers  (input_reg_file.start_stream_readers),    
        .latched_reg_file                       (latched_reg_file), 
        .streamed_data                          (streamed_data),
        .compute_data                           (compute_data),
        .computation_ctrl                       (computation_ctrl),
        .o_update_latched_reg_file              (update_latched_reg_file)
    );


endmodule
