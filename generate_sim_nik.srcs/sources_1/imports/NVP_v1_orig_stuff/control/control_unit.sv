/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Control Unit
*   Date:   24.12.2021
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module control_unit #(   
    parameter int REGISTER_WIDTH                            = NVP_v1_constants::REGISTER_WIDTH, 
    parameter int NUMBER_OF_REGISTERS                       = NVP_v1_constants::NUMBER_OF_REGISTERS, 
    parameter int STREAM_1_PTR_REGISTER                     = NVP_v1_constants::STREAM_1_PTR_REGISTER,
    parameter int STREAM_2_PTR_REGISTER                     = NVP_v1_constants::STREAM_2_PTR_REGISTER,
    parameter int STREAM_3_PTR_REGISTER                     = NVP_v1_constants::STREAM_3_PTR_REGISTER,
    parameter int STREAM_WRITER_REGISTER                    = NVP_v1_constants::STREAM_WRITER_REGISTER,
    parameter int NUMBER_OF_CONV_LAYER_COLS_REGISTER        = NVP_v1_constants::NUMBER_OF_CONV_LAYER_COLS_REGISTER,
    parameter int EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER = NVP_v1_constants::EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER,
    parameter int NUMBER_OF_CHANNELS_REGISTER               = NVP_v1_constants::NUMBER_OF_CHANNELS_REGISTER,
    parameter int CHANNELS_MINUS_8_REGISTER                 = NVP_v1_constants::CHANNELS_MINUS_8_REGISTER,
    parameter int KERNEL_STEPS_MINUS_1_REGISTER             = NVP_v1_constants::KERNEL_STEPS_MINUS_1_REGISTER,
    parameter int NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER   = NVP_v1_constants::NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER,  
    parameter int CHANNEL_STEPS_REGISTER                    = NVP_v1_constants::CHANNEL_STEPS_REGISTER,
    parameter int ACTIVATION_BANK_BIT_WIDTH                 = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH, 
    parameter int ACTIVATION_BUFFER_BANK_COUNT              = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS         = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS, 
    parameter int NUMBER_OF_READ_STREAMS                    = NVP_v1_constants::NUMBER_OF_READ_STREAMS, 
    parameter int EXECUTION_FLAG_BIT_INDEX                  = NVP_v1_constants::EXECUTION_FLAG_BIT_INDEX,
    parameter int START_STREAM_READERS_BIT_INDEX            = NVP_v1_constants::START_STREAM_READERS_BIT_INDEX,
    parameter int STREAM_MODE_BIT_INDEX                     = NVP_v1_constants::STREAM_MODE_BIT_INDEX,
    parameter int PW_CONV_BIT_INDEX                         = NVP_v1_constants::PW_CONV_BIT_INDEX,
    parameter int ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX      = NVP_v1_constants::ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX,
    parameter int ELEMENT_WISE_ADD_BIT_INDEX                = NVP_v1_constants::ELEMENT_WISE_ADD_BIT_INDEX,
    parameter int BIAS_ENABLE_BIT_INDEX                     = NVP_v1_constants::BIAS_ENABLE_BIT_INDEX,
    parameter int RELU_ENABLE_BIT_INDEX                     = NVP_v1_constants::RELU_ENABLE_BIT_INDEX,
    parameter int STRIDED_CONV_BIT_INDEX                    = NVP_v1_constants::STRIDED_CONV_BIT_INDEX,
    // parameter int WEIGHT_PING_PONG_BIT_INDEX                = NVP_v1_constants::WEIGHT_PING_PONG_BIT_INDEX,
    parameter int WEIGHT_ADDRESS_OFFSET_REGISTER            = NVP_v1_constants::WEIGHT_ADDRESS_OFFSET_REGISTER,
    parameter int WEIGHT_ADDRESS_OFFSET_MSB                 = NVP_v1_constants::WEIGHT_ADDRESS_OFFSET_MSB,
    parameter int WEIGHT_ADDRESS_OFFSET_LSB                 = NVP_v1_constants::WEIGHT_ADDRESS_OFFSET_LSB,
    parameter int STREAM_READERS_PING_PONG_BIT_INDEX        = NVP_v1_constants::STREAM_READERS_PING_PONG_BIT_INDEX,
    parameter int STREAM_1_ENABLE_INDEX                     = NVP_v1_constants::STREAM_1_ENABLE_INDEX,
    parameter int STREAM_2_ENABLE_INDEX                     = NVP_v1_constants::STREAM_2_ENABLE_INDEX,
    parameter int STREAM_3_ENABLE_INDEX                     = NVP_v1_constants::STREAM_3_ENABLE_INDEX,
    parameter int CONTROL_AXI_DATA_WIDTH                    = NVP_v1_constants::CONTROL_AXI_DATA_WIDTH,
    parameter int CONTROL_AXI_ADDR_WIDTH                    = NVP_v1_constants::CONTROL_AXI_ADDR_WIDTH,
    parameter int NUMBER_OF_CHANNELS_MSB                    = NVP_v1_constants::NUMBER_OF_CHANNELS_MSB,
    parameter int NUMBER_OF_CHANNELS_LSB                    = NVP_v1_constants::NUMBER_OF_CHANNELS_LSB,
    parameter int CHANNELS_MINUS_8_MSB                      = NVP_v1_constants::CHANNELS_MINUS_8_MSB,
    parameter int CHANNELS_MINUS_8_LSB                      = NVP_v1_constants::CHANNELS_MINUS_8_LSB,
    parameter int KERNEL_STEPS_MINUS_1_MSB                  = NVP_v1_constants::KERNEL_STEPS_MINUS_1_MSB,
    parameter int KERNEL_STEPS_MINUS_1_LSB                  = NVP_v1_constants::KERNEL_STEPS_MINUS_1_LSB,
    parameter int NUMBER_OF_OUTPUT_SLICING_STEPS_MSB        = NVP_v1_constants::NUMBER_OF_OUTPUT_SLICING_STEPS_MSB,
    parameter int NUMBER_OF_OUTPUT_SLICING_STEPS_LSB        = NVP_v1_constants::NUMBER_OF_OUTPUT_SLICING_STEPS_LSB,
    parameter int CHANNEL_STEPS_MSB                         = NVP_v1_constants::CHANNEL_STEPS_MSB,
    parameter int CHANNEL_STEPS_LSB                         = NVP_v1_constants::CHANNEL_STEPS_LSB,
    parameter int BIAS_STEPS_REGISTER                       = NVP_v1_constants::BIAS_STEPS_REGISTER,
    parameter int BIAS_STEPS_MSB                            = NVP_v1_constants::BIAS_STEPS_MSB,
    parameter int BIAS_STEPS_LSB                            = NVP_v1_constants::BIAS_STEPS_LSB,
    parameter int NUMBER_OF_CONV_LAYER_COLS_MSB             = NVP_v1_constants::NUMBER_OF_CONV_LAYER_COLS_MSB,
    parameter int NUMBER_OF_CONV_LAYER_COLS_LSB             = NVP_v1_constants::NUMBER_OF_CONV_LAYER_COLS_LSB,
    parameter int EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB      = NVP_v1_constants::EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB,
    parameter int EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB      = NVP_v1_constants::EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB,
    parameter int STREAM_WRITER_ADDRESS_MSB                 = NVP_v1_constants::STREAM_WRITER_ADDRESS_MSB,
    parameter int STREAM_WRITER_ADDRESS_LSB                 = NVP_v1_constants::STREAM_WRITER_ADDRESS_LSB,
    parameter int QUANTIZATION_SCALE_REGISTER               = NVP_v1_constants::QUANTIZATION_SCALE_REGISTER,
    parameter int QUANTIZATION_SCALE_MSB                    = NVP_v1_constants::QUANTIZATION_SCALE_MSB,
    parameter int QUANTIZATION_SCALE_LSB                    = NVP_v1_constants::QUANTIZATION_SCALE_LSB,
    localparam CONTROL_FLAGS_REGISTER                       = NUMBER_OF_REGISTERS-1,
    localparam LINE_BUFFER_SELECTION_BIT_WIDTH              = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS)
)(
    input logic                     clk,
    input logic                     resetn,
    s_axi_lite_bus                  i_control_bus,
    register_file_if                reg_file,
    register_file_if                latched_reg_file,
    register_file_if                compute_latched_reg_file,
    control_and_stream_decoder_if   stream_decoder_ctrl,
    output logic                    o_push_sync_word,
    output logic                    o_next_command_interrupt
);
    
    // Control register file
    logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];   
    control_memory #(   
        .REGISTER_WIDTH         (REGISTER_WIDTH),
        .NUMBER_OF_REGISTERS    (NUMBER_OF_REGISTERS),
        .AXI_DATA_WIDTH         (CONTROL_AXI_DATA_WIDTH),
        .AXI_ADDR_WIDTH         (CONTROL_AXI_ADDR_WIDTH)
    ) control_register_file (
        .clk                        (clk),
        .resetn                     (resetn),
        .i_control_bus              (i_control_bus),
        .i_output_line_end_address  (compute_latched_reg_file.output_line_end_address),
        .o_register_file            (register_file)
    );

    // --------------------------------------
    // ------ Control register file
	// --------------------------------------
    logic start_stream_readers_comb, start_stream_readers_ff;
    logic execution_flag_comb, execution_flag_ff;
    // Read control values from register file
    always_comb begin
        // reg_file.execution_flag                 = register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX]; // starts execution
        reg_file.stream_mode                        = register_file[CONTROL_FLAGS_REGISTER][STREAM_MODE_BIT_INDEX]; // either sparse or dense mode. 
        reg_file.pw_conv                            = register_file[CONTROL_FLAGS_REGISTER][PW_CONV_BIT_INDEX]; // if layer type is pw conv. 
        reg_file.strided_conv                       = register_file[CONTROL_FLAGS_REGISTER][STRIDED_CONV_BIT_INDEX]; // if the conv is a strided conv (only stride=2 is supported.)
        // reg_file.weight_ping_or_pong                = register_file[CONTROL_FLAGS_REGISTER][WEIGHT_PING_PONG_BIT_INDEX]; // ping-pong buffer         
        reg_file.enable_element_wise_buffer         = register_file[CONTROL_FLAGS_REGISTER][ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX]; // element-wise addition
        reg_file.element_wise_add                   = register_file[CONTROL_FLAGS_REGISTER][ELEMENT_WISE_ADD_BIT_INDEX]; // element-wise addition
        reg_file.bias_enable                        = register_file[CONTROL_FLAGS_REGISTER][BIAS_ENABLE_BIT_INDEX]; // perform convolution with or without bias
        reg_file.q_scale                            = register_file[QUANTIZATION_SCALE_REGISTER][QUANTIZATION_SCALE_MSB:QUANTIZATION_SCALE_LSB]; // 
        reg_file.relu                               = register_file[CONTROL_FLAGS_REGISTER][RELU_ENABLE_BIT_INDEX]; // 
        reg_file.weight_address_offset              = register_file[WEIGHT_ADDRESS_OFFSET_REGISTER][WEIGHT_ADDRESS_OFFSET_MSB:WEIGHT_ADDRESS_OFFSET_LSB]; 
        reg_file.number_of_channels                 = register_file[NUMBER_OF_CHANNELS_REGISTER][NUMBER_OF_CHANNELS_MSB:NUMBER_OF_CHANNELS_LSB]; // number of channels minus 8. used in sparse mode compressed stream readers. 
        reg_file.channels_minus_8                   = register_file[CHANNELS_MINUS_8_REGISTER][CHANNELS_MINUS_8_MSB:CHANNELS_MINUS_8_LSB]; // number of channels minus 8. used in sparse mode compressed stream readers. 
        reg_file.kernel_steps_minus_1               = register_file[KERNEL_STEPS_MINUS_1_REGISTER][KERNEL_STEPS_MINUS_1_MSB:KERNEL_STEPS_MINUS_1_LSB]; // ?
        reg_file.number_of_output_slicing_steps     = register_file[NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER][NUMBER_OF_OUTPUT_SLICING_STEPS_MSB:NUMBER_OF_OUTPUT_SLICING_STEPS_LSB]; // ?
        reg_file.channel_steps                      = register_file[CHANNEL_STEPS_REGISTER][CHANNEL_STEPS_MSB:CHANNEL_STEPS_LSB];
        reg_file.bias_steps                         = register_file[BIAS_STEPS_REGISTER][BIAS_STEPS_MSB:BIAS_STEPS_LSB];
        reg_file.number_of_conv_layer_columns       = register_file[NUMBER_OF_CONV_LAYER_COLS_REGISTER][NUMBER_OF_CONV_LAYER_COLS_MSB:NUMBER_OF_CONV_LAYER_COLS_LSB]; // number of columns
        reg_file.expected_total_number_of_outputs   = register_file[EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER][EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB:EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB]; 
        reg_file.stream_writer_ptr                  = register_file[STREAM_WRITER_REGISTER][STREAM_WRITER_ADDRESS_MSB:STREAM_WRITER_ADDRESS_LSB];
        reg_file.stream_1_ptr                       = register_file[STREAM_1_PTR_REGISTER];
        reg_file.stream_2_ptr                       = register_file[STREAM_2_PTR_REGISTER];
        reg_file.stream_3_ptr                       = register_file[STREAM_3_PTR_REGISTER];
        reg_file.stream_1_enable                    = register_file[CONTROL_FLAGS_REGISTER][STREAM_1_ENABLE_INDEX];
        reg_file.stream_2_enable                    = register_file[CONTROL_FLAGS_REGISTER][STREAM_2_ENABLE_INDEX];
        reg_file.stream_3_enable                    = register_file[CONTROL_FLAGS_REGISTER][STREAM_3_ENABLE_INDEX];
        execution_flag_comb                         = register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX]; // starts execution
        reg_file.execution_flag                     = (execution_flag_ff==execution_flag_comb)? 0 : 1; 
        start_stream_readers_comb                   = register_file[CONTROL_FLAGS_REGISTER][START_STREAM_READERS_BIT_INDEX]; // starts stream readers             
        reg_file.start_stream_readers               = (start_stream_readers_ff==start_stream_readers_comb)? 0 : 1; 
    end
    always_ff @(posedge clk) begin // flip these bit to trigger 
        if(resetn==0) begin
            start_stream_readers_ff <= 0;
            execution_flag_ff       <= 0;
        end
        else begin 
            start_stream_readers_ff <= start_stream_readers_comb;                
            execution_flag_ff       <= execution_flag_comb;
        end
    end
    

    // --------------------------------------
    // ------ Instantiate control modules
	// --------------------------------------
    execution_control #(   
        .REGISTER_WIDTH       (REGISTER_WIDTH),
        .NUMBER_OF_REGISTERS  (NUMBER_OF_REGISTERS)
    ) execution_control_unit (
        .clk                        (clk),
        .resetn                     (resetn),
        .reg_file                   (reg_file),
        .latched_reg_file           (latched_reg_file),
        .stream_decoder_ctrl        (stream_decoder_ctrl),
        .o_push_sync_word           (o_push_sync_word),
        .o_next_command_interrupt   (o_next_command_interrupt)
    );
    
    // // -------------------------------------- TODO:: create a debug_control macro. 
    // // --------------------------------------
    // // DEBUG ONLY
    // // --------------------------------------
    // // --------------------------------------
    // generate 
    //     if (DEBUG_CONTROL) begin
    //         activation_buffer_control_if #(
    //             .ACTIVATION_BANK_BIT_WIDTH	    (ACTIVATION_BANK_BIT_WIDTH),
    //             .ACTIVATION_BUFFER_BANK_COUNT	    (ACTIVATION_BUFFER_BANK_COUNT),
    //             .NUMBER_OF_ACTIVATION_LINE_BUFFERS	(NUMBER_OF_ACTIVATION_LINE_BUFFERS)
    //         ) activation_buffer_ctrl ();
            
    //         activation_buffer_read_control #(   
    //             .REGISTER_WIDTH       (REGISTER_WIDTH),
    //             .NUMBER_OF_REGISTERS  (NUMBER_OF_REGISTERS)
    //         ) activation_buffer_read_control_unit (
    //             .clk                        (clk),
    //             .resetn                     (resetn),
    //             .activation_buffer_ctrl     (activation_buffer_ctrl.control),
    //             .latched_reg_file           (latched_reg_file),
    //             .o_stream_read_data         (), 
    //             .o_stream_read_valid        (),
    //             .i_stream_read_ready        ()
    //         );
    //         activation_buffer_external_write_control #(   
    //             .REGISTER_WIDTH       (REGISTER_WIDTH),
    //             .NUMBER_OF_REGISTERS  (NUMBER_OF_REGISTERS)
    //         ) activation_buffer_external_write_control_unit (
    //             .clk                        (clk),
    //             .resetn                     (resetn),
    //             .activation_buffer_ctrl     (activation_buffer_ctrl.control),
    //             .reg_file                   (reg_file),
    //             .latched_reg_file           (latched_reg_file),
    //             .o_weight_memory_data       (),
    //             .o_weight_memory_valid      (),
    //             .o_weight_memory_last       (),
    //             .i_weight_memory_ready      ()
    //         );
    //     end
    // endgenerate
    // // --------------------------------------
    // // -------------------------------------- TODO:: delete after debug
    
endmodule
