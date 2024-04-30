/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Accelerator Functions and Datatypes Package 
*   Date:  21.09.2021
*   Author: hasan
*   Description: A Package that holds top level datatype definitions and functions. 
*/


`timescale 1ns / 1ps


package NVP_v1_package;
 
import NVP_v1_constants::*;
 
    // // typedef logic[DATA_WIDTH-1:0]               data_t;         
    // // typedef logic[WEIGHT_WIDTH-1:0]             weight_t;       
    // // typedef logic[DATAMWEIGHT_WIDTH-1:0]        dwdata_t;       // Type describing the result of a multiplication between weight and data.
    // // typedef logic[UNQUANTIZED_WIDTH-1:0]        unquantized_t;  
    
    // // typedef enum logic { NO_ACTIVATION = 0, RELU = 1 }        activation_t; // Type describing which activation function should be used.
    // // typedef enum logic { NO_POOLING = 0, MAX_POOLING = 1 }    pooling_t;    // Type describing which pooling function should be used.    
    // // typedef logic[POOLING_COUNT_WIDTH-1:0]      pooling_count_t; // Type describing the number of pooled values.

    // /**
    // * Multiplies two values. 
    // **/
    // function automatic dwdata_t f_multiply(data_t data, weight_t weight);
    //     return (signed'(data) * signed'(weight));
    // endfunction

    // /**
    // * Quantizes an unquantized value to a quantized data value.
    // **/
    // function automatic data_t f_quantize(unquantized_t unquantized);
    
    //     // Weights and input data is currently set to 16 Bit with a 8.8 fixed-point representation.
    //     // Multiplied results will be 16.16 and the accumulated result has a representation of 32.16
    //     // (48 Bit is the maximum for DSP block in FPGAs).
    
    //     // We have to trim the result back to 8 fractional bits
    //     logic[UNQUANTIZED_WIDTH-HALF_DATA_WIDTH-1:0] unquantized_trimmed;
    //     data_t quantized;
        
    //     // Trim the value to the fraction of the fixed point representation
    //     unquantized_trimmed = unquantized[UNQUANTIZED_WIDTH-1:HALF_DATA_WIDTH];
        
        
    //     // Set the value to the boundaries, if it's outside of the bounds
    //     if($signed(unquantized_trimmed) < DATA_MIN_VALUE) begin
    //         quantized = DATA_MIN_VALUE;
    //     end
    //     else if($signed(unquantized_trimmed) > DATA_MAX_VALUE) begin
    //         quantized = DATA_MAX_VALUE;
    //     end
    //     else begin
    //         // Assign the actual result
    //         quantized = unquantized_trimmed[DATA_WIDTH-1:0];
    //     end
        
    //     return quantized;
    // endfunction	
	
    // /**
    // * Returns the maximum of two numbers.
    // **/
    // function automatic int f_max(input int a, input int b);
	// return (a > b) ? a : b;
    // endfunction
    
    // /**
    // * Activates a quantized value with a given activation function.
    // **/
    // function automatic data_t f_activate(activation_t activation_function, data_t quantized_data);
    //     case(activation_function)
    //         NO_ACTIVATION:
    //             begin
    //                 // Do nothing to the input data
    //                 return quantized_data;
    //             end
    //         RELU:
    //             begin
    //                 if(quantized_data[DATA_WIDTH-1]) begin
    //                     // Input is negative
    //                     return 0;
    //                 end
    //                 else begin
    //                     // Input is positive
    //                     return quantized_data;
    //                 end
    //             end
    //         default:
    //             begin
    //                 // Shouldn't happen, do nothing to the input data
    //                 return quantized_data;
    //             end
    //     endcase
    // endfunction

endpackage
