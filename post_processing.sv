/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Post-Processing module
*   Date:  07.02.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

// import NVP_v1_constants::*;

module post_processing #(    
    parameter int REGISTER_WIDTH                                    = NVP_v1_constants::REGISTER_WIDTH,
    parameter int ACTIVATION_BIT_WIDTH                              = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int ACTIVATION_BANK_BIT_WIDTH                         = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW                       = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,
    parameter int NUMBER_OF_PES_PER_ARRAY                           = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,
    parameter int COLUMN_VALUE_BIT_WIDTH                            = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ACCUMULATOR_BIT_WIDTH                             = NVP_v1_constants::ACCUMULATOR_BIT_WIDTH,
    parameter int OUTPUT_FIFO_DEPTH                                 = NVP_v1_constants::OUTPUT_FIFO_DEPTH,
    parameter int OUTPUT_STAGE_FIFO_DEPTH                           = NVP_v1_constants::OUTPUT_STAGE_FIFO_DEPTH,
    parameter int SPARSE_MODE                                       = NVP_v1_constants::SPARSE_MODE,
    parameter int DENSE_MODE                                        = NVP_v1_constants::DENSE_MODE,
    parameter int SUPPORTED_MAX_NUMBER_OF_PES_PER_ARRAY             = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_PES_PER_ARRAY,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS              = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    parameter int SUPPORTED_MAX_NUMBER_OF_COLUMNS                   = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_COLUMNS,
    parameter int SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS,
    parameter int OUTPUT_WRITER_ADDRESS_BIT_WIDTH                   = NVP_v1_constants::OUTPUT_WRITER_ADDRESS_BIT_WIDTH,
    parameter int ACTIVATION_MIN_VALUE                              = NVP_v1_constants::ACTIVATION_MIN_VALUE,
    parameter int ACTIVATION_MAX_VALUE                              = NVP_v1_constants::ACTIVATION_MAX_VALUE,
    parameter int BIAS_BIT_WIDTH                                    = NVP_v1_constants::BIAS_BIT_WIDTH,
    parameter int BIAS_BIT_WIDTH_AXI                                = NVP_v1_constants::BIAS_BIT_WIDTH_AXI,
    parameter int QUANTIZATION_SCALE_BIT_WIDTH                      = NVP_v1_constants::QUANTIZATION_SCALE_BIT_WIDTH,
    localparam int HALF_ACTIVATION_BIT_WIDTH                        = ACTIVATION_BIT_WIDTH/2,
    localparam int MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE             = SUPPORTED_MAX_NUMBER_OF_COLUMNS*SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS
)(
    input  logic                                        clk,
    input  logic                                        resetn,
    register_file_if                                    global_latched_reg_file, 
    register_file_if                                    input_reg_file, 
    register_file_if                                    output_reg_file, 
    streamed_data_if                                    streamed_data,
    decoded_data_if                                     decoded_data,
    computation_control_if                              computation_ctrl,
    compute_core_data_if                                compute_data,
    input logic [ACCUMULATOR_BIT_WIDTH-1:0]             i_output_activations  [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS],
    output logic [ACTIVATION_BANK_BIT_WIDTH-1:0]        o_output_array,
    output logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]  o_output_address,
    output logic                                        o_output_valid,
    output logic                                        o_output_line_stored,

    output logic unsigned [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]    debug_quantized_activations, 
    output logic                                        debug_quantized_activations_valid
);

    logic [(ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH)-1:0] ZEROS; 
    always_comb ZEROS = '{default:0};
    logic [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0] ZEROS_;
    always_comb ZEROS_ = 0;

    // --------------------------------------
    // ------ local reg_file latching
    // This is needed due to the dataflow nature of the accelerator.  
	// -------------------------------------- 
    logic update_latched_reg_file; 
    logic latch_flag;
    logic update_latched_reg_file_to_output_address_latch_flag; // this will be high when "update_latched_reg_file" is asserted, until the output_address "latch_flag" is high...
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

    // latch "decoded_data.toggled_column" to detect change.
    logic [COLUMN_VALUE_BIT_WIDTH-1:0] decoded_word_toggled_column_ff;
    always_ff @(posedge clk) begin 
        if(resetn==0)begin
            decoded_word_toggled_column_ff <= '0;
        end
        else begin
            decoded_word_toggled_column_ff <= decoded_data.toggled_column[1];
        end
    end

    // output pixel counter logic 
    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0] output_pixel_counter [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0] expected_total_number_of_outputs;
    // FSMs for different operation modes 
    enum logic {DROPPING, READING} conv_3x3_drop_first_output_fsm, conv_3x3_read_last_output_fsm, strided_conv_3x3_drop_output_fsm;
    logic pixel_counter_on;
    always_comb pixel_counter_on = (conv_3x3_drop_first_output_fsm==READING) || (conv_3x3_read_last_output_fsm==READING) || (output_pixel_counter[0]==0) || (strided_conv_3x3_drop_output_fsm==READING);
    // sparse_conv_3x3 logic 
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            conv_3x3_drop_first_output_fsm <= DROPPING;
        end
        else begin
            if(latched_reg_file.pw_conv==0 && latched_reg_file.strided_conv==0) begin
                if (conv_3x3_drop_first_output_fsm==DROPPING) begin
                    // if (computation_ctrl.shift_output_steps_counter_finished_flag==1) begin
                    //     conv_3x3_drop_first_output_fsm <= READING;
                    // end

                    // todo: fixme hasan
                    // if (output_pixel_counter[0]==latched_reg_file.kernel_steps_minus_1+1) begin
                    if (output_pixel_counter[0]==1 && computation_ctrl.post_processing_shift_partial_result[0]==0) begin
                    // if (computation_ctrl.shift_partial_result[0]==1 && output_pixel_counter[0]==latched_reg_file.kernel_steps_minus_1) begin
                        conv_3x3_drop_first_output_fsm <= READING;
                    end
                end
                else begin // READING
                    // if (output_pixel_counter[0]==expected_total_number_of_outputs-latched_reg_file.kernel_steps_minus_1) begin
                    if (output_pixel_counter[0]==0) begin // the condition above should be true. but I am trying this simpler solution.
                        conv_3x3_drop_first_output_fsm <= DROPPING;
                    end
                end
            end
        end  
    end
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            conv_3x3_read_last_output_fsm <= DROPPING;
        end
        else begin
            if(latched_reg_file.pw_conv==0 && latched_reg_file.strided_conv==0) begin
                if (conv_3x3_read_last_output_fsm==DROPPING) begin
                    // if (output_pixel_counter[1]==expected_total_number_of_outputs-latched_reg_file.kernel_steps_minus_1-1) begin
                    if (output_pixel_counter[1]==expected_total_number_of_outputs-2*(latched_reg_file.kernel_steps_minus_1+1)+1) begin
                        conv_3x3_read_last_output_fsm <= READING;
                    end
                end
                else begin //READING
                    //todo: fixme hasan
                    // if (output_pixel_counter[1]==expected_total_number_of_outputs-latched_reg_file.kernel_steps_minus_1) begin
                    if (output_pixel_counter[1]==0) begin // the condition above should be true. but I am trying this simpler solution.
                        conv_3x3_read_last_output_fsm <= DROPPING;
                    end
                end
            end
        end  
    end
    // strided sparse_conv_3x3 logic
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            strided_conv_3x3_drop_output_fsm <= DROPPING;
        end
        else begin
            if(latched_reg_file.strided_conv==1) begin
                if (strided_conv_3x3_drop_output_fsm==DROPPING) begin
                    if (computation_ctrl.post_processing_shift_output_steps_counter_finished_flag==1) begin
                        strided_conv_3x3_drop_output_fsm <= READING;
                    end
                end
                else begin // READING
                    if (computation_ctrl.post_processing_shift_output_steps_counter_finished_flag==1) begin
                        strided_conv_3x3_drop_output_fsm <= DROPPING;
                    end
                end
            end
        end  
    end
    always_comb expected_total_number_of_outputs = latched_reg_file.expected_total_number_of_outputs; 
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            output_pixel_counter    <= '{default:0};
            update_latched_reg_file <= 0;
        end
        else begin
            if (output_pixel_counter[0]==expected_total_number_of_outputs-latched_reg_file.kernel_steps_minus_1) begin
                output_pixel_counter[0] <= 0;
            end 
            else begin
                // if(computation_ctrl.shift_partial_result[0]==1) begin
                if(computation_ctrl.post_processing_shift_partial_result[0]==1 && pixel_counter_on==1) begin
                    output_pixel_counter[0] <= output_pixel_counter[0] + 1;
                end
            end
                output_pixel_counter[1] <= output_pixel_counter[0]; //TODO:: check if needed.
                output_pixel_counter[2] <= output_pixel_counter[1];

                // update local register file
                // if(output_pixel_counter[0]==0) begin
                if(output_pixel_counter[0]==0) begin
                    update_latched_reg_file <= 1; //TODO:: check that output address generation and output storing is correct
                end
                else begin
                    update_latched_reg_file <= 0;
                end
        end
    end

    // --------------------------------------
    // ------ Output post-processing pipeline 
	// --------------------------------------
    // --------------
    // Step 1: Latch valid outputs when valid (depending on operation mode)
	// --------------
    logic [ACCUMULATOR_BIT_WIDTH-1:0]       output_activations  [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY];
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0] output_activations_valid;
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0] operation_mode_output_valid_control;
    // opeartion mode logic -> used to generate "operation_mode_output_valid_control"
    logic [1:0] concatenated_operation_mode; //TODO:: dilated convolution?
    always_comb concatenated_operation_mode = {latched_reg_file.pw_conv, latched_reg_file.strided_conv};
    always_comb begin // set "operation_mode_output_valid_control" bits to control output activations valid. In different operation modes, different outputs are dropped. 
        case (concatenated_operation_mode)
            2'b00: begin // 3x3 conv 
                // always drop "pe_array_2" output 
                operation_mode_output_valid_control[2] = 0;

                // drop first "pe_array_0" output (all kernel_steps)
                operation_mode_output_valid_control[0] = (conv_3x3_drop_first_output_fsm==DROPPING)? 0 : 1;

                // read last "pe_array_1" output (all kernel_steps)
                // operation_mode_output_valid_control[1] = computation_ctrl.last_column_finished;
                operation_mode_output_valid_control[1] = (conv_3x3_read_last_output_fsm==READING)? 1 : 0;
            end
            2'b01: begin // 3x3 strided conv
                operation_mode_output_valid_control[2] = 0; 
                operation_mode_output_valid_control[1] = 0; 
                operation_mode_output_valid_control[0] = (strided_conv_3x3_drop_output_fsm==READING)? 1 : 0; 
            end
            2'b10: begin // 1x1 conv
                operation_mode_output_valid_control = 3'b111;
            end
            default: begin
                operation_mode_output_valid_control = 3'b000;
            end
        endcase
    end
    // latch valid incoming i_output_activations
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            output_activations          <= '{default:0};
            output_activations_valid    <= '0;
        end
        else begin
            for (int j=0; j<NUMBER_OF_PE_ARRAYS_PER_ROW; j++) begin
                if(computation_ctrl.post_processing_shift_partial_result[j]==1) begin
                    output_activations_valid[j]    <= operation_mode_output_valid_control[j];
                    for (int i=0; i<NUMBER_OF_PES_PER_ARRAY; i++) begin
                        // output_activations[j][i]   <= i_output_activations[j][i][computation_ctrl.shift_output_steps_counter[j]];
                        output_activations[j][i]   <= i_output_activations[j][i][computation_ctrl.post_processing_shift_output_steps_counter[j]];
                    end
                end
                else begin
                    output_activations_valid[j]    <= 0;
                end    
            end
        end
    end
    

    // --------------
    // Step 2: Buffer valid output activations in the corresponding FIFO
	// --------------
    //output fifo signals
    localparam int ACTIVATION_BIT_WIDTH_NUMBER_OF_BITS          = $clog2(ACTIVATION_BIT_WIDTH);
    localparam int OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_PES_PER_ARRAY/ACTIVATION_BIT_WIDTH);
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH               = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS);
    localparam int CONCATENATED_FLAGS_BIT_WIDTH                 = 5 + OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH + KERNEL_STEPS_COUNTER_BIT_WIDTH;
    logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]                    output_fifo_write_concatenated_flags;
    logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]                    output_fifo_read_concatenated_flags [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [ACCUMULATOR_BIT_WIDTH*NUMBER_OF_PES_PER_ARRAY-1:0]   output_fifo_write_data  [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     output_fifo_write_valid;
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     output_fifo_write_ready;
    logic [ACCUMULATOR_BIT_WIDTH*NUMBER_OF_PES_PER_ARRAY-1:0]   output_fifo_read_data   [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     output_fifo_read_valid;
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     output_fifo_read_ready;
    logic                                                   output_stage_fifo_write_ready; // comes from output stage fifo
    logic                                                   output_fifo_empty[NUMBER_OF_PE_ARRAYS_PER_ROW]; 

    // Instantiate fifos
    generate 
        for (genvar i=0; i < NUMBER_OF_PE_ARRAYS_PER_ROW-1; i++) begin : output_fifo_i
            axis_fifo_v3 #(
                .AXIS_BUS_WIDTH (ACCUMULATOR_BIT_WIDTH*NUMBER_OF_PES_PER_ARRAY+CONCATENATED_FLAGS_BIT_WIDTH),
                .FIFO_DEPTH     (OUTPUT_FIFO_DEPTH) 
            ) output_fifo_i (
                .m_axi_aclk     (clk),
                .m_axi_aresetn  (resetn),
                .s_axis_tdata   ({output_fifo_write_data[i], output_fifo_write_concatenated_flags}),
                .s_axis_tvalid  (output_fifo_write_valid[i]),
                .s_axis_tready  (output_fifo_write_ready[i]),
                .m_axis_tdata   ({output_fifo_read_data[i], output_fifo_read_concatenated_flags[i]}),
                .m_axis_tvalid  (output_fifo_read_valid[i]),
                .m_axis_tready  (output_fifo_read_ready[i] && output_stage_fifo_write_ready),
                .o_empty        (output_fifo_empty[i]) //TODO:: remove me.
            );
        end
    endgenerate
    // output slicing steps
    logic [OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH-1:0] output_slicing_add_steps; // calculate steps from register file values
    always_comb begin
        output_slicing_add_steps = latched_reg_file.number_of_output_slicing_steps;
        // output_slicing_add_steps = NUMBER_OF_PES_PER_ARRAY>>3; // TODO:: fix now
    end
    // buffered flags
    localparam int LOCAL_ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX   = 0; // enable element-wise add buffer write port. 
    localparam int LOCAL_ELEMENT_WISE_ADD_BIT_INDEX             = 1; // perform the actual element-wise addition
    localparam int LOCAL_STRIDED_CONV_BIT_INDEX                 = 2;
    localparam int LOCAL_BIAS_ENABLE_BIT_INDEX                  = 3;
    localparam int LOCAL_STREAM_MODE_BIT_INDEX                  = 4;
    localparam int LOCAL_OUTPUT_SLICING_STEPS_MSB               = LOCAL_STREAM_MODE_BIT_INDEX+OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH;
    localparam int LOCAL_KERNEL_STEPS_MSB                       = LOCAL_OUTPUT_SLICING_STEPS_MSB+KERNEL_STEPS_COUNTER_BIT_WIDTH;
    always_comb output_fifo_write_concatenated_flags[LOCAL_STRIDED_CONV_BIT_INDEX]                                              = latched_reg_file.strided_conv;
    always_comb output_fifo_write_concatenated_flags[LOCAL_STREAM_MODE_BIT_INDEX]                                               = latched_reg_file.stream_mode;
    always_comb output_fifo_write_concatenated_flags[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]                                          = latched_reg_file.element_wise_add;
    always_comb output_fifo_write_concatenated_flags[LOCAL_BIAS_ENABLE_BIT_INDEX]                                               = latched_reg_file.bias_enable;
    always_comb output_fifo_write_concatenated_flags[LOCAL_ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX]                                = latched_reg_file.enable_element_wise_buffer;
    always_comb output_fifo_write_concatenated_flags[LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]    = output_slicing_add_steps-1;
    always_comb output_fifo_write_concatenated_flags[LOCAL_KERNEL_STEPS_MSB-:KERNEL_STEPS_COUNTER_BIT_WIDTH]                    = latched_reg_file.kernel_steps_minus_1;


    logic [OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH-1:0] debug_output_fifo_read_ouptut_slicing_add_steps;
    always_comb debug_output_fifo_read_ouptut_slicing_add_steps =  output_fifo_read_concatenated_flags[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH];
    

    // connect output_fifo write signals
    always_comb begin
        output_fifo_write_valid = output_activations_valid;
        // output_fifo_write_ready -> TODO:: use to stall pe_array if needed. 
        for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
                output_fifo_write_data[i][(j+1)*ACCUMULATOR_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH] = output_activations[i][j];
            end
        end
    end


    // --------------
    // Step 3: Read buffered valid output activations from the fifos, and schedule their entry into the next stages
    // After this step, the outputs are inserted into a common pipeline. (the three pe_arrays' outputs are gathered (when valid)).
	// --------------
    // Valid outputs from pe arrays are scheduled to be post-processed sequentially. 
    // It depends on the operating mode. 
    // In sparse 3x3 conv mode, outputs are always read from pe_array_0, except first pixel (is dropped) and last pixel (is read from pe_array_1).
    // In sparse 1x1 conv mode, outputs are read from all pe_arrays
	// --------------------------------------
    enum logic[1:0] {CHECK, FIRST, SECOND, THIRD}               scheduling_valid_outputs_fsm;
    logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]                    scheduled_output_concatenated_flags;
    logic                                                       scheduled_output_activations_valid;
    logic                                                       increment_scheduled_output_activations_counter;
    logic [OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH-1:0]          output_slicing_steps_counter; 

    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0]    scheduled_output_activations_counter;
    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0]    scheduled_output_activations_expected_total_number_of_outputs;
    logic                                                       scheduled_output_activations_last;
    logic                                                       read_flag;
    logic [ACCUMULATOR_BIT_WIDTH*NUMBER_OF_PES_PER_ARRAY-1:0]   output_fifo_read_data_ff   [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [ACCUMULATOR_BIT_WIDTH*NUMBER_OF_PES_PER_ARRAY-1:0]   output_fifo_read_data_ff_shift_reg   [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     output_fifo_read_valid_ff;
    logic [NUMBER_OF_PE_ARRAYS_PER_ROW-1:0]                     latch_output_fifo_read_valid;
    logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]                    output_fifo_read_concatenated_flags_ff [NUMBER_OF_PE_ARRAYS_PER_ROW];
    always_ff @(posedge clk) begin // latch fifo output
        if(resetn==0) begin   
            output_fifo_read_data_ff                <= '{default:0};
            output_fifo_read_concatenated_flags_ff  <= '{default:0};
            output_fifo_read_valid_ff               <= '0;
        end
        else begin
            if(output_stage_fifo_write_ready==1)begin
                for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                    // if(output_fifo_read_ready[i]==1) begin
                    // if(output_fifo_read_valid[i]==1) begin
                    // if(output_fifo_read_valid_ff[i]==0) begin 
                    if(latch_output_fifo_read_valid[i]==1 && output_fifo_read_valid_ff[i]==0) begin
                        output_fifo_read_data_ff[i]                 <= output_fifo_read_data[i];
                        output_fifo_read_concatenated_flags_ff[i]   <= output_fifo_read_concatenated_flags[i];
                        output_fifo_read_valid_ff[i]                <= output_fifo_read_valid[i];
                    end
                    else begin
                        // output_fifo_read_valid_ff[i] <= (scheduling_valid_outputs_fsm==SECOND)? 0 : output_fifo_read_valid_ff[i];
                        if(i==1) begin
                            output_fifo_read_valid_ff[i] <= (scheduling_valid_outputs_fsm==SECOND)? 0 : output_fifo_read_valid_ff[i];
                        end 
                        else begin
                            output_fifo_read_valid_ff[i] <= 0;
                        end 
                    end
                end
            end
        end
    end



    // always_comb output_fifo_write_concatenated_flags[LOCAL_STREAM_MODE_BIT_INDEX]               = latched_reg_file.stream_mode;
    // always_comb output_fifo_write_concatenated_flags[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]          = latched_reg_file.element_wise_add;
    // always_comb output_fifo_write_concatenated_flags[LOCAL_ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX]   = latched_reg_file.enable_element_wise_buffer;
    // always_comb output_fifo_write_concatenated_flags[LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]   = output_slicing_add_steps-1;
    // always_comb output_fifo_write_concatenated_flags[LOCAL_KERNEL_STEPS_MSB-:KERNEL_STEPS_COUNTER_BIT_WIDTH]   = latched_reg_file.kernel_steps_minus_1;

    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0] debug_scheduled_counter_last_condition;
    always_comb debug_scheduled_counter_last_condition = scheduled_output_activations_expected_total_number_of_outputs-1;
    always_comb scheduled_output_activations_last = (debug_scheduled_counter_last_condition==scheduled_output_activations_counter) && increment_scheduled_output_activations_counter;
    // always_comb scheduled_output_activations_last = (debug_scheduled_counter_last_condition==scheduled_output_activations_counter) && scheduled_output_activations_valid;

    logic [$clog2(MAX_NUMBER_OF_VALID_OUTPUTS_PER_LINE)-1:0] debug_prioritize_second_condition;
    always_comb debug_prioritize_second_condition = debug_scheduled_counter_last_condition- output_fifo_read_concatenated_flags_ff[0][LOCAL_KERNEL_STEPS_MSB-:KERNEL_STEPS_COUNTER_BIT_WIDTH]-1;

    always_ff @(posedge clk) begin 
        if(resetn==0) begin
            scheduled_output_activations_counter                            <= '{default:0};
            scheduled_output_activations_expected_total_number_of_outputs   <= '{default:0};
            read_flag <= 1;
        end
        else begin 
            if(output_stage_fifo_write_ready==1)begin
                if(read_flag==1) begin
                    // scheduled_output_activations_expected_total_number_of_outputs   <= expected_total_number_of_outputs;
                    scheduled_output_activations_expected_total_number_of_outputs   <= expected_total_number_of_outputs - latched_reg_file.strided_conv;
                    if(latch_flag==1 && latched_reg_file.execution_flag) begin //todo:: check me (used to be "latched_reg_file.execution_flag")
                        read_flag <= 0;
                    end
                end
                else begin
                    if(increment_scheduled_output_activations_counter==1) begin
                        if(scheduled_output_activations_counter==debug_scheduled_counter_last_condition) begin

                            scheduled_output_activations_counter    <= 0;
                            read_flag <= 1;
                        end
                        else begin
                            scheduled_output_activations_counter    <= scheduled_output_activations_counter + 1;
                        end
                    end
                end
            end
        end
    end
    logic prioritize_second_fifo_flag;
    always_ff @(posedge clk) begin // scheduling fsm + element-wise counting logic
        if(resetn==0) begin
            scheduling_valid_outputs_fsm                    <= CHECK;
            output_slicing_steps_counter                    <= 0;
            increment_scheduled_output_activations_counter  <= 0;
            output_fifo_read_ready                          <= '{default:1}; 
            prioritize_second_fifo_flag                     <= 0;     
            output_fifo_read_data_ff_shift_reg              <= '{default:0};
            latch_output_fifo_read_valid                    <= '{default:1}; 
        end
        else begin
            if(output_stage_fifo_write_ready==1)begin
                for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                    if(output_fifo_read_ready[i]==1) begin
                        // output_fifo_read_ready[i] <= (output_fifo_read_valid[i]==1)? 0 : 1;
                        output_fifo_read_ready[i] <= (output_fifo_empty[i]==0)? 0 : 1;
                    end
                end
                // if(scheduled_output_activations_counter==scheduled_output_activations_expected_total_number_of_outputs)
                case(scheduling_valid_outputs_fsm)
                    CHECK: begin 
                        increment_scheduled_output_activations_counter  <= 0;
                        
                        if(prioritize_second_fifo_flag==0) begin
                            if (output_fifo_read_valid_ff[0]) begin  //TODO:: check me
                                scheduling_valid_outputs_fsm    <= FIRST;
                                output_fifo_read_data_ff_shift_reg[0] <= output_fifo_read_data_ff[0];
                                latch_output_fifo_read_valid[0] <= 0;

                                if(output_fifo_read_concatenated_flags_ff[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]==0) begin
                                    increment_scheduled_output_activations_counter  <= 1;
                                    output_fifo_read_ready[0]                       <= 1;
                                end
                            end
                            else begin
                                scheduling_valid_outputs_fsm    <= CHECK; 
                            end 
                        end
                        else begin
                            if (output_fifo_read_valid_ff[1]) begin  //TODO:: check me
                                scheduling_valid_outputs_fsm    <= SECOND; 
                                // output_fifo_read_data_ff_shift_reg[1] <= output_fifo_read_data[1];
                                output_fifo_read_data_ff_shift_reg[1] <= output_fifo_read_data_ff[1]; // 
                                latch_output_fifo_read_valid[1] <= 0;

                                // increment_scheduled_output_activations_counter  <= (output_fifo_read_concatenated_flags_ff[1][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]==0)? 1 : 0;
                                if(output_fifo_read_concatenated_flags_ff[1][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]==0) begin
                                    increment_scheduled_output_activations_counter  <= 1;
                                    output_fifo_read_ready[1]                       <= 1;
                                end
                            end
                            else begin
                                scheduling_valid_outputs_fsm    <= CHECK; 
                            end 
                        end


                    end
                    FIRST: begin // shift register 0
                        // output_fifo_read_data_ff[0] <= output_fifo_read_data_ff[0] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        // output_fifo_read_data_ff_shift_reg[0] <= output_fifo_read_data_ff[0] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        output_fifo_read_data_ff_shift_reg[0] <= output_fifo_read_data_ff_shift_reg[0] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 

                        // if no/finished element_wise steps, then set ready to high, and go to next state.
                        if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]) begin 
                        // if(output_slicing_steps_counter==output_fifo_read_concatenated_flags[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]) begin 
                            output_slicing_steps_counter                    <= '{default:0};
                            // output_fifo_read_ready[0]                       <= 1;
                            latch_output_fifo_read_valid[0] <= 1;
                            // increment_scheduled_output_activations_counter  <= 0;                            
                            increment_scheduled_output_activations_counter  <= (increment_scheduled_output_activations_counter==1)? 0 : 1;                            
                            scheduling_valid_outputs_fsm    <= CHECK;

                            // check if it's time to latch the second buffer's output
                            if(scheduled_output_activations_counter==debug_prioritize_second_condition && output_fifo_read_concatenated_flags_ff[0][LOCAL_STRIDED_CONV_BIT_INDEX]==0) begin
                                
                               prioritize_second_fifo_flag <= 1; 
                            end
                            
                        end
                        else begin
                            output_slicing_steps_counter                    <= output_slicing_steps_counter + 1;
                            if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]-1) begin 
                            // if(output_slicing_steps_counter==output_fifo_read_concatenated_flags[0][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]-1) begin 
                                increment_scheduled_output_activations_counter  <= 1;
                                output_fifo_read_ready[0]                       <= 1;
                            end
                        end
                    end
                    SECOND: begin // shift register 1
                        // output_fifo_read_data_ff[1] <= output_fifo_read_data_ff[1] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        // output_fifo_read_data_ff_shift_reg[1] <= output_fifo_read_data_ff[1] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        output_fifo_read_data_ff_shift_reg[1] <= output_fifo_read_data_ff_shift_reg[1] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        
                        // if no/finished element_wise steps, then set ready to high, and got to next state.
                        if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[1][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]) begin 
                            output_slicing_steps_counter                    <= '{default:0};
                            // output_fifo_read_ready[1]                       <= 1;
                            latch_output_fifo_read_valid[1] <= 1;
                            // increment_scheduled_output_activations_counter  <= 0;
                            increment_scheduled_output_activations_counter  <= (increment_scheduled_output_activations_counter==1)? 0 : 1;                            
                            scheduling_valid_outputs_fsm    <= CHECK;

                            // TODO:: fixme hasan
                            if(scheduled_output_activations_counter==scheduled_output_activations_expected_total_number_of_outputs-1) begin
                                prioritize_second_fifo_flag <= 0;
                            end
                        end
                        else begin
                            output_slicing_steps_counter                    <= output_slicing_steps_counter + 1;
                            if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[1][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]-1) begin 
                                increment_scheduled_output_activations_counter  <= 1;
                                output_fifo_read_ready[1]                       <= 1;
                            end
                        end
                    end
                    THIRD: begin // shift register 2
                        // output_fifo_read_data_ff[2] <= output_fifo_read_data_ff[2] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 
                        output_fifo_read_data_ff_shift_reg[2] <= output_fifo_read_data_ff[2] >> (ACCUMULATOR_BIT_WIDTH*ACTIVATION_BIT_WIDTH); 

                        // if no/finished element_wise steps, then set ready to high, and got to next state.
                        if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[2][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]) begin 
                            output_slicing_steps_counter                    <= '{default:0};
                            output_fifo_read_ready[2]                       <= 1;
                            increment_scheduled_output_activations_counter  <= 0;
                            scheduling_valid_outputs_fsm                    <= CHECK; // next state
                        end
                        else begin
                            output_slicing_steps_counter                    <= output_slicing_steps_counter + 1;
                            if(output_slicing_steps_counter==output_fifo_read_concatenated_flags_ff[2][LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]-1) begin 
                                increment_scheduled_output_activations_counter  <= 1;
                            end
                        end
                    end
                endcase
            end
        end
    end
    // separate packed words into an array
    logic [ACCUMULATOR_BIT_WIDTH-1:0] scheduled_output_activations_array [ACTIVATION_BIT_WIDTH]; 
    always_comb begin 
        case (scheduling_valid_outputs_fsm)
            CHECK: begin
                scheduled_output_concatenated_flags = '{default:0}; 
                scheduled_output_activations_valid  = 0;
                for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                    scheduled_output_activations_array[i] = '{default:0};    
                end
            end
            FIRST: begin
                scheduled_output_concatenated_flags = output_fifo_read_concatenated_flags_ff[0]; 
                // scheduled_output_activations_valid  = 1;
                scheduled_output_activations_valid  = (output_slicing_steps_counter<latched_reg_file.number_of_output_slicing_steps)? 1 : scheduled_output_activations_last;
                // scheduled_output_activations_valid  = 1;
                for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                    // scheduled_output_activations_array[i] = output_fifo_read_data_ff[0][(i+1)*ACCUMULATOR_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH];    
                    scheduled_output_activations_array[i] = output_fifo_read_data_ff_shift_reg[0][(i+1)*ACCUMULATOR_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH];    
                end
            end
            SECOND: begin
                scheduled_output_concatenated_flags = output_fifo_read_concatenated_flags_ff[1]; 
                // scheduled_output_activations_valid  = 1;
                scheduled_output_activations_valid  = (output_slicing_steps_counter<latched_reg_file.number_of_output_slicing_steps)? 1 : (scheduled_output_activations_last);
                for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                    scheduled_output_activations_array[i] = output_fifo_read_data_ff_shift_reg[1][(i+1)*ACCUMULATOR_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH];    
                end
            end
            THIRD: begin
                scheduled_output_concatenated_flags = output_fifo_read_concatenated_flags_ff[2]; 
                // scheduled_output_activations_valid  = 1;
                scheduled_output_activations_valid  = (output_slicing_steps_counter<latched_reg_file.number_of_output_slicing_steps)? 1 : scheduled_output_activations_last;
                for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                    scheduled_output_activations_array[i] = output_fifo_read_data_ff_shift_reg[2][(i+1)*ACCUMULATOR_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH];    
                end
            end
            default: begin
                scheduled_output_concatenated_flags = '{default:0}; 
                scheduled_output_activations_valid  = 0;
                for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                    scheduled_output_activations_array[i] = '{default:0};    
                end
            end
        endcase
    end
    logic [ACCUMULATOR_BIT_WIDTH-1:0]           scheduled_output_activations_array_ff [ACTIVATION_BIT_WIDTH]; 
    logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]    scheduled_output_concatenated_flags_ff;
    logic                                       scheduled_output_activations_valid_ff;
    logic                                       scheduled_output_activations_last_ff;
    always_ff @(posedge clk) begin 
        if(resetn==0) begin
            scheduled_output_activations_array_ff   <= '{default:0};
            scheduled_output_concatenated_flags_ff  <= '{default:0};
            scheduled_output_activations_valid_ff   <= '0;
            scheduled_output_activations_last_ff    <= 0;
        end
        else begin 
            if(output_stage_fifo_write_ready==1)begin
                scheduled_output_activations_array_ff   <= scheduled_output_activations_array;
                scheduled_output_concatenated_flags_ff  <= scheduled_output_concatenated_flags;
                scheduled_output_activations_valid_ff   <= scheduled_output_activations_valid;
                scheduled_output_activations_last_ff    <= scheduled_output_activations_last;
                // scheduled_output_activations_last_ff    <= (output_slicing_steps_counter==latched_reg_file.number_of_output_slicing_steps)? scheduled_output_activations_last : 0;
            end
        end
    end

    always_ff @(posedge clk) begin
        if(resetn==0) begin
            computation_ctrl.bias_memory_address <= 0;
        end
        else begin
            if(output_stage_fifo_write_ready==1)begin
                // if(scheduled_output_activations_last==1) begin
                // if(computation_ctrl.bias_memory_address==(latched_reg_file.kernel_steps_minus_1+1)*latched_reg_file.number_of_output_slicing_steps -1) begin // TODO:: check if "output_slicing_steps_counter" need to be pipelined
                if(computation_ctrl.bias_memory_address==latched_reg_file.bias_steps-1) begin // TODO:: check if "output_slicing_steps_counter" need to be pipelined
                    computation_ctrl.bias_memory_address <= 0;
                end
                else begin 
                    if(scheduled_output_activations_valid==1) begin
                        computation_ctrl.bias_memory_address <= computation_ctrl.bias_memory_address + 1;
                    end
                end
            end
        end
    end

    // Bias
    logic [BIAS_BIT_WIDTH-1:0]           bias_array [ACTIVATION_BIT_WIDTH]; 
    always_comb begin
        for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
            bias_array[ACTIVATION_BIT_WIDTH-1-i] = computation_ctrl.bias_memory_data[(i+1)*BIAS_BIT_WIDTH_AXI-1 -: BIAS_BIT_WIDTH_AXI]; 
        end
    end
    logic [ACCUMULATOR_BIT_WIDTH-1:0]           output_activations_plus_bias_array [ACTIVATION_BIT_WIDTH]; 
    
    // logic [CONCATENATED_FLAGS_BIT_WIDTH-1:0]    output_concatenated_plus_bias_flags;
    logic                                       output_activations_plus_bias_valid;
    logic                                       output_activations_plus_bias_last;
    always_ff @(posedge clk) begin 
        if(resetn==0) begin
            output_activations_plus_bias_array   <= '{default:0};
            // output_concatenated_plus_bias_flags  <= '{default:0};
            output_activations_plus_bias_valid   <= '0;
            output_activations_plus_bias_last    <= 0;
        end
        else begin 
            
            if(output_stage_fifo_write_ready==1)begin
                if(scheduled_output_concatenated_flags_ff[LOCAL_BIAS_ENABLE_BIT_INDEX]==1) begin // add bias
                    for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                        output_activations_plus_bias_array[i] <= bias_array[i] + scheduled_output_activations_array_ff[i]; //TODO:: fixme: "element_wise_buffer_dob" should be properly extended to ACCUMULATOR_BIT_WIDTH
                    end
                end 
                else begin // no bias addition
                    output_activations_plus_bias_array <= scheduled_output_activations_array_ff;
                end

                output_activations_plus_bias_valid   <= scheduled_output_activations_valid_ff;
                output_activations_plus_bias_last    <= scheduled_output_activations_last_ff;
            end
        end
    end

    // --------------
    // Step 4: Bias + optional Element-wise add
	// --------------
    // Currently only works with 3x3 sparse convolution with padding=1. 
    // Can work with depth-first execution.
    // Data is read from stream 1. [Streams: 0, 1, 2]
	// --------------------------------------
    // Routing decoded data 
    localparam int ROUTING_CODE_BIT_WIDTH = $clog2(NUMBER_OF_PES_PER_ARRAY);
    localparam int INPUT_WORD_BIT_WIDTH   = ACTIVATION_BIT_WIDTH + 1; // +1 -> valid bit
    logic [INPUT_WORD_BIT_WIDTH-1:0]    decompressed_data_comb  [NUMBER_OF_PES_PER_ARRAY]; // this signal holds the decompressed sparse activation pixel. 
    logic [ACTIVATION_BIT_WIDTH-1:0]    decompressed_data_ff    [NUMBER_OF_PES_PER_ARRAY]; // delayed version of the corresponding _comb signal
    logic                               clear_decompressed_data;
    logic                               clear_decompressed_data_ff;
    logic [INPUT_WORD_BIT_WIDTH-1:0]    routing_data;
    logic [ROUTING_CODE_BIT_WIDTH-1:0]  routing_code;
    always_comb routing_data = {decoded_data.data[1], decoded_data.valid[1]};
    always_comb routing_code = decoded_data.channel[1][ROUTING_CODE_BIT_WIDTH-1:0];
    routing_tree #( // this module is used to prepare the data that is going to be written in the "element_wise_add_buffer". 
        .INPUT_WORD_BIT_WIDTH           (INPUT_WORD_BIT_WIDTH),
        .NUMBER_OF_ROUTING_TREE_OUTPUTS (NUMBER_OF_PES_PER_ARRAY)         
    ) decompression_register_routing_tree (
        .clk            (clk),
        .resetn         (resetn),
        .i_input        (routing_data),
        .i_routing_code (routing_code),    
        .o_outputs      (decompressed_data_comb)
    );
    delay_unit #(
        .DATA_WIDTH    (0), 
        .DELAY_CYCLES  ($clog2(NUMBER_OF_PES_PER_ARRAY))
    ) delay_1 (
        .clk                    (clk),
        .resetn                 (resetn),
        .i_input_data           (),
        .i_input_data_valid     (clear_decompressed_data),
        .o_output_data          (),
        .o_output_data_valid    (clear_decompressed_data_ff)
    );
    always_ff @(posedge clk) begin // control "decompressed_data_ff" register write using routed activations.
        if(resetn==0) begin
            decompressed_data_ff        <= '{default:0};
        end
        else begin 
            for (int i=0; i<NUMBER_OF_PES_PER_ARRAY; i++) begin
                if (clear_decompressed_data_ff==1) begin
                    decompressed_data_ff[i]     <= '0;
                end
                else begin
                    if (decompressed_data_comb[i][0]==1) begin
                        decompressed_data_ff[i] <= decompressed_data_comb[i][INPUT_WORD_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH];
                    end
                end
            end
        end
    end
    // element-wise addition memory. This memory stores the activation line to be added.  
    logic                                                                                                       element_wise_buffer_ena;
    logic                                                                                                       element_wise_buffer_enb;
    logic                                                                                                       element_wise_buffer_wea;
    logic [$clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS*SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS)-1:0]   element_wise_buffer_addra;
    logic [$clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS*SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS)-1:0]   element_wise_buffer_addrb;
    logic [NUMBER_OF_PES_PER_ARRAY*ACTIVATION_BIT_WIDTH-1:0]                                                    element_wise_buffer_dia;
    logic [NUMBER_OF_PES_PER_ARRAY*ACTIVATION_BIT_WIDTH-1:0]                                                    element_wise_buffer_dob;
    bram_sdp #(
        .BRAM_DATA_BIT_WIDTH (NUMBER_OF_PES_PER_ARRAY*ACTIVATION_BIT_WIDTH), 
        .BRAM_DEPTH          (SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS*SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS) //TODO:: check me
    ) element_wise_add_buffer(
        .clk    (clk),
        .ena    (element_wise_buffer_ena),
        .enb    (element_wise_buffer_enb),
        .wea    (element_wise_buffer_wea),
        .addra  (element_wise_buffer_addra),
        .addrb  (element_wise_buffer_addrb),
        .dia    (element_wise_buffer_dia),
        .dob    (element_wise_buffer_dob)
    );
    always_comb begin // set combinational buffer signals
        // enable (read and write ports) 
        element_wise_buffer_ena = global_latched_reg_file.enable_element_wise_buffer; //latched_reg_file.enable_element_wise_buffer; // enable writing values into the buffer. // this value is only updated after the stream decoders are done. this means that all the decoded_data values are correctly stored.       
        element_wise_buffer_enb = 1; 
        // write enable
        if(unsigned'(decoded_data.channel[1]) > unsigned'(NUMBER_OF_PES_PER_ARRAY) || decoded_data.toggled_column[1] != decoded_word_toggled_column_ff) begin
            clear_decompressed_data = 1;
        end
        else begin
            clear_decompressed_data = 0;
        end
        element_wise_buffer_wea = (scheduled_output_concatenated_flags[LOCAL_STREAM_MODE_BIT_INDEX]==SPARSE_MODE) ? clear_decompressed_data_ff : streamed_data.valid[1];
        // data in
        if(scheduled_output_concatenated_flags[LOCAL_STREAM_MODE_BIT_INDEX]==SPARSE_MODE) begin
            for (int i=0; i<NUMBER_OF_PES_PER_ARRAY; i++) begin
                element_wise_buffer_dia[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH] = decompressed_data_ff[i]; 
            end 
        end
        else begin // DENSE_MODE element-wise add 
                element_wise_buffer_dia = streamed_data.data[1]; 
        end
    end
    always_ff @(posedge clk) begin  // control "element_wise_buffer" address write address. 
        if(resetn==0) begin
            element_wise_buffer_addra <= '{default:0};
        end
        else begin
            // write address
            if (clear_decompressed_data_ff==1) begin
                element_wise_buffer_addra   <= element_wise_buffer_addra + 1;
            end
        end
    end
    // shifting data from element-wise add buffer
    logic [NUMBER_OF_PES_PER_ARRAY*ACTIVATION_BIT_WIDTH-1:0]    element_wise_stored_activations;
    logic                                                       element_wise_stored_activations_ready;
    always_ff @(posedge clk) begin 
        if(resetn==0) begin
            element_wise_stored_activations         <= '{default:0};
            element_wise_stored_activations_ready   <= 1;
            element_wise_buffer_addrb               <= '{default:0};
        end
        else begin
            if(output_stage_fifo_write_ready==1)begin
                if (element_wise_stored_activations_ready==1) begin
                    element_wise_stored_activations         <= element_wise_buffer_dob;
                    if(scheduled_output_concatenated_flags[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1 && scheduled_output_activations_valid==1) begin
                        element_wise_buffer_addrb               <= element_wise_buffer_addrb + 1;    
                        element_wise_stored_activations_ready   <= 0;
                    end                    
                end
                else begin
                    if(output_slicing_steps_counter==scheduled_output_concatenated_flags[LOCAL_OUTPUT_SLICING_STEPS_MSB-:OUTPUT_SLICING_STEPS_COUNTER_BIT_WIDTH]) begin 
                        element_wise_stored_activations_ready   <= 1;
                        // element_wise_buffer_addrb               <= element_wise_buffer_addrb + 1;
                    end
                    else begin
                        element_wise_stored_activations <= {ZEROS_, element_wise_stored_activations[$left(element_wise_stored_activations)-ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH:0]}; 
                    end
                end
            end
        end
    end
    // separate packed words into an array
    logic [ACTIVATION_BIT_WIDTH-1:0] element_wise_stored_activations_array [ACTIVATION_BIT_WIDTH];
    always_comb begin 
        for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
            element_wise_stored_activations_array[i] = element_wise_stored_activations[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH]; //TODO:: fixme: "element_wise_buffer_dob" should be properly extended to ACCUMULATOR_BIT_WIDTH
        end
    end
    // The actual element-wise addition.
    logic [ACCUMULATOR_BIT_WIDTH-1:0]   element_wise_output_activations [ACTIVATION_BIT_WIDTH]; 
    logic                               element_wise_output_activations_valid;
    logic                               element_wise_output_activations_last;
    // sequential 
    always_ff @(posedge clk) begin  
        if(resetn==0) begin
            element_wise_output_activations         <= '{default:0};
            element_wise_output_activations_valid   <= 0;
            element_wise_output_activations_last    <= 0;
        end
        else begin 
            if(output_stage_fifo_write_ready==1)begin
                // if(scheduled_output_concatenated_flags_ff[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1) begin
                //     for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                //         element_wise_output_activations[i] <= element_wise_stored_activations_array[i] + scheduled_output_activations_array_ff[i]; //TODO:: fixme: "element_wise_buffer_dob" should be properly extended to ACCUMULATOR_BIT_WIDTH
                //     end
                //     element_wise_output_activations_valid   <= scheduled_output_activations_valid_ff;
                //     element_wise_output_activations_last    <= scheduled_output_activations_last_ff; 
                // end
                // else begin
                //     element_wise_output_activations_valid <= 0;
                //     element_wise_output_activations_last  <= 0;
                // end

                if(scheduled_output_concatenated_flags_ff[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1) begin
                    for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                        element_wise_output_activations[i] <= element_wise_stored_activations_array[i] + output_activations_plus_bias_array[i]; //TODO:: fixme: "element_wise_buffer_dob" should be properly extended to ACCUMULATOR_BIT_WIDTH
                    end
                    element_wise_output_activations_valid   <= output_activations_plus_bias_valid;
                    element_wise_output_activations_last    <= output_activations_plus_bias_last; 
                end
                else begin
                    element_wise_output_activations_valid <= 0;
                    element_wise_output_activations_last  <= 0;
                end
            end
        end
    end
    
    // TODO:: fixme -> add pytorch requantization
    // TODO:: fixme -> add bias either with elementwise add or after
    // logic[$clog2(BIAS_LINE_BUFFER_DEPTH)-1:0]               computation_ctrl.bias_memory_address;
    // logic[BIAS_BANK_BIT_WIDTH*BIAS_BUFFER_BANK_COUNT-1:0]   computation_ctrl.bias_memory_data;


    // combinational
    // always_comb begin  
    //     if(output_stage_fifo_write_ready==1)begin
    //         if(scheduled_output_concatenated_flags_ff[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1) begin
    //             for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
    //                 element_wise_output_activations[i] = element_wise_stored_activations_array[i] + scheduled_output_activations_array_ff[i]; //TODO:: fixme: "element_wise_buffer_dob" should be properly extended to ACCUMULATOR_BIT_WIDTH
    //             end
    //             element_wise_output_activations_valid   = scheduled_output_activations_valid_ff;
    //             element_wise_output_activations_last    = scheduled_output_activations_last; // this works in sync with "scheduled_output_activations_array_ff" because it is delayed one cycle
    //         end
    //         else begin
    //             element_wise_output_activations       = '{default:0};
    //             element_wise_output_activations_valid = 0;
    //             element_wise_output_activations_last  = 0;
    //         end
    //     end
    // end
    // bypass element-wise addition? 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]   unquantized_activations [ACTIVATION_BIT_WIDTH]; 
    logic                               unquantized_activations_valid;
    logic                               unquantized_activations_last;
    // always_comb begin
    //     if(scheduled_output_concatenated_flags_ff[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1) begin
    //         unquantized_activations          = element_wise_output_activations;
    //         unquantized_activations_valid    = element_wise_output_activations_valid;
    //         unquantized_activations_last     = element_wise_output_activations_last;
    //     end
    //     else begin
    //         // unquantized_activations          = scheduled_output_activations_array_ff;
    //         // unquantized_activations_valid    = scheduled_output_activations_valid_ff;
    //         // unquantized_activations_last     = scheduled_output_activations_last_ff; 
    //         unquantized_activations          = output_activations_plus_bias_array;
    //         unquantized_activations_valid    = output_activations_plus_bias_valid;
    //         unquantized_activations_last     = output_activations_plus_bias_last; 
    //     end
    // end 
    always_ff @(posedge clk) begin  
        if(resetn==0) begin
            unquantized_activations         <= '{default:0};
            unquantized_activations_valid   <= 0;
            unquantized_activations_last    <= 0;
        end
        else begin 
            if(scheduled_output_concatenated_flags_ff[LOCAL_ELEMENT_WISE_ADD_BIT_INDEX]==1) begin
                unquantized_activations          <= element_wise_output_activations;
                unquantized_activations_valid    <= element_wise_output_activations_valid;
                unquantized_activations_last     <= element_wise_output_activations_last;
            end
            else begin
                unquantized_activations          <= output_activations_plus_bias_array;
                unquantized_activations_valid    <= output_activations_plus_bias_valid;
                unquantized_activations_last     <= output_activations_plus_bias_last; 
            end
        end
    end 

    // --------------
    // Step 5: Quantization  TODO:: use scaled quantization -> either soft multipliers or dsps
	// --------------
    // localparam UNQUANTIZED_TRIMMED_WIDTH = ACCUMULATOR_BIT_WIDTH-ACTIVATION_BIT_WIDTH+2;
    localparam UNQUANTIZED_TRIMMED_WIDTH = ACCUMULATOR_BIT_WIDTH;
    logic [UNQUANTIZED_TRIMMED_WIDTH-1:0]  unquantized_trimmed_activations [ACTIVATION_BIT_WIDTH]; 
    logic unsigned [ACTIVATION_BIT_WIDTH-1:0]                  quantized_activations_comb [ACTIVATION_BIT_WIDTH]; 
    logic                                                       quantized_activations_valid_comb;
    logic                                                       quantized_activations_last_comb;
    logic unsigned [ACTIVATION_BIT_WIDTH-1:0]                  quantized_activations [ACTIVATION_BIT_WIDTH]; 
    logic                                                       quantized_activations_valid;
    logic                                                       quantized_activations_last;
    // // POWERS-OF-TWO SCALING FACTORS (fixed_point quantization)
    // always_comb begin
    //     for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
    //         // unquantized_trimmed_activations[i] = unquantized_activations[i][ACCUMULATOR_BIT_WIDTH-1:ACTIVATION_BIT_WIDTH-1];
    //         unquantized_trimmed_activations[i] = unquantized_activations[i][ACCUMULATOR_BIT_WIDTH-1:ACTIVATION_BIT_WIDTH-2]; // weight quantization scale is 6 bits (64)

    //         // if(signed'(unquantized_trimmed_activations[i]) < signed'(UNQUANTIZED_TRIMMED_WIDTH'(ACTIVATION_MIN_VALUE))) begin
    //         if(signed'(unquantized_trimmed_activations[i]) < 0) begin

    //             // quantized_activations[i] = ACTIVATION_MIN_VALUE;
    //             quantized_activations[i] = 0;
    //         end
    //         // else if(signed'(unquantized_trimmed_activations[i]) > signed'(UNQUANTIZED_TRIMMED_WIDTH'(ACTIVATION_MAX_VALUE))) begin
    //         else if(signed'(unquantized_trimmed_activations[i]) > 255) begin
    //             // quantized_activations[i] = ACTIVATION_MAX_VALUE;
    //             quantized_activations[i] = 255;
    //         end
    //         else begin
    //             // Assign the actual result
    //             quantized_activations[i] = unquantized_trimmed_activations[i][ACTIVATION_BIT_WIDTH-1:0];
    //         end        
    //     end
    //     quantized_activations_valid = unquantized_activations_valid;
    //     quantized_activations_last  = unquantized_activations_last;
    // end

    // // approximated scaling factors
    logic [QUANTIZATION_SCALE_BIT_WIDTH-1:0] q_scale;
    always_comb q_scale = latched_reg_file.q_scale;
    logic [ACCUMULATOR_BIT_WIDTH+QUANTIZATION_SCALE_BIT_WIDTH-1:0] scaling_result [ACTIVATION_BIT_WIDTH];
    always_comb begin // TODO:: fixme -> change to always_ff
        for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
            // scaling_result[i] = unquantized_activations[i] * q_scale;
            scaling_result[i] = signed'(unquantized_activations[i]) * signed'(q_scale);
            unquantized_trimmed_activations[i] = scaling_result[i][ACCUMULATOR_BIT_WIDTH+QUANTIZATION_SCALE_BIT_WIDTH-1 -: ACCUMULATOR_BIT_WIDTH];
            // unquantized_trimmed_activations[i] = unquantized_activations[i][ACCUMULATOR_BIT_WIDTH-1:ACTIVATION_BIT_WIDTH-2]; // weight quantization scale is 6 bits (64)

            if(latched_reg_file.relu==1) begin
                if(signed'(unquantized_trimmed_activations[i]) < 0 ) begin
                    // quantized_activations[i] = ACTIVATION_MIN_VALUE;
                    quantized_activations_comb[i] = 0;
                end
                // else if(signed'(unquantized_trimmed_activations[i]) > signed'(UNQUANTIZED_TRIMMED_WIDTH'(ACTIVATION_MAX_VALUE))) begin
                else if(signed'(unquantized_trimmed_activations[i]) > 255) begin
                    // quantized_activations[i] = ACTIVATION_MAX_VALUE;
                    quantized_activations_comb[i] = 255;
                end
                else begin
                    // Assign the actual result
                    quantized_activations_comb[i] = unquantized_trimmed_activations[i][ACTIVATION_BIT_WIDTH-1:0];
                end        
            end 
            else begin
                if(signed'(unquantized_trimmed_activations[i]) < -128) begin
                    // quantized_activations[i] = ACTIVATION_MIN_VALUE;
                    quantized_activations_comb[i] = -128;
                end
                // else if(signed'(unquantized_trimmed_activations[i]) > signed'(UNQUANTIZED_TRIMMED_WIDTH'(ACTIVATION_MAX_VALUE))) begin
                else if(signed'(unquantized_trimmed_activations[i]) > 127) begin
                    // quantized_activations[i] = ACTIVATION_MAX_VALUE;
                    quantized_activations_comb[i] = 127;
                end
                else begin
                    // Assign the actual result
                    quantized_activations_comb[i] = unquantized_trimmed_activations[i][ACTIVATION_BIT_WIDTH-1:0];
                end    
            end

            // if(signed'(unquantized_trimmed_activations[i]) > 255) begin
            //     // quantized_activations[i] = ACTIVATION_MAX_VALUE;
            //     quantized_activations_comb[i] = 255;
            // end
            // else begin
            //     // Assign the actual result
            //     quantized_activations_comb[i] = unquantized_trimmed_activations[i][ACTIVATION_BIT_WIDTH-1:0];
            // end        
        end
        quantized_activations_valid_comb = unquantized_activations_valid;
        quantized_activations_last_comb  = unquantized_activations_last;
    end

    always_ff @(posedge clk) begin  
        if(resetn==0) begin
            quantized_activations         <= '{default:0};
            quantized_activations_valid   <= 0;
            quantized_activations_last    <= 0;
        end
        else begin 
            quantized_activations          <= quantized_activations_comb;
            quantized_activations_valid    <= quantized_activations_valid_comb;
            quantized_activations_last     <= quantized_activations_last_comb;
        end
    end 


    // --------------
    // Step 6: Activation  TODO:: check if this should be pipelined  TODO:: add "no_activation" mode
	// --------------
    logic [ACTIVATION_BIT_WIDTH-1:0] relu_activations [ACTIVATION_BIT_WIDTH]; 
    logic [ACTIVATION_BIT_WIDTH-1:0] relu_sm; 
    logic                            relu_activations_valid;
    logic                            relu_activations_last;
    // always_comb begin
    //     for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
    //         if(quantized_activations[i]<=0) begin 
    //             relu_activations[ACTIVATION_BIT_WIDTH-1-i]  = 0;
    //             relu_sm[ACTIVATION_BIT_WIDTH-1-i]           = 0;
    //         end
    //         else begin
    //             relu_activations[ACTIVATION_BIT_WIDTH-1-i]  = quantized_activations[i];
    //             relu_sm[ACTIVATION_BIT_WIDTH-1-i]           = 1;
    //         end
    //     end
    //     relu_activations_valid = quantized_activations_valid;
    //     relu_activations_last  = quantized_activations_last;
    // end

    always_ff @(posedge clk) begin  
        if(resetn==0) begin
            relu_activations        <= '{default:0};
            relu_sm                 <= 0;
            relu_activations_valid  <= 0;
            relu_activations_last   <= 0;
        end
        else begin 
            for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
                if(quantized_activations[i]<=0) begin 
                // if(quantized_activations[i]<=0) begin 
                    if(latched_reg_file.relu==1) begin
                        relu_activations[ACTIVATION_BIT_WIDTH-1-i]  <= 0;
                    end
                    relu_sm[ACTIVATION_BIT_WIDTH-1-i]           <= 0;
                end
                else begin
                    relu_activations[ACTIVATION_BIT_WIDTH-1-i]  <= quantized_activations[i];
                    relu_sm[ACTIVATION_BIT_WIDTH-1-i]           <= 1;
                end
            end
            relu_activations_valid <= quantized_activations_valid;
            relu_activations_last  <= quantized_activations_last;
        end
    end 


    // --------------
    // Step 7: SM Compression and output commit. 
	// --------------
    logic                                   clear_output_stage; // TODO:: must be high with the last 8-word segment. 
    logic                                   sm_valid;
    logic [ACTIVATION_BIT_WIDTH-1:0]        sm;
    logic [ACTIVATION_BIT_WIDTH-1:0]        input_array [ACTIVATION_BIT_WIDTH]; // including sm
    logic [ACTIVATION_BANK_BIT_WIDTH-1:0]   output_array;
    logic                                   output_valid;
    logic                                   output_last;
    logic                                   output_stage_ready; // TODO:: fixme: use to stall previous stage(s)
    logic [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]   output_stage_fifo_write_data;
    logic [ACTIVATION_BIT_WIDTH-1:0]                        output_stage_fifo_write_sm;
    logic                                                   output_stage_fifo_write_last;
    logic                                                   output_stage_fifo_write_valid;
    // logic                                                   output_stage_fifo_write_ready;
    logic [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]   output_stage_fifo_read_data;
    logic [ACTIVATION_BIT_WIDTH-1:0]                        output_stage_fifo_read_sm;
    logic                                                   output_stage_fifo_read_last;
    logic                                                   output_stage_fifo_read_valid;
    logic                                                   output_stage_fifo_read_ready;
    // axis_fifo_v2 #(
    axis_fifo_v4 #(
        .AXIS_BUS_WIDTH (ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH + ACTIVATION_BIT_WIDTH + 1),
        .FIFO_DEPTH     (OUTPUT_FIFO_DEPTH) 
    ) output_stage_fifo (
        .m_axi_aclk     (clk),
        .m_axi_aresetn  (resetn),
        .s_axis_tdata   ({output_stage_fifo_write_data, output_stage_fifo_write_sm, output_stage_fifo_write_last}),
        .s_axis_tvalid  (output_stage_fifo_write_valid),
        .s_axis_tready  (output_stage_fifo_write_ready),
        .m_axis_tdata   ({output_stage_fifo_read_data, output_stage_fifo_read_sm, output_stage_fifo_read_last}),
        .m_axis_tvalid  (output_stage_fifo_read_valid),
        .m_axis_tready  (output_stage_fifo_read_ready),
        .o_empty        () //TODO:: remove me.
    );
    always_comb begin
        for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
            output_stage_fifo_write_data[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH]  = relu_activations[i]; 
        end
        output_stage_fifo_write_sm      = relu_sm;
        output_stage_fifo_write_last    = relu_activations_last;
        output_stage_fifo_write_valid   = relu_activations_valid;
        output_stage_fifo_read_ready    = output_stage_ready;

        sm_valid           = output_stage_fifo_read_valid && output_stage_fifo_read_ready;
        sm                 = output_stage_fifo_read_sm;
        for (int i=0; i<ACTIVATION_BIT_WIDTH; i++) begin
            input_array[i] = output_stage_fifo_read_data[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH]; 
        end
        clear_output_stage = output_stage_fifo_read_last;
    end
    output_stage #(
        .DATA_BIT_WIDTH (ACTIVATION_BIT_WIDTH)
    ) output_stage_unit (
        .clk                    (clk),
        .resetn                 (resetn),
        .i_clear_output_stage   (clear_output_stage),
        .i_sm_valid             (sm_valid),    
        .i_sm                   (sm),
        .i_input_array          (input_array),  
        .o_output_stage_ready   (output_stage_ready),      
        .o_output_array         (output_array),        
        .o_output_valid         (output_valid),
        .o_output_last          (output_last)
    );
    // always_comb begin
    //     sm_valid           = relu_activations_valid;
    //     sm                 = relu_sm;
    //     input_array        = relu_activations;
    //     clear_output_stage = relu_activations_last;
    // end

    // --------------
    // Step 8: Output address generation/control
	// --------------
    logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]  output_address;
    // enum logic[1:0] {WAITING_FOR_FIRST_OUTPUT, }
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            output_address <= '1;
            latched_reg_file.output_line_end_address <= 0; // TODO:: check me
            latch_flag <= 1;
            o_output_line_stored <= 0;
            // update_latched_reg_file_to_output_address_latch_flag <= 0;
        end
        else begin
            // if(latched_reg_file.execution_flag==1 && update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin 
            // if(update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin 
            // if(update_latched_reg_file && latch_flag) begin 
            if(latch_flag) begin 
                output_address <= latched_reg_file.stream_writer_ptr;
                // latch_flag <= 0; // TODO:: check if latch_flag should be deasserted without depending on "latched_reg_file.execution_flag".
            end


            // else begin

                // if(output_fifo_read_valid[0]==1) begin

                if(output_valid==1) begin
                    if(output_last==1) begin
                        latch_flag <= 1;
                        o_output_line_stored <= 1;
                        latched_reg_file.output_line_end_address <= output_address; 
                    end
                    else begin
                        // latch_flag <= 0;
                        output_address  <= output_address + 1;
                    end
                end
                else begin
                    // if(output_activations_valid[0]==1) begin
                    if(output_activations_valid[0]==1) begin
                        latch_flag <= 0;
                    end 
                    o_output_line_stored <= 0;
                end 
            // end

            update_latched_reg_file_to_output_address_latch_flag <= update_latched_reg_file;

            // // if(update_latched_reg_file==1) begin
            // if(latch_flag && update_latched_reg_file) begin
            //     update_latched_reg_file_to_output_address_latch_flag <= 1;
            // end
            // else begin
            //     // if(latched_reg_file.execution_flag==1 && update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin
            //     if(update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin
            //         update_latched_reg_file_to_output_address_latch_flag <= 0;
            //     end
            // end

        end
    end

    // always_ff @(posedge clk) begin
    //     if(resetn==0) begin
    //         update_latched_reg_file_to_output_address_latch_flag <= 1;
    //     end
    //     else begin
    //         if(update_latched_reg_file==1) begin
    //             update_latched_reg_file_to_output_address_latch_flag <= 1;
    //         end
    //         else begin
    //             // todo: fixme hasan
    //             // if(latched_reg_file.execution_flag==1 && update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin
    //             if(update_latched_reg_file_to_output_address_latch_flag==1 && latch_flag==1) begin
    //                 update_latched_reg_file_to_output_address_latch_flag <= 0;
    //             end
    //         end
    //     end
    // end


    always_comb begin 
        for (int i = 0; i<ACTIVATION_BIT_WIDTH; i++) begin
            debug_quantized_activations[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH] = quantized_activations[i];
        end
        debug_quantized_activations_valid = quantized_activations_valid;
    end

    // debug
    always_comb begin
        o_output_array          = output_array;
        o_output_valid          = output_valid;
        o_output_address        = output_address;
        // o_output_line_stored    = latch_flag;
    end

endmodule