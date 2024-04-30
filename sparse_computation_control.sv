/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: SPARSE conv3x3 convolution computation control. 
*   Date:   10.02.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module sparse_conv_computation_control #(   
    parameter int REGISTER_WIDTH                        = NVP_v1_constants::REGISTER_WIDTH,
    parameter int ACTIVATION_BANK_BIT_WIDTH           = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT          = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int ACTIVATION_BIT_WIDTH                  = NVP_v1_constants::ACTIVATION_BIT_WIDTH,    
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW           = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,            
    parameter int NUMBER_OF_PES_PER_ARRAY               = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,        
    parameter int COLUMN_VALUE_BIT_WIDTH                = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,        
    parameter int CHANNEL_VALUE_BIT_WIDTH               = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,        
    parameter int ROW_VALUE_BIT_WIDTH                   = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,    
    parameter int WEIGHT_LINE_BUFFER_DEPTH                   = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,    
    parameter int TOGGLED_COLUMN_MSB                    = NVP_v1_constants::TOGGLED_COLUMN_MSB,    
    parameter int CHANNEL_MSB                           = NVP_v1_constants::CHANNEL_MSB,
    parameter int RELATIVE_ROW_MSB                      = NVP_v1_constants::RELATIVE_ROW_MSB,
    parameter int LAST_COLUMN_MSB                       = NVP_v1_constants::LAST_COLUMN_MSB,
    parameter int ACTIVATION_DATA_MSB                   = NVP_v1_constants::ACTIVATION_DATA_MSB,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS)
)(
    input logic                                                                     clk,
    input logic                                                                     resetn,
    compute_core_data_if                                                            compute_data,
    input logic   [REGISTER_WIDTH-1:0]                                              i_sparse_kernel_steps_minus_1, // i_sparse_kernel_steps_minus_1 <==> latched_reg_file.kernel_steps_minus_1 // TODO:: fixme see how many bits instead of REGISTER_WIDTH
    input logic   [REGISTER_WIDTH-1:0]                                              i_sparse_number_of_channels, // i_sparse_number_of_channels <==> latched_reg_file.number_of_channels // TODO:: fixme see how many bits instead of REGISTER_WIDTH
    output logic                                                                    o_sparse_shift_output_steps_counter_finished_flag,
    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               o_sparse_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                             o_sparse_weight_address_systolic      [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_sparse_delayed_shift_partial_result_flag,
    output logic                                                                    o_sparse_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_sparse_reset_accumulator_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]       o_sparse_activations_systolic         [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_sparse_valid_systolic               [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               o_sparse_kernel_step_index_systolic   [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_sparse_ready,
    output logic                                                                    o_sparse_update_latched_reg_file_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],

    output logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                               o_post_processing_shift_output_steps_counter_systolic [NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_post_processing_sparse_shift_partial_result_systolic[NUMBER_OF_PE_ARRAYS_PER_ROW],
    output logic                                                                    o_post_processing_sparse_shift_output_steps_counter_finished_flag
);

    // --------------------------------------
    // ------ Sparse mode signals and some control logic
    // used in weight address generation 
	// -------------------------------------- 
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]      sparse_activations_comb, sparse_activations_ff; // if the "_ff" variable is defined, this means that the signal needs to be delayed.
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]                                      sparse_toggled_column, sparse_toggled_column_previous;
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0]                                     sparse_channel; 
    logic [ROW_VALUE_BIT_WIDTH-1:0]                                         sparse_row; 
    logic                                                                   sparse_last_column;
    logic                                                                   sparse_ready;
    logic                                                                   sparse_reset_accumulator;  
    logic                                                                   sparse_shift_partial_result;
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                            sparse_weight_address_comb;
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]                            sparse_buffered_weight_address;
    logic                                                                   sparse_valid, sparse_valid_ff; 
    logic                                                                   sparse_shift_output_steps_counter_finished_flag; // this signal is asserted for one cycle after the last shift.
    logic                                                                   sparse_shift_output_steps_counter_trigger;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                              sparse_shift_output_steps_counter;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                              sparse_kernel_steps_counter, sparse_kernel_steps_counter_ff, sparse_kernel_steps_counter_ff_ff; // counts kernel_steps or channel_steps
    logic                                                                   sparse_update_latched_reg_file;
    // {data, toggled_column, channel, row, valid}
    always_ff @(posedge clk) begin // extract {data, toggled_column, channel, row, valid} from read valid word
        if(resetn==0) begin
            sparse_toggled_column   <= '0;    
            sparse_channel          <= '0;  
            sparse_row              <= '0;  
            sparse_last_column      <= 0;
            sparse_valid       <= 0;  
            sparse_buffered_weight_address <= 0;
            sparse_activations_comb <= '{default:0};
        end
        else begin 
            if(sparse_ready==1) begin
                sparse_valid                    <= compute_data.sparse_data_valid;  
                sparse_toggled_column           <= compute_data.sparse_data[TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH];    
                sparse_channel                  <= compute_data.sparse_data[CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH];  
                sparse_row                      <= compute_data.sparse_data[RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH];  
                sparse_last_column              <= compute_data.sparse_data[LAST_COLUMN_MSB];
                sparse_buffered_weight_address  <= compute_data.sparse_buffered_weight_address;  
                
                for (int i=0; i<NUMBER_OF_PES_PER_ARRAY; i++) begin
                    sparse_activations_comb[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH] <=  compute_data.sparse_data[ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH];
                end
            end
        end
    end 
            // always_comb begin // extract {data, toggled_column, channel, row, valid} from read valid word
    //     sparse_toggled_column   = compute_data.sparse_data[TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH];    
    //     sparse_channel          = compute_data.sparse_data[CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH];  
    //     sparse_row              = compute_data.sparse_data[RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH];  
    //     sparse_last_column      = compute_data.sparse_data[LAST_COLUMN_MSB];
    //     // sparse_valid       = compute_data.sparse_data[VALID_MSB];  
    //     sparse_valid       = compute_data.sparse_data_valid;  
    //     for (int i=0; i<NUMBER_OF_PES_PER_ARRAY; i++) begin
    //         sparse_activations_comb[(i+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH] =  compute_data.sparse_data[ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH];
    //     end
    // end
    delay_unit #(   // configurable delay = to synchronize activations and weights and other control signals
        .DATA_WIDTH    ($size(sparse_activations_comb)), 
        .DELAY_CYCLES  (1)
    ) delay_1 (
        .clk                    (clk),
        .resetn                 (resetn),
        .i_input_data           (sparse_activations_comb),
        .i_input_data_valid     (sparse_valid),
        .o_output_data          (sparse_activations_ff),
        .o_output_data_valid    (sparse_valid_ff)
    );
    always_ff @(posedge clk) begin // save column index. Used to know when the column index changes.  
        if(resetn==0) begin
            sparse_toggled_column_previous <= '{default:0};
        end
        else begin 
            
            sparse_toggled_column_previous <= (sparse_valid || sparse_reset_accumulator)? sparse_toggled_column : sparse_toggled_column_previous;
            // sparse_toggled_column_previous <= sparse_toggled_column;
        end
    end


    // Clear accumulators in sparse mode
    enum logic[1:0] {WAITING_FOR_LAST_COLUMN, LAST_COLUMN, UPDATE_REG_FILE} accumulator_reset_fsm;
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            accumulator_reset_fsm       <= WAITING_FOR_LAST_COLUMN;
            sparse_reset_accumulator    <= 0;
            sparse_update_latched_reg_file <= 0;
        end
        else begin
            case (accumulator_reset_fsm)
                WAITING_FOR_LAST_COLUMN: begin
                    if (sparse_last_column==1 && sparse_valid==1) begin
                        accumulator_reset_fsm <= LAST_COLUMN;
                    end
                    
                    if (sparse_valid==1) begin
                        sparse_update_latched_reg_file <= 0;
                    end
                    // sparse_update_latched_reg_file <= 0;
                end
                LAST_COLUMN: begin
                    if (sparse_last_column==0 && sparse_valid==1) begin
                    // if (sparse_last_column==0) begin
                        sparse_reset_accumulator    <= 1; // this is an active high reset.
                        accumulator_reset_fsm       <= UPDATE_REG_FILE;
                    end
                end
                UPDATE_REG_FILE: begin
                    // this condition ensures that the last column's outputs are all read when kernel_steps > 1 , then deassert the reset.
                    if(sparse_shift_output_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin // TODO:: fixme: check that this condition is correct
                        sparse_reset_accumulator <= 0;
                        sparse_update_latched_reg_file <= 1;
                        accumulator_reset_fsm <= WAITING_FOR_LAST_COLUMN;
                    end 
                end
                default: begin
                    accumulator_reset_fsm <= LAST_COLUMN;
                end
            endcase
        end
    end

    // always_comb sparse_enable_pes        = sparse_valid_ff;
    // used to implement partial result shift in kernel steps. 
    // when 1, there are no kernel steps, so the partial result is not valid at the shift cycle. To solve this, the shift is performed on two cycles. 
    // First, the accumulator is cleared and adds only the current multiplciation value. 
    // Second, the input partial result (now ready) is added to the accumulated value and added to the multiplication value.  
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            sparse_shift_output_steps_counter                  <= '{default:0};
            sparse_shift_partial_result                        <= 0;
            sparse_shift_output_steps_counter_trigger          <= 0;
            sparse_shift_output_steps_counter_finished_flag    <= 0;
        end
        else begin
            // shift_output_steps_counter <= steps_counter;
            // instead of being delayed one cycle, it is triggered to count "kernel_steps" cycles. 
            // if(steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin
            //     // shift_output_steps_counter_trigger <= 1; // enable trigger
            //     // shift_output_steps_counter   <= 0;
            // end
            if (sparse_shift_output_steps_counter_trigger==1) begin 
                if(sparse_shift_output_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin
                    sparse_shift_output_steps_counter                  <= 0; // reset counter
                    sparse_shift_output_steps_counter_trigger          <= 0; // reset counter trigger
                    sparse_shift_output_steps_counter_finished_flag    <= 1;
                end
                else begin
                    sparse_shift_output_steps_counter <= sparse_shift_output_steps_counter + 1;
                end
            end

            if (sparse_shift_output_steps_counter_finished_flag==1) begin
                sparse_shift_output_steps_counter_finished_flag <= 0;
            end

            if ((sparse_valid==1 && sparse_toggled_column!=sparse_toggled_column_previous) || (sparse_valid==1 && accumulator_reset_fsm==LAST_COLUMN && sparse_last_column==0)) begin
            // if (sparse_toggled_column!=sparse_toggled_column_previous) begin
                sparse_shift_partial_result <= 1;
                sparse_shift_output_steps_counter_trigger <= 1;
            end 
            else begin
                // sparse_shift_partial_result <= 0;
                if(sparse_shift_output_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin
                    sparse_shift_partial_result <= 0;
                end
                else begin
                    sparse_shift_partial_result <= sparse_shift_partial_result;
                end
            end
        end
    end

    // Kernel steps counter and ready signals logic o_sparse_ready 
    always_comb o_sparse_ready = sparse_ready;
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            sparse_kernel_steps_counter <= '{default:0};
            sparse_ready         <= 1;
        end
        else begin
            if(compute_data.sparse_data_valid==1 || sparse_kernel_steps_counter != 0) begin //  //TODO:: check me
            // if(sparse_valid==1 || sparse_kernel_steps_counter != 0) begin //  //TODO:: check me 
                if (i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]==0) begin // no steps - steps=1
                    sparse_ready <= 1;
                end 
                else begin 
                    if(sparse_kernel_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin // steps >= 2
                        sparse_kernel_steps_counter <= '{default:0};
                        sparse_ready <= 1;
                    end
                    else begin
                        sparse_ready <= 0;
                        sparse_kernel_steps_counter <= sparse_kernel_steps_counter + 1;
                    end
                end
            end

        end
    end
    // always_ff @(posedge clk) begin
    //     if(resetn==0) begin
    //         sparse_kernel_steps_counter <= '{default:0};
    //         o_sparse_ready         <= 1;
    //     end
    //     else begin
    //         if(compute_data.sparse_data_valid==1 || sparse_kernel_steps_counter != 0) begin //  //TODO:: check me "sparse_valid_ff==1" 
    //             if (i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]==0) begin // no steps - steps=1
    //                 o_sparse_ready <= 1;
    //             end 
    //             else begin 
    //                 if(sparse_kernel_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]) begin // steps >= 2
    //                     o_sparse_ready <= 0;
    //                     sparse_kernel_steps_counter <= '{default:0};
    //                 end
    //                 else begin
    //                     sparse_kernel_steps_counter <= sparse_kernel_steps_counter + 1;

    //                     if(sparse_kernel_steps_counter==i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]-1) begin
    //                         o_sparse_ready <= 1;
    //                     end
    //                 end
    //             end
    //         end
    //     end
    // end
    // delay_unit #(   // configurable delay = to synchronize activations and weights and other control signals
    //     .DATA_WIDTH    ($size(sparse_kernel_steps_counter)), 
    //     .DELAY_CYCLES  (2)
    // ) delay_2 (
    //     .clk                    (clk),
    //     .resetn                 (resetn),
    //     .i_input_data           (sparse_kernel_steps_counter),
    //     .i_input_data_valid     (),
    //     .o_output_data          (sparse_kernel_steps_counter_ff),
    //     .o_output_data_valid    ()
    // );
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            sparse_kernel_steps_counter_ff       <= '{default:0};
            sparse_kernel_steps_counter_ff_ff    <= '{default:0};
        end
        else begin
            sparse_kernel_steps_counter_ff       <= sparse_kernel_steps_counter;
            sparse_kernel_steps_counter_ff_ff    <= sparse_kernel_steps_counter_ff;
        end
    end

    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH+1-1:0] kernel_steps;
    always_comb kernel_steps = i_sparse_kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0] + 1; 
    always_comb begin 
        sparse_weight_address_comb       = sparse_kernel_steps_counter_ff + sparse_buffered_weight_address;
        // sparse_weight_address_comb       = sparse_kernel_steps_counter + compute_data.sparse_buffered_weight_address;
    end

    // delays
    localparam BASE_DELAY = 1; // >=1
    localparam DELAY_1 = BASE_DELAY + 1;
    logic                                                               sparse_shift_partial_result_delay[DELAY_1];
    // logic                                                               sparse_reset_accumulator_delay[DELAY_1];  
    // logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]                          sparse_shift_output_steps_counter_delay[DELAY_1];
    logic                                                               sparse_update_latched_reg_file_delay[DELAY_1];
    logic                                                               sparse_shift_output_steps_counter_finished_flag_delay[DELAY_1]; 

    // localparam DELAY_2 = BASE_DELAY + 3;
    localparam DELAY_2 = BASE_DELAY + 2;
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0] sparse_kernel_steps_counter_delay [DELAY_2]; 

    localparam DELAY_3 = BASE_DELAY + 2;
    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]  sparse_activations_delay[DELAY_3]; 
    logic                                                               sparse_valid_delay[DELAY_3];

    localparam DELAY_4 = BASE_DELAY + 0;
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0] sparse_weight_address_delay[DELAY_4];
    logic sparse_reset_accumulator_delay[DELAY_4];  
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0] sparse_shift_output_steps_counter_delay[DELAY_4];



    always_ff @(posedge clk) begin
        if (resetn==0) begin
            sparse_activations_delay                               <= '{default:0};
            sparse_valid_delay                                     <= '{default:0};
        end
        else begin
            // DELAY_1
            sparse_shift_partial_result_delay[DELAY_1-1] <= sparse_shift_partial_result;
            for (int i=DELAY_1-2; i>=0; i--) begin
                sparse_shift_partial_result_delay[i] <= sparse_shift_partial_result_delay[i+1];    
            end

            // sparse_reset_accumulator_delay[DELAY_1-1] <= sparse_reset_accumulator;
            // for (int i=DELAY_1-2; i>=0; i--) begin
            //     sparse_reset_accumulator_delay[i] <= sparse_reset_accumulator_delay[i+1];    
            // end

            // sparse_shift_output_steps_counter_delay[DELAY_1-1] <= sparse_shift_output_steps_counter;
            // for (int i=DELAY_1-2; i>=0; i--) begin
            //     sparse_shift_output_steps_counter_delay[i] <= sparse_shift_output_steps_counter_delay[i+1];    
            // end

            sparse_update_latched_reg_file_delay[DELAY_1-1] <= sparse_update_latched_reg_file;
            for (int i=DELAY_1-2; i>=0; i--) begin
                sparse_update_latched_reg_file_delay[i] <= sparse_update_latched_reg_file_delay[i+1];    
            end

            sparse_shift_output_steps_counter_finished_flag_delay[DELAY_1-1] <= sparse_shift_output_steps_counter_finished_flag;
            for (int i=DELAY_1-2; i>=0; i--) begin
                sparse_shift_output_steps_counter_finished_flag_delay[i] <= sparse_shift_output_steps_counter_finished_flag_delay[i+1];    
            end
            
            
            // DELAY_2
            sparse_kernel_steps_counter_delay[DELAY_2-1] <= sparse_kernel_steps_counter;
            for (int i=DELAY_2-2; i>=0; i--) begin
                sparse_kernel_steps_counter_delay[i] <= sparse_kernel_steps_counter_delay[i+1];    
            end


            // DELAY_3
            sparse_activations_delay[DELAY_3-1] <= sparse_activations_comb;
            for (int i=DELAY_3-2; i>=0; i--) begin
                sparse_activations_delay[i] <= sparse_activations_delay[i+1];    
            end

            sparse_valid_delay[DELAY_3-1] <= sparse_valid;
            for (int i=DELAY_3-2; i>=0; i--) begin
                sparse_valid_delay[i] <= sparse_valid_delay[i+1];    
            end

            // DELAY_4
            sparse_weight_address_delay[DELAY_4-1] <= sparse_weight_address_comb;
            for (int i=DELAY_4-2; i>=0; i--) begin
                sparse_weight_address_delay[i] <= sparse_weight_address_delay[i+1];    
            end

            sparse_reset_accumulator_delay[DELAY_4-1] <= sparse_reset_accumulator;
            for (int i=DELAY_4-2; i>=0; i--) begin
                sparse_reset_accumulator_delay[i] <= sparse_reset_accumulator_delay[i+1];    
            end

            sparse_shift_output_steps_counter_delay[DELAY_4-1] <= sparse_shift_output_steps_counter;
            for (int i=DELAY_4-2; i>=0; i--) begin
                sparse_shift_output_steps_counter_delay[i] <= sparse_shift_output_steps_counter_delay[i+1];    
            end
            
        end
    end


    always_ff @(posedge clk) begin// systolic operation between pe arrays inside the same pe row. 
        // what should be pipelined: activations, weights, valid, output_activaions valid, clear accumulators, accumulator enable (according to relative row).
        if (resetn==0) begin
            o_sparse_activations_systolic                                       <= '{default:0};
            // o_sparse_weight_address_systolic                                 <= '{default:0};
            o_sparse_weight_address_systolic[0]                                 <= '{default:0};
            o_sparse_weight_address_systolic[1]                                 <= '{default:0};
            o_sparse_weight_address_systolic[2]                                 <= '{default:0};
            o_sparse_valid_systolic                                             <= '{default:0};
            o_sparse_shift_partial_result_systolic                              <= '{default:0};
            o_sparse_reset_accumulator_systolic                                 <= '{default:0};
            o_sparse_shift_output_steps_counter_systolic                        <= '{default:0};
            o_sparse_kernel_step_index_systolic                                 <= '{default:0};
            o_post_processing_sparse_shift_partial_result_systolic              <= '{default:0};
            o_post_processing_shift_output_steps_counter_systolic               <= '{default:0};
            o_post_processing_sparse_shift_output_steps_counter_finished_flag   <= 0;

        end
        else begin
            o_sparse_activations_systolic[0] <= sparse_activations_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_activations_systolic[i] <= o_sparse_activations_systolic[i-1];    
            end

            o_sparse_valid_systolic[0]  <= sparse_valid_delay[0];  
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_valid_systolic[i]  <= o_sparse_valid_systolic[i-1];  
            end

            o_sparse_kernel_step_index_systolic[0] <= sparse_kernel_steps_counter_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_kernel_step_index_systolic[i] <= o_sparse_kernel_step_index_systolic[i-1];
            end

            
            // o_sparse_shift_partial_result_systolic[0] <= sparse_shift_partial_result;
            o_sparse_shift_partial_result_systolic[0] <= sparse_shift_partial_result_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_shift_partial_result_systolic[i] <= o_sparse_shift_partial_result_systolic[i-1];
            end
            o_post_processing_sparse_shift_partial_result_systolic[0] <= sparse_shift_partial_result_delay[0]; // no delay
            // o_post_processing_sparse_shift_partial_result_systolic[0] <= o_sparse_shift_partial_result_systolic[0]; // one cycle delay
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_post_processing_sparse_shift_partial_result_systolic[i] <= o_post_processing_sparse_shift_partial_result_systolic[i-1];
            end
            

            // o_sparse_reset_accumulator_systolic[0] <= sparse_reset_accumulator;
            o_sparse_reset_accumulator_systolic[0] <= sparse_reset_accumulator_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_reset_accumulator_systolic[i] <= o_sparse_reset_accumulator_systolic[i-1];
            end

            // o_sparse_shift_output_steps_counter_systolic[0] <= sparse_shift_output_steps_counter;
            o_sparse_shift_output_steps_counter_systolic[0] <= sparse_shift_output_steps_counter_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_shift_output_steps_counter_systolic[i] <= o_sparse_shift_output_steps_counter_systolic[i-1];
            end
            o_post_processing_shift_output_steps_counter_systolic[0] <= o_sparse_shift_output_steps_counter_systolic[0]; // one cycle delay 
            // o_post_processing_shift_output_steps_counter_systolic[0] <= o_sparse_shift_output_steps_counter_systolic[1]; // two cycles delay
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_post_processing_shift_output_steps_counter_systolic[i] <= o_post_processing_shift_output_steps_counter_systolic[i-1];
            end
            // o_post_processing_shift_output_steps_counter_systolic <= o_sparse_shift_output_steps_counter_systolic;


            
            // o_sparse_update_latched_reg_file_systolic[0] <= sparse_update_latched_reg_file;
            o_sparse_update_latched_reg_file_systolic[0] <= sparse_update_latched_reg_file_delay[0];
            for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                o_sparse_update_latched_reg_file_systolic[i] <= o_sparse_update_latched_reg_file_systolic[i-1];
            end

            // o_sparse_shift_output_steps_counter_finished_flag   <= sparse_shift_output_steps_counter_finished_flag;
            o_sparse_shift_output_steps_counter_finished_flag                   <= sparse_shift_output_steps_counter_finished_flag_delay[0];
            o_post_processing_sparse_shift_output_steps_counter_finished_flag   <= sparse_shift_output_steps_counter_finished_flag_delay[0]; // no delay
            // o_post_processing_sparse_shift_output_steps_counter_finished_flag   <= o_sparse_shift_output_steps_counter_finished_flag; // one cycle delay
            


            // o_sparse_weight_address_systolic[0] <= sparse_weight_address_comb;
            // for (int i=1; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            //     o_sparse_weight_address_systolic[i] <= o_sparse_weight_address_systolic[i-1];
            // end

            o_sparse_weight_address_systolic[0] <= sparse_weight_address_comb;
            // o_sparse_weight_address_systolic[0] <= sparse_weight_address_delay[0];
            o_sparse_weight_address_systolic[1] <= o_sparse_weight_address_systolic[0];
            o_sparse_weight_address_systolic[2] <= o_sparse_weight_address_systolic[1];

        end
    end

    always_comb begin
        // o_sparse_weight_address_systolic[0] = sparse_weight_address_comb; // saving one cycle to compensate for the inserted output register in weight memory.

        // o_sparse_shift_output_steps_counter_finished_flag   = sparse_shift_output_steps_counter_finished_flag;
        o_sparse_delayed_shift_partial_result_flag          = (i_sparse_kernel_steps_minus_1==0)? 1 : 0; 
    end

endmodule