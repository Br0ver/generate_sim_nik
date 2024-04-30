/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Address Generation Module
*   Date:   20.09.2021
*   Author: hasan
*   Description:  This module is responsible for generating addresses and their corresponding
*                   control signals. These signals are then propagated through the pipeline.
*/



`timescale 1ns / 1ps


import accelerator_package::*;

module address_generator #(
    parameter integer COMPUTE_ARRAY_HEIGHT = accelerator_constants::COMPUTE_ARRAY_HEIGHT,
    parameter integer COMPUTE_ARRAY_WIDTH  = accelerator_constants::COMPUTE_ARRAY_WIDTH,
    parameter integer REGISTER_WIDTH       = 32,
    parameter integer NUMBER_OF_REGISTERS  = 10,

    parameter integer IB_SRAM_DEPTH         = 4096,
    parameter integer IB_SRAM_BANK_COUNT    = 1,
    parameter integer WB_SRAM_DEPTH         = 1024,
    parameter integer WB_SRAM_BANK_COUNT    = 1,
    parameter integer OB_SRAM_DEPTH         = 4096,
    parameter integer OB_SRAM_BANK_COUNT    = 1, 

    parameter integer INPUT_WIDTH_BITS_WIDTH    = 11,
    parameter integer INPUT_HEIGHT_BITS_WIDTH   = 11,
    parameter integer INPUT_CHANNELS_BITS_WIDTH = 10,

    parameter integer KERNEL_WIDTH_BITS_WIDTH  = 5,
    parameter integer KERNEL_HEIGHT_BITS_WIDTH = 5,

    parameter integer BB_SRAM_DEPTH    	    = 16,
    parameter integer BB_SRAM_BANK_COUNT    = 1,

    parameter integer INPUT_CHANNEL_STEPS_BITS_WIDTH  = 11,
    parameter integer OUTPUT_CHANNEL_STEPS_BITS_WIDTH = 11,

    parameter integer OUTPUT_WIDTH_BITS_WIDTH    = 11,
    parameter integer OUTPUT_HEIGHT_BITS_WIDTH   = 11,
    parameter integer OUTPUT_CHANNELS_BITS_WIDTH = 10
    )(
    input logic clk, 
    input logic rst,  
    s_axi_lite_bus.slave control_bus,
    address_generator_to_buffer_control_interface.address_generator address_generator_to_buffer_control_if
);

    localparam integer CONVOLUTION_FUNCTION_BITS_START = REGISTER_WIDTH-1;
    localparam integer CONVOLUTION_FUNCTION_BITS_WIDTH = 8; 
    localparam integer CONVOLUTION_TYPE_BITS_START = CONVOLUTION_FUNCTION_BITS_WIDTH-1; 
    localparam integer CONVOLUTION_TYPE_BITS_WIDTH = 2;
    localparam integer CONVOLUTION_STRIDE_BITS_START = CONVOLUTION_TYPE_BITS_START - CONVOLUTION_TYPE_BITS_WIDTH; 
    localparam integer CONVOLUTION_STRIDE_BITS_WIDTH = 3; 
    localparam integer CONVOLUTION_DILATION_BITS_START = CONVOLUTION_STRIDE_BITS_START - CONVOLUTION_STRIDE_BITS_WIDTH; 
    localparam integer CONVOLUTION_DILATION_BITS_WIDTH = 3;
    /* XX_YYY_ZZZ 
    XX: convolution type. 
        00: dense conv
        01: ??
        10: dilated conv
    YYY: stride
        0 -> s=1
        1 -> s=2
        2 -> s=4
        3 -> s=8
        4 -> s=16
    ZZZ: dilation rate.
        0 -> d=1
        1 -> d=2
        2 -> d=4
        3 -> d=8
        4 -> d=16
    */
    localparam integer ACTIVATION_FUNCTION_BITS_START = CONVOLUTION_FUNCTION_BITS_START - CONVOLUTION_FUNCTION_BITS_WIDTH;
    localparam integer ACTIVATION_FUNCTION_BITS_WIDTH = 1;
    localparam integer POOLING_FUNCTION_BITS_START = ACTIVATION_FUNCTION_BITS_START - ACTIVATION_FUNCTION_BITS_WIDTH;
    localparam integer POOLING_FUNCTION_BITS_WIDTH = 1;
    localparam integer POOLING_COUNT_BITS_START = POOLING_FUNCTION_BITS_START - POOLING_FUNCTION_BITS_WIDTH;
    localparam integer POOLING_COUNT_BITS_WIDTH = 8; // 8 bits
    localparam integer END_SIGNAL_BITS_START = POOLING_COUNT_BITS_START - POOLING_COUNT_BITS_WIDTH;
    localparam integer END_SIGNAL_BITS_WIDTH = 1;
    localparam integer START_SIGNAL_BITS_START = END_SIGNAL_BITS_START - END_SIGNAL_BITS_WIDTH;
    localparam integer START_SIGNAL_BITS_WIDTH = 1; 
    initial assert (CONVOLUTION_FUNCTION_BITS_WIDTH + ACTIVATION_FUNCTION_BITS_WIDTH + POOLING_FUNCTION_BITS_WIDTH + POOLING_COUNT_BITS_WIDTH + END_SIGNAL_BITS_WIDTH + START_SIGNAL_BITS_WIDTH <= REGISTER_WIDTH);
    
    localparam integer INPUT_WIDTH_BITS_START = REGISTER_WIDTH-1;
    localparam integer INPUT_HEIGHT_BITS_START = INPUT_WIDTH_BITS_START - INPUT_WIDTH_BITS_WIDTH;
    localparam integer INPUT_CHANNELS_BITS_START = INPUT_HEIGHT_BITS_START - INPUT_HEIGHT_BITS_WIDTH;
    initial assert (INPUT_WIDTH_BITS_WIDTH + INPUT_HEIGHT_BITS_WIDTH + INPUT_CHANNELS_BITS_WIDTH <= REGISTER_WIDTH);

    localparam integer KERNEL_WIDTH_BITS_START = REGISTER_WIDTH-1;
    localparam integer KERNEL_HEIGHT_BITS_START = KERNEL_WIDTH_BITS_START - KERNEL_WIDTH_BITS_WIDTH;
    localparam integer INPUT_CHANNEL_STEPS_BITS_START = KERNEL_HEIGHT_BITS_START - KERNEL_HEIGHT_BITS_WIDTH;
    localparam integer OUTPUT_CHANNEL_STEPS_BITS_START = INPUT_CHANNEL_STEPS_BITS_START - INPUT_CHANNEL_STEPS_BITS_WIDTH;
    initial assert (KERNEL_WIDTH_BITS_WIDTH + KERNEL_HEIGHT_BITS_WIDTH + INPUT_CHANNEL_STEPS_BITS_WIDTH + OUTPUT_HEIGHT_BITS_WIDTH <= REGISTER_WIDTH);

    localparam integer OUTPUT_WIDTH_BITS_START = REGISTER_WIDTH-1;
    localparam integer OUTPUT_HEIGHT_BITS_START = OUTPUT_WIDTH_BITS_START - OUTPUT_WIDTH_BITS_WIDTH;
    localparam integer OUTPUT_CHANNELS_BITS_START = OUTPUT_HEIGHT_BITS_START - OUTPUT_HEIGHT_BITS_WIDTH;
    initial assert (OUTPUT_WIDTH_BITS_WIDTH + OUTPUT_HEIGHT_BITS_WIDTH + OUTPUT_CHANNELS_BITS_WIDTH <= REGISTER_WIDTH);

    logic [CONVOLUTION_FUNCTION_BITS_WIDTH-1:0] convolution_function;
    logic [START_SIGNAL_BITS_WIDTH-1:0] start_signal, start_signal_ff;
    
    logic [INPUT_WIDTH_BITS_WIDTH-1:0] l_input_width;
    logic [INPUT_HEIGHT_BITS_WIDTH-1:0] l_input_height;
    logic [INPUT_CHANNELS_BITS_WIDTH-1:0] l_input_channels;
    
    logic [OUTPUT_WIDTH_BITS_WIDTH-1:0] l_output_width;
    logic [OUTPUT_HEIGHT_BITS_WIDTH-1:0] l_output_height;
    logic [OUTPUT_CHANNELS_BITS_WIDTH-1:0] l_output_channels;
    
    logic [KERNEL_WIDTH_BITS_WIDTH-1:0] l_kernel_width;
    logic [KERNEL_HEIGHT_BITS_WIDTH-1:0] l_kernel_height;

    logic [INPUT_CHANNELS_BITS_WIDTH-1:0] l_input_channel_steps;
    logic [OUTPUT_CHANNELS_BITS_WIDTH-1:0] l_output_channel_steps;

    logic [REGISTER_WIDTH-1:0] lines_to_run_ff;
    logic l_end_signal_ff;

    typedef enum logic[2:0] {IDLE = 0, ON = 1, HOLD = 2} CONTROL_FSM_t;
    CONTROL_FSM_t CONTROL_FSM = IDLE;
    logic last_line_signal = 0;

    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0]  l_input_buffer_address_comb ;
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0]  l_weight_buffer_address_comb;
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0]  l_output_buffer_address_comb;
    logic [$clog2(BB_SRAM_DEPTH*BB_SRAM_BANK_COUNT)-1:0]  l_bias_buffer_address_comb  ; 
    // logic [1:0]            l_enable_delay_counter_ff;
    localparam int         ENABLE_SIGNAL_DELAY = 4;
	logic                  l_enable_signals_flag_ff[ENABLE_SIGNAL_DELAY];
    logic                  l_input_buffer_read_enable_comb, l_input_buffer_read_enable_ff;
    logic                  l_weight_buffer_read_enable_comb, l_weight_buffer_read_enable_ff;
    logic                  l_output_buffer_write_enable_comb;
    logic                  l_output_buffer_write_enable_ff[3];
    logic                  l_bias_buffer_read_enable_comb, l_bias_buffer_read_enable_ff;


    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_1_ff [6];
    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_2_ff [4];
    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_3_ff [2];
    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_1_comb [6];
    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_2_comb [4];
    logic [$clog2(IB_SRAM_DEPTH*IB_SRAM_BANK_COUNT)-1:0] l_input_buffer_address_pipeline_3_comb [2];

    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_1_ff [4];
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_2_ff [3];
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_3_ff [2];
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_1_comb [4];
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_2_comb [3];
    logic [$clog2(WB_SRAM_DEPTH*WB_SRAM_BANK_COUNT)-1:0] l_weight_buffer_address_pipeline_3_comb [2];
 
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_1_ff [4];
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_2_ff [2];
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_3_ff [1];
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_1_comb [4];
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_2_comb [2];
    logic [$clog2(OB_SRAM_DEPTH*OB_SRAM_BANK_COUNT)-1:0] l_output_buffer_address_pipeline_3_comb [1];


    logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];
    /*
    Register File: 
    0: convolution type - activation function - pooling function - pooling count - end signal - start signal 
    1: Input feature map shape
    2: kernel shape
    3: Output feature map shape
    */

    logic                                       l_bridge_write_enable;
    logic[control_bus.C_S_AXI_DATA_WIDTH/8-1:0] l_bridge_write_strobes; // Write strobes are byte wise
    logic[control_bus.C_S_AXI_DATA_WIDTH-1:0]   l_bridge_output_data;
    logic[control_bus.C_S_AXI_ADDR_WIDTH-$clog2(control_bus.C_S_AXI_DATA_WIDTH/8)-1:0]   l_bridge_write_address; // Addresses one word, even though AXI addresses bytes (the address is converted)
    logic[control_bus.C_S_AXI_ADDR_WIDTH-$clog2(control_bus.C_S_AXI_DATA_WIDTH/8)-1:0]   l_bridge_read_address;

    axi_register_file_fsm input_memory_bridge (
        .axi_bus(control_bus),
        .ol_write_enable(l_bridge_write_enable),
        .ol_write_strobes(l_bridge_write_strobes),
        .ol_data(l_bridge_output_data),
        .ol_write_address(l_bridge_write_address),
        .il_data('{default: 1'b0}),
        .ol_read_address(l_bridge_read_address)
    );                                                                                                    
        
    always_ff @(posedge clk)                                                                                                                 
    begin
        if(rst) begin
            for (int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
                register_file[i] <= {REGISTER_WIDTH{1'b0}};
            end                                            
            lines_to_run_ff <= 0;                                                                                                           
            start_signal_ff <= 0;
        end
        else begin
            if(l_bridge_write_enable) begin
                register_file[l_bridge_write_address] <= l_bridge_output_data;
                if (l_bridge_write_address==0 && l_bridge_output_data[START_SIGNAL_BITS_START-:START_SIGNAL_BITS_WIDTH]==1) begin
                    start_signal_ff <= 1;
                end
                if (l_bridge_write_address==4) begin
                    lines_to_run_ff <= lines_to_run_ff + 1;
                end
            end                          
            else start_signal_ff <= 0;                                                                                                                                                                                                                                                                                                                                                                                                                             
        end                                                                                                                                  
    end

    always_comb address_generator_to_buffer_control_if.activation_function = activation_t'(register_file[0][ACTIVATION_FUNCTION_BITS_START-:ACTIVATION_FUNCTION_BITS_WIDTH]);
    always_comb address_generator_to_buffer_control_if.pooling_function    = pooling_t'(register_file[0][POOLING_FUNCTION_BITS_START-:POOLING_FUNCTION_BITS_WIDTH]);
    always_comb address_generator_to_buffer_control_if.pooling_count       = register_file[0][POOLING_COUNT_BITS_START-:POOLING_COUNT_BITS_WIDTH];
    // always_comb address_generator_to_buffer_control_if.l_end_signal        = register_file[0][END_SIGNAL_BITS_START-:END_SIGNAL_BITS_WIDTH];
    always_comb address_generator_to_buffer_control_if.l_end_signal        = l_end_signal_ff;
    always_comb convolution_function                                       = register_file[0][CONVOLUTION_FUNCTION_BITS_START-:CONVOLUTION_FUNCTION_BITS_WIDTH];

    always_comb l_input_width    = register_file[1][INPUT_WIDTH_BITS_START-:INPUT_WIDTH_BITS_WIDTH];
    always_comb l_input_height   = register_file[1][INPUT_HEIGHT_BITS_START-:INPUT_HEIGHT_BITS_WIDTH];
    always_comb l_input_channels = register_file[1][INPUT_CHANNELS_BITS_START-:INPUT_CHANNELS_BITS_WIDTH];

    always_comb l_kernel_width  = register_file[2][KERNEL_WIDTH_BITS_START-:KERNEL_WIDTH_BITS_WIDTH];
    always_comb l_kernel_height = register_file[2][KERNEL_HEIGHT_BITS_START-:KERNEL_HEIGHT_BITS_WIDTH];
    
    always_comb l_input_channel_steps = register_file[2][INPUT_CHANNEL_STEPS_BITS_START-:INPUT_CHANNEL_STEPS_BITS_WIDTH];
    always_comb l_output_channel_steps = register_file[2][OUTPUT_CHANNEL_STEPS_BITS_START-:OUTPUT_CHANNEL_STEPS_BITS_WIDTH];

    always_comb l_output_width    = register_file[3][OUTPUT_WIDTH_BITS_START-:OUTPUT_WIDTH_BITS_WIDTH];
    always_comb l_output_height   = register_file[3][OUTPUT_HEIGHT_BITS_START-:OUTPUT_HEIGHT_BITS_WIDTH];
    always_comb l_output_channels = register_file[3][OUTPUT_CHANNELS_BITS_START-:OUTPUT_CHANNELS_BITS_WIDTH];

    logic [REGISTER_WIDTH-1:0] kx_ff, ky_ff, ox_ff, oy_ff, step_ff;
    logic kx_update_comb, ky_update_comb, ox_update_comb, oy_update_comb;
    logic [REGISTER_WIDTH-1:0] kx_increment_comb, ky_increment_comb, ox_increment_comb, oy_increment_comb, step_increment_comb;
    logic [REGISTER_WIDTH-1:0] input_coeff0_ff, input_coeff1_ff, input_coeff2_ff, input_coeff3_ff, input_coeff4_ff;
    logic [REGISTER_WIDTH-1:0] weight_coeff0_ff, weight_coeff1_ff, weight_coeff2_ff;
    logic [REGISTER_WIDTH-1:0] output_coeff0_0_ff, output_coeff0_1_ff, output_coeff1_ff, output_coeff2_ff;

    logic [REGISTER_WIDTH-1:0]  input_coeff0_comb, input_coeff0_0_comb, input_coeff0_1_comb, weight_coeff0_comb, output_coeff0_0_comb, output_coeff0_1_comb; // offsets. 
    logic [3:0]                 l_dilation_cycles_counter_ff;
    logic [3:0]                 l_dilation_rate_ff;
    logic [3:0]                 l_dilation_rate_comb;
    logic [3:0]                 l_stride_comb;
    logic [REGISTER_WIDTH-1:0]  l_dilation_output_group_size_ff, l_dilation_input_group_size_ff; 
    logic [REGISTER_WIDTH-1:0]  l_dilated_conv_input_address_jump_counter_ff;

    logic [REGISTER_WIDTH-1:0]  l_output_channel_steps_counter;

    logic [REGISTER_WIDTH-1:0]  l_jumps_counter_ff;


    always_comb kx_increment_comb = kx_ff + 1;
    always_comb ky_increment_comb = ky_ff + 1;
    always_comb ox_increment_comb = ox_ff + 1;
    always_comb oy_increment_comb = oy_ff + 1;
    always_comb step_increment_comb = step_ff + 1;

    always_comb kx_update_comb   = (step_ff == l_input_channel_steps-1);
    always_comb ky_update_comb   = (kx_ff == l_kernel_width-1);
    always_comb ox_update_comb   = (ky_ff == l_kernel_height-1);
    always_comb oy_update_comb   = (ox_ff == l_output_width-1);
    
    always_comb last_line_signal = (oy_ff == l_output_height-1) && (l_output_channel_steps_counter==l_output_channel_steps-1); 

    always_comb l_dilation_rate_comb = convolution_function[CONVOLUTION_DILATION_BITS_START-:CONVOLUTION_DILATION_BITS_WIDTH];
    always_comb l_stride_comb        = convolution_function[CONVOLUTION_STRIDE_BITS_START-:CONVOLUTION_STRIDE_BITS_WIDTH];

    /*
    Control FSM process & capturing the address equation coefficients
    */
    always_ff @(posedge clk) begin
        if (rst) begin
            input_coeff1_ff <= 0;
            input_coeff2_ff <= 0;
            input_coeff3_ff <= 0;
            input_coeff4_ff <= 0;

            weight_coeff1_ff <= 0;
            weight_coeff2_ff <= 0;

            output_coeff1_ff <= 0;
            output_coeff2_ff <= 0;

            l_enable_signals_flag_ff  <= '{default:0};


        end else begin  
            case (CONTROL_FSM)
                    IDLE: begin
                        if (start_signal_ff) begin 
                            input_coeff1_ff <= l_input_channel_steps*l_input_width << l_stride_comb;
                            input_coeff2_ff <= l_input_channel_steps << l_stride_comb;
                            input_coeff3_ff <= l_input_channel_steps*l_input_width;
                            // input_coeff4_ff <= l_input_channel_steps; 
                            input_coeff4_ff <= l_input_channel_steps << l_dilation_rate_comb; // this translates to input_channel_steps*dilation_rate

                            weight_coeff1_ff <= l_input_channel_steps*l_kernel_width;
                            weight_coeff2_ff <= l_input_channel_steps;

                            output_coeff1_ff <= l_output_width*l_output_channel_steps;
                            output_coeff2_ff <= l_output_channel_steps; 

                            l_enable_signals_flag_ff[0] <= 1;

                            CONTROL_FSM <= ON;
                        end
                        else begin
                            CONTROL_FSM <= IDLE;
                            l_enable_signals_flag_ff[0] <= 0;
                        end

                        l_end_signal_ff <= 0;
                    end
                    ON: begin
                        if (last_line_signal && oy_update_comb && ox_update_comb && ky_update_comb && kx_update_comb) begin 
                            CONTROL_FSM                 <= IDLE;
                            l_enable_signals_flag_ff[0] <= 0;
                            l_end_signal_ff <= 1;
                        end
                        else if (oy_update_comb && ox_update_comb && ky_update_comb && kx_update_comb) begin
                            l_end_signal_ff <= 1;
                            if (lines_to_run_ff == 1) begin
                                CONTROL_FSM                 <= HOLD;   
                                l_enable_signals_flag_ff[0] <= 0; 
                            end
                            
                            lines_to_run_ff <= lines_to_run_ff - 1;
                            
                        end    
                        else begin 
                            CONTROL_FSM <= ON;
                            l_end_signal_ff <= 0;
                        end
                    end
                    HOLD: begin
                        if (lines_to_run_ff > 0) begin
                            CONTROL_FSM                 <= ON;
                            l_enable_signals_flag_ff[0] <= 0;    
                        end
                        else begin
                            CONTROL_FSM <= HOLD;
                        end

                        l_end_signal_ff <= 0;
                    end
            endcase
        end
    end

    /*
    Update loop counters
    */
    always_ff @(posedge clk) begin
        if (rst) begin
            kx_ff   <= 0;
            ky_ff   <= 0;
            ox_ff   <= 0;
            oy_ff   <= 0;
            step_ff <= 0;

            weight_coeff0_ff <= 0; // weight buffer address offset. 

            l_output_channel_steps_counter <= 0;
            
            // l_enable_delay_counter_ff <= 0;
        end else begin
            if (CONTROL_FSM == ON) begin
                if (kx_update_comb) begin
                    step_ff      <= 0;
                end else begin 
                    step_ff      <= step_increment_comb;
                end

                if (kx_update_comb) begin 
                    if (ky_update_comb) begin
                        kx_ff        <= 0;
                    end else begin 
                        kx_ff        <= kx_increment_comb;
                    end
                end

                if (ky_update_comb && kx_update_comb) begin 
                    if (ox_update_comb) begin
                        ky_ff        <= 0;
                    end else begin 
                        ky_ff        <= ky_increment_comb;
                    end
                end
                
                if (ox_update_comb && ky_update_comb && kx_update_comb) begin 
                    if (oy_update_comb) begin
                        ox_ff        <= 0;
                    end else begin 
                        ox_ff        <= ox_increment_comb;
                    end
                end

                if (oy_update_comb && ox_update_comb && ky_update_comb && kx_update_comb) begin 
                    // update output channel steps counter and oy 
                    if (l_output_channel_steps_counter == l_output_channel_steps-1) begin
                        l_output_channel_steps_counter <= 0;
                        weight_coeff0_ff               <= 0;
                        if (last_line_signal) begin
                            oy_ff                 <= 0;
                        end else begin 
                            oy_ff                 <= oy_increment_comb;
                        end
                    end
                    else begin
                        l_output_channel_steps_counter <= l_output_channel_steps_counter + 1;
                        weight_coeff0_ff <= (l_output_channel_steps_counter+1)*l_kernel_width*l_kernel_height*l_input_channel_steps;
                    end

                end
            end
        end
    end

    /*
    Address generation pipeline
    */
    always_ff @(posedge clk) begin
        if(rst) begin
            l_input_buffer_address_pipeline_1_ff  <= '{default:0};
            l_input_buffer_address_pipeline_2_ff  <= '{default:0};
            l_input_buffer_address_pipeline_3_ff  <= '{default:0};
            l_weight_buffer_address_pipeline_1_ff <= '{default:0};
            l_weight_buffer_address_pipeline_2_ff <= '{default:0};
            l_weight_buffer_address_pipeline_3_ff <= '{default:0};
            l_output_buffer_address_pipeline_1_ff <= '{default:0};
            l_output_buffer_address_pipeline_2_ff <= '{default:0};
            l_output_buffer_address_pipeline_3_ff <= '{default:0};             

            l_output_buffer_write_enable_ff <= '{default:0};     

            address_generator_to_buffer_control_if.l_input_buffer_address  <= '{default:0};
            address_generator_to_buffer_control_if.l_weight_buffer_address <= '{default:0};
            address_generator_to_buffer_control_if.l_output_buffer_address <= '{default:0};

            address_generator_to_buffer_control_if.l_input_buffer_read_enable   <= 0;
            address_generator_to_buffer_control_if.l_weight_buffer_read_enable  <= 0;
            address_generator_to_buffer_control_if.l_output_buffer_write_enable <= 0;
        end
        else begin
            l_input_buffer_address_pipeline_1_ff <= l_input_buffer_address_pipeline_1_comb;
            l_input_buffer_address_pipeline_2_ff <= l_input_buffer_address_pipeline_2_comb;
            l_input_buffer_address_pipeline_3_ff <= l_input_buffer_address_pipeline_3_comb;

            l_weight_buffer_address_pipeline_1_ff <= l_weight_buffer_address_pipeline_1_comb;
            l_weight_buffer_address_pipeline_2_ff <= l_weight_buffer_address_pipeline_2_comb;
            l_weight_buffer_address_pipeline_3_ff <= l_weight_buffer_address_pipeline_3_comb;

            l_output_buffer_address_pipeline_1_ff <= l_output_buffer_address_pipeline_1_comb;
            l_output_buffer_address_pipeline_2_ff <= l_output_buffer_address_pipeline_2_comb;
            l_output_buffer_address_pipeline_3_ff <= l_output_buffer_address_pipeline_3_comb;     

            address_generator_to_buffer_control_if.l_input_buffer_address  <= l_input_buffer_address_comb;
            address_generator_to_buffer_control_if.l_weight_buffer_address <= l_weight_buffer_address_comb;
            address_generator_to_buffer_control_if.l_output_buffer_address <= l_output_buffer_address_comb;

            l_output_buffer_write_enable_ff[0] <= l_output_buffer_write_enable_comb;
            l_output_buffer_write_enable_ff[1] <= l_output_buffer_write_enable_ff[0];
            l_output_buffer_write_enable_ff[2] <= l_output_buffer_write_enable_ff[1];

            address_generator_to_buffer_control_if.l_input_buffer_read_enable   <= l_input_buffer_read_enable_comb;
            address_generator_to_buffer_control_if.l_weight_buffer_read_enable  <= l_weight_buffer_read_enable_comb;
            address_generator_to_buffer_control_if.l_output_buffer_write_enable <= l_output_buffer_write_enable_ff[2];


            address_generator_to_buffer_control_if.l_bias_buffer_address     <= 0;
            address_generator_to_buffer_control_if.l_bias_buffer_read_enable <= 0;

            for (int i = 0; i < ENABLE_SIGNAL_DELAY-1; i++) begin
                l_enable_signals_flag_ff[i+1] <= l_enable_signals_flag_ff[i]; 
            end
        end
    end

    /*
    Address generation coefficients process 
    */
    always_ff @(posedge clk) begin
        if(rst) begin
            l_dilation_cycles_counter_ff <= 0;
            
            input_coeff0_ff    <= 0; // Input buffer address offset.  
            output_coeff0_0_ff <= 0; // Output buffer address offset. 
            output_coeff0_1_ff <= 0; // Output buffer address offset. 
        end
        else begin
            
            // Output address offset
            if (ox_update_comb && ky_update_comb && kx_update_comb && oy_update_comb) begin
                output_coeff0_0_ff <= 0;
                output_coeff0_1_ff <= 0;
            end
            else begin
                output_coeff0_0_ff <= output_coeff0_0_comb;
                output_coeff0_1_ff <= output_coeff0_1_comb; 
            end
            
            // Input address offset
            if (ox_update_comb && ky_update_comb && kx_update_comb) begin 
                if (oy_update_comb) begin
                    input_coeff0_ff  <= 0;
                end
                else begin
                    input_coeff0_ff <= input_coeff0_comb;
                end
            end

        end
    end
    
    // input address offset coefficient0
    always_comb begin
        input_coeff0_0_comb = 0;
        
        input_coeff0_comb = input_coeff0_0_comb;
    end

    // output address offset coefficient0
    always_comb begin 
        output_coeff0_0_comb = l_output_channel_steps_counter;
        output_coeff0_1_comb = 0;
    end
     

    always_comb l_input_buffer_address_pipeline_1_comb[0] = step_ff;
    always_comb l_input_buffer_address_pipeline_1_comb[1] = (unsigned'(input_coeff4_ff) * unsigned'(kx_ff));
    always_comb l_input_buffer_address_pipeline_1_comb[2] = (unsigned'(input_coeff3_ff) * unsigned'(ky_ff));
    always_comb l_input_buffer_address_pipeline_1_comb[3] = (unsigned'(input_coeff2_ff) * unsigned'(ox_ff));
    always_comb l_input_buffer_address_pipeline_1_comb[4] = (unsigned'(input_coeff1_ff) * unsigned'(oy_ff));
    always_comb l_input_buffer_address_pipeline_1_comb[5] = input_coeff0_ff;

    always_comb l_input_buffer_address_pipeline_2_comb[0] = l_input_buffer_address_pipeline_1_ff[0];
    always_comb l_input_buffer_address_pipeline_2_comb[1] = l_input_buffer_address_pipeline_1_ff[1] + l_input_buffer_address_pipeline_1_ff[2];
    always_comb l_input_buffer_address_pipeline_2_comb[2] = l_input_buffer_address_pipeline_1_ff[3];
    always_comb l_input_buffer_address_pipeline_2_comb[3] = l_input_buffer_address_pipeline_1_ff[4] + l_input_buffer_address_pipeline_1_ff[5];

    always_comb l_input_buffer_address_pipeline_3_comb[0] = l_input_buffer_address_pipeline_2_ff[0] + l_input_buffer_address_pipeline_2_ff[1];
    always_comb l_input_buffer_address_pipeline_3_comb[1] = l_input_buffer_address_pipeline_2_ff[2] + l_input_buffer_address_pipeline_2_ff[3];

    always_comb l_input_buffer_address_comb = l_input_buffer_address_pipeline_3_ff[0] + l_input_buffer_address_pipeline_3_ff[1];

    //
    always_comb l_weight_buffer_address_pipeline_1_comb[0] = step_ff;
    always_comb l_weight_buffer_address_pipeline_1_comb[1] = (unsigned'(weight_coeff2_ff) * unsigned'(kx_ff));
    always_comb l_weight_buffer_address_pipeline_1_comb[2] = (unsigned'(weight_coeff1_ff) * unsigned'(ky_ff));
    always_comb l_weight_buffer_address_pipeline_1_comb[3] = weight_coeff0_ff;

    always_comb l_weight_buffer_address_pipeline_2_comb[0] = l_weight_buffer_address_pipeline_1_ff[0];
    always_comb l_weight_buffer_address_pipeline_2_comb[1] = l_weight_buffer_address_pipeline_1_ff[1] + l_weight_buffer_address_pipeline_1_ff[2];
    always_comb l_weight_buffer_address_pipeline_2_comb[2] = l_weight_buffer_address_pipeline_1_ff[3];

    always_comb l_weight_buffer_address_pipeline_3_comb[0] = l_weight_buffer_address_pipeline_2_ff[0] + l_weight_buffer_address_pipeline_2_ff[1];
    always_comb l_weight_buffer_address_pipeline_3_comb[1] = l_weight_buffer_address_pipeline_2_ff[2];

    always_comb l_weight_buffer_address_comb = l_weight_buffer_address_pipeline_3_ff[0] + l_weight_buffer_address_pipeline_3_ff[1];

    //
    always_comb l_output_buffer_address_pipeline_1_comb[0] = (unsigned'(output_coeff2_ff) * unsigned'(ox_ff)); 
    always_comb l_output_buffer_address_pipeline_1_comb[1] = (unsigned'(output_coeff1_ff) * unsigned'(oy_ff));
    always_comb l_output_buffer_address_pipeline_1_comb[2] = output_coeff0_0_ff;
    always_comb l_output_buffer_address_pipeline_1_comb[3] = output_coeff0_1_ff;

    always_comb l_output_buffer_address_pipeline_2_comb[0] = l_output_buffer_address_pipeline_1_ff[0] + l_output_buffer_address_pipeline_1_ff[3];
    always_comb l_output_buffer_address_pipeline_2_comb[1] = l_output_buffer_address_pipeline_1_ff[1] + l_output_buffer_address_pipeline_1_ff[2];

    always_comb l_output_buffer_address_pipeline_3_comb[0] = l_output_buffer_address_pipeline_2_ff[0] + l_output_buffer_address_pipeline_2_ff[1];

    always_comb l_output_buffer_address_comb = l_output_buffer_address_pipeline_3_ff[0];

    always_comb l_input_buffer_read_enable_comb   = l_enable_signals_flag_ff[ENABLE_SIGNAL_DELAY-1]? 1 : 0;
    always_comb l_weight_buffer_read_enable_comb  = l_enable_signals_flag_ff[ENABLE_SIGNAL_DELAY-1]? 1 : 0;
    always_comb l_output_buffer_write_enable_comb = (ox_update_comb && ky_update_comb && kx_update_comb)? 1 : 0;



/*
TODO:: 
Features: 
. testbench classes
. padding *** (use HLS)
. bias  
. add element wise add
. save all feature maps on-chip (dilated conv line pointers)
. meet with shih-chii:
    . student (folding CNNs - FSFnet Folding)
    . student (edge segmentation + edge detection)


Optimizations:
. simplify if conditions and share their registers
*/



endmodule