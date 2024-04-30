/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  PE
*   Date:  06.12.2021
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module pe #(
    parameter int ACTIVATION_BIT_WIDTH              = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int WEIGHT_BIT_WIDTH                  = NVP_v1_constants::WEIGHT_BIT_WIDTH,
    parameter int ACCUMULATOR_BIT_WIDTH             = NVP_v1_constants::ACCUMULATOR_BIT_WIDTH,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH   = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS)
)(
    input  logic                                        clk,
    input  logic                                        resetn, 
    input  logic [ACTIVATION_BIT_WIDTH-1:0]             i_activation_data, 
    input  logic [WEIGHT_BIT_WIDTH-1:0]                 i_weight_data, 
    input  logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]   i_accumulator_index, 
    input  logic                                        i_enable,
    input  logic                                        i_reset_accumulators, 
    input  logic                                        i_delayed_shift_partial_result_flag, // when '1', the "i_shift_partial_result" is not ready at the shift clock cycle. To solve this, the data is shifted in the next clock cycle. This happens for example when there are no kernel_steps in SPARSE mode.
    input  logic                                        i_shift_partial_result,
    input logic [ACCUMULATOR_BIT_WIDTH-1:0]             i_partial_result [SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS],
    output logic [ACCUMULATOR_BIT_WIDTH-1:0]            o_result [SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS]
);


    logic shift_partial_result_one_cycle_delayed;
    logic reset_accumulators_one_cycle_delayed;
    always_ff @(posedge clk)
    begin
        if(resetn==0) begin
            shift_partial_result_one_cycle_delayed  <= 0;
            reset_accumulators_one_cycle_delayed    <= 0;
        end
        else begin
            shift_partial_result_one_cycle_delayed  <= i_shift_partial_result;
            reset_accumulators_one_cycle_delayed    <= i_reset_accumulators;
        end
    end


    logic zero_gating; 
    // always_comb zero_gating = (i_weight_data==0 || i_activation_data==0 || i_enable==0)? 1 : 0;
    always_comb zero_gating = (i_weight_data==0 || i_activation_data==0)? 1 : 0;

    logic enable;
    always_comb enable = i_enable || i_shift_partial_result || i_reset_accumulators || shift_partial_result_one_cycle_delayed;

    (* use_dsp = "yes" *) 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  accumulator_ff [SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS]; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  selected_accumulator; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  selected_partial_result; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  accumulator_comb; 

    logic [ACCUMULATOR_BIT_WIDTH-1:0]  MAC_comb; 

    logic [ACTIVATION_BIT_WIDTH-1:0]   activation_data_delayed;
    logic [WEIGHT_BIT_WIDTH-1:0]       weight_data_delayed;
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  accumulator_comb_delayed; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  selected_accumulator_delayed; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  selected_partial_result_delayed; 
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]   accumulator_index_delayed;
    logic                                        enable_delayed;

    logic [ACCUMULATOR_BIT_WIDTH-1:0]  multiplier_comb_unsigned; 
    logic [ACCUMULATOR_BIT_WIDTH-1:0]  multiplier_comb_signed; 

    always_ff @(posedge clk) begin
        if(resetn==0) begin
            for (int i=0; i<SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS; i++) begin
                accumulator_ff[i] <= '{default:0};            
            end
        end
        else begin   
            if (enable==1) begin 
                // accumulator_ff[i_accumulator_index] <= (signed'(i_activation_data) * signed'(i_weight_data)) + signed'(accumulator_comb);
                accumulator_ff[i_accumulator_index] <= (signed'(ACCUMULATOR_BIT_WIDTH'(i_activation_data)) * signed'(i_weight_data)) + signed'(accumulator_comb);
                
                // if(zero_gating==1)
                //     accumulator_ff[i_accumulator_index] <= signed'(accumulator_comb);
                // else
                //     accumulator_ff[i_accumulator_index] <= (signed'(i_activation_data) * signed'(i_weight_data)) + signed'(accumulator_comb);
            end
        end
    end
    
    always_comb begin 
        selected_accumulator    = (i_reset_accumulators==1)? '0 : accumulator_ff[i_accumulator_index]; 
        selected_partial_result = (i_reset_accumulators==1)? '0 : i_partial_result[i_accumulator_index];


        if(i_delayed_shift_partial_result_flag==1) begin 
            // delayed shift takes place when kernel_steps==1. This happens due to the systolic operation of the pe arrays. 
            // The problem occurs because the input partial result from the neighboring pe array is not ready at the shift clock cycle. 


            if(i_shift_partial_result==1 || reset_accumulators_one_cycle_delayed==1) begin
                accumulator_comb = '0;    
            end
            else begin
                if(shift_partial_result_one_cycle_delayed==1) begin
                    accumulator_comb = selected_accumulator + selected_partial_result;
                end
                else begin
                    accumulator_comb = selected_accumulator;    
                end
            end
        end
        else begin
            accumulator_comb = (i_shift_partial_result==1)? selected_partial_result : selected_accumulator;
        end


    end

    always_comb o_result = accumulator_ff;

endmodule