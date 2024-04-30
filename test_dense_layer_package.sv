 
`timescale 1ns / 1ps 

package test_dense_layer_package;

import NVP_v1_constants::*;
import test_package::*;

    localparam SDK_FILE_NAME                = "test_neural_net";
    localparam BASE_DIRECTORY               = "/home/hasan/NVP_v1/tb/dense_layer_32_pes_8_bits_64_axi/";
    localparam AXI_BYTE_ACCESS_BITS         = 3;
    localparam OUTPUT_LINE_0_START_ADDRESS  = 6144;
    localparam OUTPUT_LINE_1_START_ADDRESS  = 8192;
    localparam OUTPUT_LINE_2_START_ADDRESS  = 10240;

    localparam ACTIVATION_ROWS              = 16; 
    localparam ACTIVATION_COLS              = 16;
    localparam ACTIVATION_CHANNELS          = 512;
    

    localparam LAYER_0_NUMBER_OF_KERNELS                            = 512;            
    localparam LAYER_0_STRIDED_CONV                                 = 0;    
    localparam LAYER_0_KERNEL_STEPS                                 = 16;    
    localparam LAYER_0_CHANNEL_STEPS                                = 16;        
    localparam LAYER_0_OUTPUT_SLICES                                = 4;        
    localparam LAYER_0_MAX_KERNELS_AND_PES                          = 512;            
    localparam LAYER_0_SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS           = 256;                            
    localparam LAYER_0_NUMBER_OF_OUTPUT_COLS                        = 16;                
    localparam LAYER_0_NUMBER_OF_OUTPUT_CH                          = 512;            
    localparam LAYER_0_NUMBER_OF_OUTPUT_ROWS                        = 16;                
    localparam LAYER_0_KERNEL_K                                     = 3;
    localparam LAYER_0_NUMBER_OF_WEIGHT_ENTRIES_PER_WEIGHT_ARRAY    = 98304;                                        
        
    neural_network_layer #(
        .LAYER_ID                            (0),
        .BASE_DIRECTORY                      (BASE_DIRECTORY),
        .AXI_BUS_DATA_BIT_WIDTH              (AXI_BUS_BIT_WIDTH),
        .AXI_BUS_ADDRESS_WIDTH               (AXI_BUS_ADDRESS_WIDTH),
        .WEIGHT_AXI_BUS_DATA_BIT_WIDTH       (WEIGHT_AXI_BUS_BIT_WIDTH),
        .WEIGHT_AXI_BUS_ADDRESS_WIDTH        (WEIGHT_AXI_BUS_ADDRESS_WIDTH),
        .CONTROL_AXI_DATA_WIDTH              (CONTROL_AXI_DATA_WIDTH),
        .CONTROL_AXI_ADDR_WIDTH              (CONTROL_AXI_ADDR_WIDTH),
        .export_file_name                    (SDK_FILE_NAME),
        .AXI_BYTE_ACCESS_BITS                (AXI_BYTE_ACCESS_BITS),
        .OUTPUT_LINE_0_START_ADDRESS         (OUTPUT_LINE_0_START_ADDRESS),
        .OUTPUT_LINE_1_START_ADDRESS         (OUTPUT_LINE_1_START_ADDRESS),
        .OUTPUT_LINE_2_START_ADDRESS         (OUTPUT_LINE_2_START_ADDRESS),
        .INPUT_NUMBER_OF_COLS                (ACTIVATION_COLS),            
        .INPUT_NUMBER_OF_CH                  (ACTIVATION_CHANNELS),        
        .INPUT_NUMBER_OF_ROWS                (ACTIVATION_ROWS),            
        .STRIDED_CONV                        (LAYER_0_STRIDED_CONV),
        .KERNEL_STEPS                        (LAYER_0_KERNEL_STEPS),
        .CHANNEL_STEPS                       (LAYER_0_CHANNEL_STEPS),
        .OUTPUT_SLICES                       (LAYER_0_OUTPUT_SLICES),
        .SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS  (LAYER_0_SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS),
        .NUMBER_OF_WEIGHT_ARRAY_ENTRIES      (LAYER_0_NUMBER_OF_WEIGHT_ENTRIES_PER_WEIGHT_ARRAY),
        .NUMBER_OF_OUTPUT_COLS               (LAYER_0_NUMBER_OF_OUTPUT_COLS),            
        .NUMBER_OF_OUTPUT_CH                 (LAYER_0_NUMBER_OF_OUTPUT_CH),            
        .NUMBER_OF_OUTPUT_ROWS               (LAYER_0_NUMBER_OF_OUTPUT_ROWS)         
    ) layer_0;
             

endpackage
    
