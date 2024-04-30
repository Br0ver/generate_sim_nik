/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP_v1 Constants
*   Date:  13.01.2022
*   Author: hasan
*   Description: A Package that holds all top level parameters. Relevant parameters are propagated to all modules. 
*/

`timescale 1ns / 1ps


package NVP_v1_constants;

    //-------------------
    //---- DEBUG PARAMETERS
    //-------------------
    parameter XILINX_SYNTHESIS  = 1;  // "1" means yes.  
    parameter DEBUG     = 1; 
    //-------------------
	
    parameter SPARSE_MODE = 0;
    parameter DENSE_MODE  = 1;

    parameter PING = 0;
    parameter PONG = 1;

    // --------------------------------------
    // ------ Data Precision
    // --------------------------------------   
    parameter ACTIVATION_BIT_WIDTH  = 8;
    // parameter ACTIVATION_MIN_VALUE  = 0;
    // parameter ACTIVATION_MAX_VALUE  = 2**(ACTIVATION_BIT_WIDTH)-1;
    parameter ACTIVATION_MIN_VALUE  = -1*2**(ACTIVATION_BIT_WIDTH-1);
    parameter ACTIVATION_MAX_VALUE  = 2**(ACTIVATION_BIT_WIDTH-1)-1;
    parameter WEIGHT_BIT_WIDTH      = 8;
    // parameter ACCUMULATOR_BIT_WIDTH     = 48; // xilinx DSP accumulator 
    parameter ACCUMULATOR_BIT_WIDTH        = WEIGHT_BIT_WIDTH+ACTIVATION_BIT_WIDTH+4; 
    parameter BIAS_BIT_WIDTH               = ACCUMULATOR_BIT_WIDTH; // Can also be 24...
    parameter BIAS_BIT_WIDTH_AXI           = 32; // This parameter is used to simplify the bias buffer design and its interface with the weight axi bus. It should be equal to "BIAS_BIT_WIDTH" rounded to the closest power of two.
    parameter QUANTIZATION_SCALE_BIT_WIDTH = 18;

    // --------------------------------------
    // ------ Streams and PE Arrays
    // --------------------------------------   
    parameter NUMBER_OF_READ_STREAMS        = 3;
    parameter NUMBER_OF_PE_ARRAY_ROWS       = 1;
    parameter NUMBER_OF_PE_ARRAYS_PER_ROW   = 3;
    parameter NUMBER_OF_PE_ARRAYS           = NUMBER_OF_PE_ARRAY_ROWS*NUMBER_OF_PE_ARRAYS_PER_ROW;
    parameter NUMBER_OF_PES_PER_ARRAY       = 16;

    parameter SUPPORTED_MAX_NUMBER_OF_PES_PER_ARRAY             = 64;
    parameter SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS              = 4;
    parameter SUPPORTED_MAX_NUMBER_OF_KERNELS                   = SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS*NUMBER_OF_PES_PER_ARRAY;
    parameter SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS             = SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS;
    parameter SUPPORTED_MAX_NUMBER_OF_CHANNELS                  = SUPPORTED_MAX_NUMBER_OF_KERNELS;
    parameter SUPPORTED_MAX_NUMBER_OF_COLUMNS                   = 129; // the maximum is "SUPPORTED_MAX_NUMBER_OF_COLUMNS-1" 
    parameter SUPPORTED_MAX_NUMBER_OF_OUTPUTS                   = SUPPORTED_MAX_NUMBER_OF_COLUMNS*SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS;
    parameter SUPPORTED_MAX_NUMBER_OF_ELEMENT_WISE_ADD_COLUMNS  = SUPPORTED_MAX_NUMBER_OF_COLUMNS/4; // it can be up to "SUPPORTED_MAX_NUMBER_OF_COLUMNS", but element-wise add usually happens after some spatial size reduction 

    parameter CHANNEL_VALUE_BIT_WIDTH   = $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNELS);
    parameter COLUMN_VALUE_BIT_WIDTH    = 2; // this only indicates a change in the column. 
    parameter ROW_VALUE_BIT_WIDTH       = $clog2(NUMBER_OF_READ_STREAMS); // this indicates the relative row.
    // parameter ROUTING_CODE_BIT_WIDTH    = 2;

    // --------------------------------------
    // ------ Decoded data combined order 
    // After the compressed stream decoders decompress the stored activation streams, each stream's data is combined to be stored in a buffer. This is how they are combined in a single word.
    // -------------------------------------- 
    parameter COMBINED_DATA_BIT_WIDTH  = ACTIVATION_BIT_WIDTH+CHANNEL_VALUE_BIT_WIDTH+COLUMN_VALUE_BIT_WIDTH+ROW_VALUE_BIT_WIDTH+2; // +2: one "valid" bit, one "last_column" bit
    parameter VALID_MSB             = 0;
    parameter LAST_COLUMN_MSB       = 1;
    parameter RELATIVE_ROW_MSB      = LAST_COLUMN_MSB + ROW_VALUE_BIT_WIDTH;
    parameter CHANNEL_MSB           = RELATIVE_ROW_MSB + CHANNEL_VALUE_BIT_WIDTH;
    parameter TOGGLED_COLUMN_MSB    = CHANNEL_MSB + COLUMN_VALUE_BIT_WIDTH;
    parameter ACTIVATION_DATA_MSB   = TOGGLED_COLUMN_MSB + ACTIVATION_BIT_WIDTH;

    parameter AXI_BIT_WIDTH = 64;

    // --------------------------------------
    // ------ Activation Memory & Bus
    // --------------------------------------     
    parameter AXI_BUS_BIT_WIDTH                         = AXI_BIT_WIDTH;
    // parameter NUMBER_OF_ACTIVATION_LINE_BUFFERS         = NUMBER_OF_READ_STREAMS*2;
    parameter NUMBER_OF_ACTIVATION_LINE_BUFFERS         = NUMBER_OF_READ_STREAMS*2;
    parameter ACTIVATION_LINE_BUFFER_DEPTH              = 512; // single line buffer // TODO:: set me properly
    parameter ACTIVATION_BANK_BIT_WIDTH                 = AXI_BUS_BIT_WIDTH; // 
    parameter ACTIVATION_BUFFER_BANK_COUNT              = NUMBER_OF_PES_PER_ARRAY*ACTIVATION_BIT_WIDTH/ACTIVATION_BANK_BIT_WIDTH; 
    parameter ACTIVATION_LINE_BUFFER_SIZE               = ACTIVATION_LINE_BUFFER_DEPTH*ACTIVATION_BUFFER_BANK_COUNT*ACTIVATION_BANK_BIT_WIDTH/8; 
    parameter ACTIVATION_BUFFER_TOTAL_SIZE              = NUMBER_OF_ACTIVATION_LINE_BUFFERS*ACTIVATION_LINE_BUFFER_DEPTH*ACTIVATION_BUFFER_BANK_COUNT*ACTIVATION_BANK_BIT_WIDTH/8;
    parameter OUTPUT_WRITER_ADDRESS_BIT_WIDTH           = $clog2(ACTIVATION_BUFFER_BANK_COUNT) + $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS) + $clog2(ACTIVATION_LINE_BUFFER_DEPTH);
    parameter ACTIVATION_LINE_BUFFER_0_START_ADDRESS    = 0;
    parameter ACTIVATION_LINE_BUFFER_1_START_ADDRESS    = ACTIVATION_LINE_BUFFER_0_START_ADDRESS + ACTIVATION_LINE_BUFFER_SIZE;
    parameter ACTIVATION_LINE_BUFFER_2_START_ADDRESS    = ACTIVATION_LINE_BUFFER_1_START_ADDRESS + ACTIVATION_LINE_BUFFER_SIZE;
    parameter ACTIVATION_LINE_BUFFER_3_START_ADDRESS    = ACTIVATION_LINE_BUFFER_2_START_ADDRESS + ACTIVATION_LINE_BUFFER_SIZE;
    parameter ACTIVATION_LINE_BUFFER_4_START_ADDRESS    = ACTIVATION_LINE_BUFFER_3_START_ADDRESS + ACTIVATION_LINE_BUFFER_SIZE;
    parameter ACTIVATION_LINE_BUFFER_5_START_ADDRESS    = ACTIVATION_LINE_BUFFER_4_START_ADDRESS + ACTIVATION_LINE_BUFFER_SIZE;
    parameter AXI_BUS_ADDRESS_WIDTH                     = $clog2(ACTIVATION_BUFFER_TOTAL_SIZE);

    // --------------------------------------
    // ------ Weight Memory & Bus
    // -------------------------------------- 
    parameter WEIGHT_AXI_BUS_BIT_WIDTH              = AXI_BIT_WIDTH;    
    parameter NUMBER_OF_WEIGHT_LINE_BUFFERS         = NUMBER_OF_PE_ARRAYS_PER_ROW;
    parameter WEIGHT_BANK_BIT_WIDTH                 = WEIGHT_AXI_BUS_BIT_WIDTH; 
    parameter WEIGHT_LINE_BUFFER_DEPTH              = 512; // TODO:: set me properly
    parameter WEIGHT_BUFFER_BANK_COUNT              = NUMBER_OF_PES_PER_ARRAY*WEIGHT_BIT_WIDTH/WEIGHT_BANK_BIT_WIDTH;
    parameter WEIGHT_LINE_BUFFER_SIZE               = WEIGHT_LINE_BUFFER_DEPTH*WEIGHT_BUFFER_BANK_COUNT*WEIGHT_BANK_BIT_WIDTH/8; 
    parameter WEIGHT_BUFFER_TOTAL_SIZE              = NUMBER_OF_WEIGHT_LINE_BUFFERS*WEIGHT_LINE_BUFFER_DEPTH*WEIGHT_BUFFER_BANK_COUNT*WEIGHT_BANK_BIT_WIDTH/8;
    parameter WEIGHT_LINE_BUFFER_0_START_ADDRESS    = 0;
    parameter WEIGHT_LINE_BUFFER_1_START_ADDRESS    = WEIGHT_LINE_BUFFER_0_START_ADDRESS + WEIGHT_LINE_BUFFER_SIZE;
    parameter WEIGHT_LINE_BUFFER_2_START_ADDRESS    = WEIGHT_LINE_BUFFER_1_START_ADDRESS + WEIGHT_LINE_BUFFER_SIZE;
    parameter BIAS_LINE_BUFFER_START_ADDRESS        = 1 << $clog2(WEIGHT_BUFFER_TOTAL_SIZE);
    parameter WEIGHT_AXI_BUS_ADDRESS_WIDTH          = $clog2(WEIGHT_BUFFER_TOTAL_SIZE) + 1; // TODO:: check bias buffer selection bit

    // --------------------------------------
    // ------ Bias Memory & Bus
    // -------------------------------------- 
    parameter BIAS_LINE_BUFFER_DEPTH = NUMBER_OF_PES_PER_ARRAY*SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS/8; 
    parameter BIAS_BANK_BIT_WIDTH    = WEIGHT_AXI_BUS_BIT_WIDTH;
    parameter BIAS_BUFFER_BANK_COUNT = (8*BIAS_BIT_WIDTH_AXI)/BIAS_BANK_BIT_WIDTH;
    parameter BIAS_BUFFER_TOTAL_SIZE = BIAS_LINE_BUFFER_DEPTH*BIAS_BUFFER_BANK_COUNT*BIAS_BANK_BIT_WIDTH/8;

    // --------------------------------------
    // ------ Intermediate FIFOs Depth
    // -------------------------------------- 
    parameter COMBINED_DATA_FIFO_DEPTH = 16;
    parameter PE_DATA_FIFO_DEPTH       = 16;
    parameter PW_DATA_FIFO_DEPTH       = 0;
    parameter OUTPUT_FIFO_DEPTH        = 512; // TODO:: must reduce stalls in  post-processing pipeline... // This fifo has to be large to hold outputs until output_stage is ready. (output stage slice the output into "ACTIVATION_BIT_WIDTH" segments)  
    parameter OUTPUT_STAGE_FIFO_DEPTH  = 256; // TODO:: calculate minimum size

    // --------------------------------------
    // ------ Register File
    // --------------------------------------   
    parameter REGISTER_WIDTH                            = 32;
    parameter NUMBER_OF_REGISTERS                       = 10; // TODO:: minimize number of registers. 
    parameter STREAM_1_PTR_REGISTER                     = 0;
    parameter STREAM_2_PTR_REGISTER                     = 1;
    parameter STREAM_3_PTR_REGISTER                     = 2;
    parameter NUMBER_OF_CONV_LAYER_COLS_REGISTER        = 3;
    parameter EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER = 3;
    parameter CHANNELS_MINUS_8_REGISTER                 = 4;
    parameter QUANTIZATION_SCALE_REGISTER               = 4;
    parameter KERNEL_STEPS_MINUS_1_REGISTER             = 5; 
    parameter NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER   = 5; 
    parameter WEIGHT_ADDRESS_OFFSET_REGISTER            = 5; 
    parameter CHANNEL_STEPS_REGISTER                    = 6; 
    parameter BIAS_STEPS_REGISTER                       = 6; 
    parameter NUMBER_OF_CHANNELS_REGISTER               = 7;
    parameter STREAM_WRITER_REGISTER                    = 8; 
    parameter CONTROL_FLAGS_REGISTER                    = NUMBER_OF_REGISTERS-1;
    parameter NUMBER_OF_PRE_REGISTERS                   = 5;
    parameter NUMBER_OF_INTRA_REGISTERS                 = 5;
    parameter integer PRE_REGISTER_LIST   [NUMBER_OF_PRE_REGISTERS] = {NUMBER_OF_CONV_LAYER_COLS_REGISTER, CHANNELS_MINUS_8_REGISTER, KERNEL_STEPS_MINUS_1_REGISTER, CHANNEL_STEPS_REGISTER, NUMBER_OF_CHANNELS_REGISTER}; // These are configured only once per layer.
    parameter integer INTRA_REGISTER_LIST [NUMBER_OF_INTRA_REGISTERS] = {CONTROL_FLAGS_REGISTER, STREAM_1_PTR_REGISTER, STREAM_2_PTR_REGISTER, STREAM_3_PTR_REGISTER, STREAM_WRITER_REGISTER}; // These are configured per trigger. CONTROL_FLAGS_REGISTER is configured per trigger.

    // register_0, register_1, register_2 sllicing 
    parameter STREAM_PING_PONG_BIT_INDEX    = 0; 
    parameter STREAM_RELATIVE_ROW_MSB       = 2; 
    parameter STREAM_RELATIVE_ROW_LSB       = 1; 
    parameter STREAM_START_ADDRESS_MSB      = REGISTER_WIDTH-1; 
    parameter STREAM_START_ADDRESS_LSB      = STREAM_START_ADDRESS_MSB - $clog2(ACTIVATION_LINE_BUFFER_DEPTH); 
    // register_3 slicing
    parameter NUMBER_OF_CONV_LAYER_COLS_MSB = REGISTER_WIDTH-1;
    parameter NUMBER_OF_CONV_LAYER_COLS_LSB = NUMBER_OF_CONV_LAYER_COLS_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS);
    parameter EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB = NUMBER_OF_CONV_LAYER_COLS_LSB-1;
    parameter EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB = EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_OUTPUTS);
    // register_4 slicing
    parameter CHANNELS_MINUS_8_MSB      = REGISTER_WIDTH-1;
    parameter CHANNELS_MINUS_8_LSB      = CHANNELS_MINUS_8_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNELS);
    parameter QUANTIZATION_SCALE_MSB    = CHANNELS_MINUS_8_LSB-1;
    parameter QUANTIZATION_SCALE_LSB    = QUANTIZATION_SCALE_MSB - QUANTIZATION_SCALE_BIT_WIDTH;
    // register_5 slicing 
    parameter KERNEL_STEPS_MINUS_1_MSB = REGISTER_WIDTH-1;
    parameter KERNEL_STEPS_MINUS_1_LSB = KERNEL_STEPS_MINUS_1_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS);
    parameter NUMBER_OF_OUTPUT_SLICING_STEPS_MSB = KERNEL_STEPS_MINUS_1_LSB-1;
    parameter NUMBER_OF_OUTPUT_SLICING_STEPS_LSB = NUMBER_OF_OUTPUT_SLICING_STEPS_MSB - $clog2(NUMBER_OF_PES_PER_ARRAY/ACTIVATION_BIT_WIDTH);
    parameter WEIGHT_ADDRESS_OFFSET_MSB          = NUMBER_OF_OUTPUT_SLICING_STEPS_LSB-1;
    parameter WEIGHT_ADDRESS_OFFSET_LSB          = WEIGHT_ADDRESS_OFFSET_MSB - $clog2(WEIGHT_LINE_BUFFER_DEPTH); 
    // assert (WEIGHT_ADDRESS_OFFSET_LSB >= 0) else $error("Register 5 assignment is larger than register width.");
    // register_6 slicing
    parameter CHANNEL_STEPS_MSB = REGISTER_WIDTH-1;
    parameter CHANNEL_STEPS_LSB = CHANNEL_STEPS_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS);
    parameter BIAS_STEPS_MSB    = CHANNEL_STEPS_LSB-1;
    parameter BIAS_STEPS_LSB    = BIAS_STEPS_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_KERNELS/ACTIVATION_BIT_WIDTH);
    // register_7 slicing
    parameter NUMBER_OF_CHANNELS_MSB = REGISTER_WIDTH-1;
    parameter NUMBER_OF_CHANNELS_LSB = NUMBER_OF_CHANNELS_MSB - $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNELS);
    // register_8 slicing
    parameter STREAM_WRITER_ADDRESS_MSB = REGISTER_WIDTH-1;
    parameter STREAM_WRITER_ADDRESS_LSB = STREAM_WRITER_ADDRESS_MSB - OUTPUT_WRITER_ADDRESS_BIT_WIDTH;
    // register_9 slicing
    parameter EXECUTION_FLAG_BIT_INDEX              = 0;
    parameter START_STREAM_READERS_BIT_INDEX        = 1;
    parameter STREAM_MODE_BIT_INDEX                 = 2;
    parameter PW_CONV_BIT_INDEX                     = 3;
    // parameter WEIGHT_PING_PONG_BIT_INDEX            = 4;
    parameter STRIDED_CONV_BIT_INDEX                = 5;
    parameter STREAM_1_ENABLE_INDEX                 = 6;
    parameter STREAM_2_ENABLE_INDEX                 = 7;
    parameter STREAM_3_ENABLE_INDEX                 = 8;
    parameter ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX  = 9;
    parameter ELEMENT_WISE_ADD_BIT_INDEX            = 10;
    parameter STREAM_READERS_PING_PONG_BIT_INDEX    = 11; 
    parameter COMPRESS_OUTPUT_BIT_INDEX             = 12; 
    parameter BIAS_ENABLE_BIT_INDEX                 = 13;   
    parameter RELU_ENABLE_BIT_INDEX                 = 14;

    // --------------------------------------
    // ------ Control Bus
    // -------------------------------------- 
    parameter CONTROL_AXI_DATA_WIDTH    = REGISTER_WIDTH;
    parameter CONTROL_AXI_ADDR_WIDTH    = $clog2(NUMBER_OF_REGISTERS*REGISTER_WIDTH/8);
    
    
endpackage
