/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: 
*   Date:   24.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

interface computation_control_if #(
    parameter int WEIGHT_BANK_DEPTH                     = 8,
    parameter int WEIGHT_BANK_BIT_WIDTH                 = 8,
    parameter int WEIGHT_BUFFER_BANK_COUNT              = 8,
    parameter int NUMBER_OF_PE_ARRAYS_PER_ROW           = 32,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = 4,
    parameter int BIAS_LINE_BUFFER_DEPTH                = 4,
    parameter int BIAS_BANK_BIT_WIDTH                   = 4,
    parameter int BIAS_BUFFER_BANK_COUNT                = 4,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS)
)();
    // weight memory 
    logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                      weight_memory_address [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_memory_data [NUMBER_OF_PE_ARRAYS_PER_ROW];

    logic[$clog2(BIAS_LINE_BUFFER_DEPTH)-1:0]               bias_memory_address;
    logic[BIAS_BANK_BIT_WIDTH*BIAS_BUFFER_BANK_COUNT-1:0]   bias_memory_data;


    // compute units
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]  kernel_step_index           [NUMBER_OF_PE_ARRAYS_PER_ROW]; 
    logic                                       reset_accumulators          [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic                                       delayed_shift_partial_result_flag;
    logic                                       shift_partial_result        [NUMBER_OF_PE_ARRAYS_PER_ROW];
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]  shift_output_steps_counter  [NUMBER_OF_PE_ARRAYS_PER_ROW]; 
    
    logic                                       shift_output_steps_counter_finished_flag;
    logic                                       last_column_finished;

    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0]  post_processing_shift_output_steps_counter  [NUMBER_OF_PE_ARRAYS_PER_ROW]; 
    logic                                       post_processing_shift_output_steps_counter_finished_flag;
    logic                                       post_processing_shift_partial_result        [NUMBER_OF_PE_ARRAYS_PER_ROW];


    // logic enable;

    modport master     (output kernel_step_index, 
        shift_output_steps_counter, 
        shift_output_steps_counter_finished_flag, 
        last_column_finished, 
        reset_accumulators, 
        delayed_shift_partial_result_flag, 
        shift_partial_result, 
        weight_memory_address, 
        post_processing_shift_output_steps_counter,
        post_processing_shift_output_steps_counter_finished_flag,
        post_processing_shift_partial_result,
        input weight_memory_data
        );

    modport slave      (input kernel_step_index, 
    shift_output_steps_counter, 
    shift_output_steps_counter_finished_flag, 
    last_column_finished, 
    reset_accumulators, 
    delayed_shift_partial_result_flag, 
    shift_partial_result, 
    weight_memory_address, 
    post_processing_shift_output_steps_counter, 
    post_processing_shift_output_steps_counter_finished_flag,
    post_processing_shift_partial_result,
    output weight_memory_data);

    // modport control     (output kernel_step_index, shift_output_steps_counter, shift_output_steps_counter_finished_flag, last_column_finished, reset_accumulators, delayed_shift_partial_result_flag, shift_partial_result, weight_memory_address, input weight_memory_data);
    // modport memory      (input  weight_memory_address, output weight_memory_data);
    // modport compute     (input  kernel_step_index, shift_output_steps_counter, shift_output_steps_counter_finished_flag, last_column_finished, reset_accumulators, delayed_shift_partial_result_flag, shift_partial_result, weight_memory_data);
endinterface
