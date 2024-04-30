/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  PE Array 
*   Date:  06.12.2021
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps


import NVP_v1_constants::*;
//import NVP_v1_package::*;


module pe_row #(
    parameter  int NUMBER_OF_PES_PER_ARRAY              = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY, 
    parameter  int NUMBER_OF_PE_ARRAYS_PER_ROW          = NVP_v1_constants::NUMBER_OF_PE_ARRAYS_PER_ROW,
    parameter  int ACTIVATION_BIT_WIDTH                 = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter  int WEIGHT_BIT_WIDTH                     = NVP_v1_constants::WEIGHT_BIT_WIDTH,
    parameter  int WEIGHT_BANK_BIT_WIDTH                = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH,
    parameter  int WEIGHT_BUFFER_BANK_COUNT             = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter  int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS),
    localparam int ACCUMULATOR_BIT_WIDTH                = NVP_v1_constants::ACCUMULATOR_BIT_WIDTH
)(
    input  logic                                clk,
    input  logic                                resetn,
    computation_control_if                      computation_ctrl,
    compute_core_data_if                        compute_data,
    output logic [ACCUMULATOR_BIT_WIDTH-1:0]    o_output_activations      [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS]
);
    
    logic [ACTIVATION_BIT_WIDTH-1:0]    activation_data_comb    [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY];
    logic [WEIGHT_BIT_WIDTH-1:0]        weight_data_comb        [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY];
    logic [ACCUMULATOR_BIT_WIDTH-1:0]   output_activations_comb [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS];

    // --------------------------------------
    // ------ Slicing input activations and weights
	// --------------------------------------
    always_comb begin
        // slice input activation into "ACTIVATION_BIT_WIDTH" chunks.
        for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
                activation_data_comb[i][j] = compute_data.activations[i][(j+1)*ACTIVATION_BIT_WIDTH-1 -: ACTIVATION_BIT_WIDTH];
            end
        end
        // // slice input weights into "WEIGHT_BIT_WIDTH" chunks.
        // for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
        //     for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
        //         weight_data_comb[i][j] = compute_data.weights[i][(j+1)*WEIGHT_BIT_WIDTH-1 -: WEIGHT_BIT_WIDTH];
        //     end
        // end
        // slice input weights into "WEIGHT_BIT_WIDTH" chunks.
        for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
                weight_data_comb[i][j] = compute_data.weights[i][(NUMBER_OF_PES_PER_ARRAY-j)*WEIGHT_BIT_WIDTH-1 -: WEIGHT_BIT_WIDTH];
            end
        end
    end


    // --------------------------------------
    // ------ Output shifting logic  
	// --------------------------------------
    logic [ACCUMULATOR_BIT_WIDTH-1:0]    partial_result  [NUMBER_OF_PE_ARRAYS_PER_ROW][NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS];
    always_comb begin
        for (int i=0; i<NUMBER_OF_PE_ARRAYS_PER_ROW-1; i++) begin
            for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
                partial_result[i][j] = output_activations_comb[i+1][j];
            end
        end
        for (int j=0; j<NUMBER_OF_PES_PER_ARRAY; j++) begin
            partial_result[NUMBER_OF_PE_ARRAYS_PER_ROW-1][j] = '{default:0};
        end 
    end

    always_comb o_output_activations = output_activations_comb;


    logic reset_accumulator [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]   accumulator_index [NUMBER_OF_PE_ARRAYS_PER_ROW]; 

    // always_comb begin
    //     for (int i=0; i < NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
    //         if(computation_ctrl.reset_accumulators[i]==1) begin
    //             accumulator_index[i] = computation_ctrl.shift_output_steps_counter[i];
    //         end
    //         else begin
    //             accumulator_index[i] = computation_ctrl.kernel_step_index[i];
    //         end
    //     end

    //     reset_accumulator = computation_ctrl.reset_accumulators;
    // end

    always_ff @(posedge clk) begin// systolic operation between pe arrays inside the same pe row. 
        // what should be pipelined: activations, weights, valid, output_activaions valid, clear accumulators, accumulator enable (according to relative row).
        if (resetn==0) begin
            accumulator_index             <= '{default:0};
            reset_accumulator             <= '{default:0};
        end
        else begin
            for (int i=0; i < NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
                if(computation_ctrl.reset_accumulators[i]==1) begin
                    accumulator_index[i] <= computation_ctrl.shift_output_steps_counter[i];
                end
                else begin
                    accumulator_index[i] <= computation_ctrl.kernel_step_index[i];
                end
            end

        reset_accumulator <= computation_ctrl.reset_accumulators;

        end
    end




    // --------------------------------------
    // ------ 3 PE arrays
	// --------------------------------------
    generate
        for (genvar i=0; i < NUMBER_OF_PE_ARRAYS_PER_ROW; i++) begin
            pe_array #(
                .NUMBER_OF_PES_PER_ARRAY        (NUMBER_OF_PES_PER_ARRAY),
                .ACTIVATION_BIT_WIDTH           (ACTIVATION_BIT_WIDTH),
                .WEIGHT_BIT_WIDTH               (WEIGHT_BIT_WIDTH),
                .ACCUMULATOR_BIT_WIDTH          (ACCUMULATOR_BIT_WIDTH)
            ) pe_array_i (
                .clk                                    (clk),
                .resetn                                 (resetn),
                .i_activation_data                      (activation_data_comb[i]),    
                .i_weight_data                          (weight_data_comb[i]),    
                .i_accumulator_index                    (accumulator_index[i]),
                .i_enable                               (compute_data.valid[i]), //TODO:: check me 
                .i_delayed_shift_partial_result_flag    (computation_ctrl.delayed_shift_partial_result_flag),
                .i_shift_partial_result                 (computation_ctrl.shift_partial_result[i]),
                // .i_reset_accumulators                   (computation_ctrl.reset_accumulators[i]),
                .i_reset_accumulators                   (reset_accumulator[i]),
                .i_partial_result                       (partial_result[i]),    
                .o_result                               (output_activations_comb[i])
            );
        end
    endgenerate

   
    
endmodule