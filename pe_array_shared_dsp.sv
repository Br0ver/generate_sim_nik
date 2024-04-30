/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  PE Array - shared DSP
*   Date:  16.03.2022
*   Author: hasan
*   Description: Every two PEs share one DSP slice to perform two 8-bit multiplications.
*/

`timescale 1ns / 1ps

module pe_array #(
    parameter int NUMBER_OF_PES_PER_ARRAY           = NVP_v1_constants::NUMBER_OF_PES_PER_ARRAY,
    parameter int ACTIVATION_BIT_WIDTH              = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int WEIGHT_BIT_WIDTH                  = NVP_v1_constants::WEIGHT_BIT_WIDTH,
    parameter int ACCUMULATOR_BIT_WIDTH             = NVP_v1_constants::ACCUMULATOR_BIT_WIDTH,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH   = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS)
)(
    input  logic                                        clk,
    input  logic                                        resetn,
    input  logic [ACTIVATION_BIT_WIDTH-1:0]             i_activation_data       [NUMBER_OF_PES_PER_ARRAY],
    input  logic [WEIGHT_BIT_WIDTH-1:0]                 i_weight_data           [NUMBER_OF_PES_PER_ARRAY],
    input  logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]   i_accumulator_index, 
    input  logic                                        i_enable,
    input  logic                                        i_delayed_shift_partial_result_flag,
    input  logic                                        i_shift_partial_result,
    input  logic                                        i_reset_accumulators,
    input  logic [ACCUMULATOR_BIT_WIDTH-1:0]            i_partial_result  [NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS], 
    output logic [ACCUMULATOR_BIT_WIDTH-1:0]            o_result          [NUMBER_OF_PES_PER_ARRAY][SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS]
);

    // --------------------------------------
    // ------ PEs
	// --------------------------------------
    generate
        for (genvar i=0; i < NUMBER_OF_PES_PER_ARRAY; i++) begin
            pe #(
                .ACTIVATION_BIT_WIDTH  (ACTIVATION_BIT_WIDTH),
                .WEIGHT_BIT_WIDTH      (WEIGHT_BIT_WIDTH),
                .ACCUMULATOR_BIT_WIDTH (ACCUMULATOR_BIT_WIDTH)
            ) pe_i (
                .clk                                    (clk),    
                .resetn                                 (resetn),
                .i_activation_data                      (i_activation_data[i]),
                .i_weight_data                          (i_weight_data[i]),
                .i_enable                               (i_enable),
                .i_accumulator_index                    (i_accumulator_index),
                .i_delayed_shift_partial_result_flag    (i_delayed_shift_partial_result_flag),
                .i_shift_partial_result                 (i_shift_partial_result),
                .i_reset_accumulators                   (i_reset_accumulators),
                .i_partial_result                       (i_partial_result[i]),
                .o_result                               (o_result[i])
            );
        end
    endgenerate



endmodule