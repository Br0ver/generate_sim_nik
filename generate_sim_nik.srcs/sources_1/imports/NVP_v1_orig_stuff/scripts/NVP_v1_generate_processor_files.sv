/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP_v1_top testbench
*   Date:  21.12.2021
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

import test_package::*;
import NVP_v1_constants::*;
// import ::*;

module NVP_v1_generate_processor_files();

    localparam CLOCK_PERIOD = 3;
    
    // Control AXI Buffer Interface
    logic  CONTROL_AXI_ACLK;
    logic  CONTROL_AXI_ARESETN;
    logic [CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_AWADDR;
    logic  CONTROL_AXI_AWVALID;
    logic  CONTROL_AXI_AWREADY;
    logic [CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_WDATA;
    logic [(CONTROL_AXI_DATA_WIDTH/8)-1 : 0] CONTROL_AXI_WSTRB;
    logic  CONTROL_AXI_WVALID;
    logic  CONTROL_AXI_WREADY;
    logic [1 : 0] CONTROL_AXI_BRESP;
    logic  CONTROL_AXI_BVALID;
    logic  CONTROL_AXI_BREADY;
    logic [CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_ARADDR;
    logic  CONTROL_AXI_ARVALID;
    logic  CONTROL_AXI_ARREADY;
    logic [CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_RDATA;
    logic [1 : 0] CONTROL_AXI_RRESP;
    logic  CONTROL_AXI_RVALID;
    logic  CONTROL_AXI_RREADY;

    // data bus interface signals
    localparam S_AXI_ID_WIDTH           = 1;
    logic  S_AXI_ACLK;
    logic  S_AXI_ARESETN;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID = '{default:0};
    logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_AWADDR = '{default:0};
    logic [7 : 0] S_AXI_AWLEN = '{default:0};
    logic [2 : 0] S_AXI_AWSIZE = '{default:0};
    logic [1 : 0] S_AXI_AWBURST = '{default:0};
    logic  S_AXI_AWLOCK = '{default:0};
    logic  S_AXI_AWVALID = '{default:0};
    logic  S_AXI_AWREADY;
    logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_WDATA = '{default:0};
    logic [(AXI_BUS_BIT_WIDTH/8)-1 : 0] S_AXI_WSTRB = '{default:0};
    logic  S_AXI_WLAST = '{default:0};
    logic  S_AXI_WVALID = '{default:0};
    logic  S_AXI_WREADY;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_BID;
    logic [1 : 0] S_AXI_BRESP;
    logic  S_AXI_BVALID;
    logic  S_AXI_BREADY = '{default:0};
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID = '{default:0};
    logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_ARADDR = '{default:0};
    logic [7 : 0] S_AXI_ARLEN = '{default:0};
    logic [2 : 0] S_AXI_ARSIZE = '{default:0};
    logic [1 : 0] S_AXI_ARBURST = '{default:0};
    logic  S_AXI_ARLOCK = '{default:0};
    logic  S_AXI_ARVALID = '{default:0};
    logic  S_AXI_ARREADY;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_RID;
    logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_RDATA;
    logic [1 : 0] S_AXI_RRESP;
    logic  S_AXI_RLAST;
    logic  S_AXI_RVALID;
    logic  S_AXI_RREADY = '{default:0};


    // weight bus interface signals
    localparam WEIGHT_AXI_ID_WIDTH           = 1;
    logic  WEIGHT_AXI_ACLK;
    logic  WEIGHT_AXI_ARESETN;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_AWID = '{default:0};
    logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_AWADDR = '{default:0};
    logic [7 : 0] WEIGHT_AXI_AWLEN = '{default:0};
    logic [2 : 0] WEIGHT_AXI_AWSIZE = '{default:0};
    logic [1 : 0] WEIGHT_AXI_AWBURST = '{default:0};
    logic  WEIGHT_AXI_AWLOCK = '{default:0};
    logic  WEIGHT_AXI_AWVALID = '{default:0};
    logic  WEIGHT_AXI_AWREADY;
    logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_WDATA = '{default:0};
    logic [(WEIGHT_AXI_BUS_BIT_WIDTH/8)-1 : 0] WEIGHT_AXI_WSTRB = '{default:0};
    logic  WEIGHT_AXI_WLAST = '{default:0};
    logic  WEIGHT_AXI_WVALID = '{default:0};
    logic  WEIGHT_AXI_WREADY;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_BID;
    logic [1 : 0] WEIGHT_AXI_BRESP;
    logic  WEIGHT_AXI_BVALID;
    logic  WEIGHT_AXI_BREADY = '{default:0};
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_ARID = '{default:0};
    logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_ARADDR = '{default:0};
    logic [7 : 0] WEIGHT_AXI_ARLEN = '{default:0};
    logic [2 : 0] WEIGHT_AXI_ARSIZE = '{default:0};
    logic [1 : 0] WEIGHT_AXI_ARBURST = '{default:0};
    logic  WEIGHT_AXI_ARLOCK = '{default:0};
    logic  WEIGHT_AXI_ARVALID = '{default:0};
    logic  WEIGHT_AXI_ARREADY;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_RID;
    logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_RDATA;
    logic [1 : 0] WEIGHT_AXI_RRESP;
    logic  WEIGHT_AXI_RLAST;
    logic  WEIGHT_AXI_RVALID;
    logic  WEIGHT_AXI_RREADY = '{default:0};

    localparam KERNEL_ROWS          = 3;

    localparam strided_string = "/home/hasan/NVP_v1/tb/strided_%0d_pes_%0d_rows_%0d_cols_%0d_ch_%0d_k_8_bits_%0d_axi/";
    localparam conv_string = "/home/hasan/NVP_v1/tb/conv_%0d_pes_%0d_rows_%0d_cols_%0d_ch_%0d_k_8_bits_%0d_axi/";

    // set parameters
    localparam STRIDED_CONV         = 0; // # 1-> strided conv on. 0-> strided conv off.
    localparam ACTIVATION_ROWS      = 3 + STRIDED_CONV;
    localparam ACTIVATION_COLS      = 32;
    localparam ACTIVATION_CHANNELS  = 32;
    localparam NUMBER_OF_KERNELS    = 32;
    localparam string_to_use = (STRIDED_CONV==1)? strided_string : conv_string;
    localparam TXT_FILES_DIRECTORY  = $sformatf(string_to_use,NUMBER_OF_PES_PER_ARRAY, ACTIVATION_ROWS, ACTIVATION_COLS, ACTIVATION_CHANNELS, NUMBER_OF_KERNELS, AXI_BIT_WIDTH);


    localparam KERNEL_CHANNELS                      = ACTIVATION_CHANNELS;
    localparam KERNEL_STEPS                         = ((NUMBER_OF_KERNELS/NUMBER_OF_PES_PER_ARRAY) == 0)? 1 : NUMBER_OF_KERNELS/NUMBER_OF_PES_PER_ARRAY;
    localparam CHANNEL_STEPS                        = ((ACTIVATION_CHANNELS/NUMBER_OF_PES_PER_ARRAY) == 0)? 1 : ACTIVATION_CHANNELS/NUMBER_OF_PES_PER_ARRAY;
    localparam OUTPUT_SLICES                        = (NUMBER_OF_KERNELS<NUMBER_OF_PES_PER_ARRAY)? NUMBER_OF_KERNELS/8 : NUMBER_OF_PES_PER_ARRAY/8;
    localparam SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS   = (ACTIVATION_COLS*KERNEL_STEPS)/(STRIDED_CONV+1) + STRIDED_CONV;
    localparam OUTPUT_ACTIVATION_ROWS               = ACTIVATION_ROWS/(STRIDED_CONV+1);
    localparam OUTPUT_ACTIVATION_COLS               = ACTIVATION_COLS/(STRIDED_CONV+1);

    localparam MAX_KERNELS_AND_PES    = (NUMBER_OF_KERNELS>NUMBER_OF_PES_PER_ARRAY)? NUMBER_OF_KERNELS : NUMBER_OF_PES_PER_ARRAY;
    localparam NUMBER_OF_WEIGHT_ENTRIES_PER_WEIGHT_ARRAY = 1*KERNEL_ROWS*KERNEL_CHANNELS*MAX_KERNELS_AND_PES*WEIGHT_BIT_WIDTH/WEIGHT_AXI_BUS_BIT_WIDTH; 


    localparam AXI_BYTE_ACCESS_BITS =  $clog2(AXI_BUS_BIT_WIDTH/8);
    localparam OUTPUT_LINE_1_START_ADDRESS = (ACTIVATION_LINE_BUFFER_3_START_ADDRESS >> AXI_BYTE_ACCESS_BITS);
    localparam OUTPUT_LINE_2_START_ADDRESS = (ACTIVATION_LINE_BUFFER_4_START_ADDRESS >> AXI_BYTE_ACCESS_BITS);

    layer_i #(
        .WEIGHT_BIT_WIDTH                   (WEIGHT_BIT_WIDTH),
        .WEIGHT_AXI_BUS_DATA_BIT_WIDTH      (WEIGHT_AXI_BUS_BIT_WIDTH),
        .WEIGHT_AXI_BUS_ADDRESS_WIDTH       (WEIGHT_AXI_BUS_ADDRESS_WIDTH),
        .NUMBER_OF_WEIGHT_ARRAY_ENTRIES     (NUMBER_OF_WEIGHT_ENTRIES_PER_WEIGHT_ARRAY),

        .ACTIVATION_BIT_WIDTH               (ACTIVATION_BIT_WIDTH),
        .AXI_BUS_DATA_BIT_WIDTH             (AXI_BUS_BIT_WIDTH),
        .AXI_BUS_ADDRESS_WIDTH              (AXI_BUS_ADDRESS_WIDTH),
        
        .C_CONTROL_AXI_DATA_WIDTH           (CONTROL_AXI_DATA_WIDTH),
        .C_CONTROL_AXI_ADDR_WIDTH           (CONTROL_AXI_ADDR_WIDTH),

        .ARRAYS_SIZE                        (2048), // should be enough to hold all activation axi words.

        .NUMBER_OF_COLS                     (ACTIVATION_COLS),
        .NUMBER_OF_CH                       (ACTIVATION_CHANNELS),
        .NUMBER_OF_ROWS                     (ACTIVATION_ROWS),
        .KERNEL_K                           (KERNEL_ROWS),
        .NUMBER_OF_OUTPUT_COLS              (OUTPUT_ACTIVATION_COLS),
        .NUMBER_OF_OUTPUT_CH                (NUMBER_OF_KERNELS),
        .NUMBER_OF_OUTPUT_ROWS              (OUTPUT_ACTIVATION_ROWS),

        .TXT_FILES_DIRECTORY                (TXT_FILES_DIRECTORY)
    ) layer_one;

    logic clk = 0;
    logic resetn = 1;
    logic next_command_interrupt;
    logic output_line_stored;
    logic [REGISTER_WIDTH-1:0] output_line_1_end_address, output_line_2_end_address;
    // logic[AXI_DATA_WIDTH-1:0] output_line_end_address
    int address_offset;
    int unsigned output_line_1_length, output_line_2_length;
    always_comb output_line_1_length = output_line_1_end_address-OUTPUT_LINE_1_START_ADDRESS; // ??
    always_comb output_line_2_length = output_line_2_end_address-OUTPUT_LINE_2_START_ADDRESS;

    string export_file_name = "test_neural_net";

    logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];

    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(WEIGHT_AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH)
    ) weight_bus ();
    assign weight_bus.S_AXI_ACLK      = WEIGHT_AXI_ACLK;
    assign weight_bus.S_AXI_ARESETN   = WEIGHT_AXI_ARESETN;
    assign weight_bus.S_AXI_AWID      = WEIGHT_AXI_AWID;
    assign weight_bus.S_AXI_AWADDR    = WEIGHT_AXI_AWADDR;
    assign weight_bus.S_AXI_AWLEN     = WEIGHT_AXI_AWLEN;
    assign weight_bus.S_AXI_AWSIZE    = WEIGHT_AXI_AWSIZE;
    assign weight_bus.S_AXI_AWBURST   = WEIGHT_AXI_AWBURST;
    assign weight_bus.S_AXI_AWLOCK    = WEIGHT_AXI_AWLOCK;
    assign weight_bus.S_AXI_AWVALID   = WEIGHT_AXI_AWVALID;
    assign weight_bus.S_AXI_WDATA     = WEIGHT_AXI_WDATA;
    assign weight_bus.S_AXI_WSTRB     = WEIGHT_AXI_WSTRB;
    assign weight_bus.S_AXI_WLAST     = WEIGHT_AXI_WLAST;
    assign weight_bus.S_AXI_WVALID    = WEIGHT_AXI_WVALID;
    assign weight_bus.S_AXI_BREADY    = WEIGHT_AXI_BREADY;
    assign weight_bus.S_AXI_ARID      = WEIGHT_AXI_ARID;
    assign weight_bus.S_AXI_ARADDR    = WEIGHT_AXI_ARADDR;
    assign weight_bus.S_AXI_ARLEN     = WEIGHT_AXI_ARLEN;
    assign weight_bus.S_AXI_ARSIZE    = WEIGHT_AXI_ARSIZE;
    assign weight_bus.S_AXI_ARBURST   = WEIGHT_AXI_ARBURST;
    assign weight_bus.S_AXI_ARLOCK    = WEIGHT_AXI_ARLOCK;
    assign weight_bus.S_AXI_ARVALID   = WEIGHT_AXI_ARVALID;
    assign weight_bus.S_AXI_RREADY    = WEIGHT_AXI_RREADY;
    assign WEIGHT_AXI_AWREADY         = weight_bus.S_AXI_AWREADY;
    assign WEIGHT_AXI_WREADY          = weight_bus.S_AXI_WREADY;
    assign WEIGHT_AXI_BID             = weight_bus.S_AXI_BID;
    assign WEIGHT_AXI_BRESP           = weight_bus.S_AXI_BRESP;
    assign WEIGHT_AXI_BVALID          = weight_bus.S_AXI_BVALID;
    assign WEIGHT_AXI_ARREADY         = weight_bus.S_AXI_ARREADY;
    assign WEIGHT_AXI_RID             = weight_bus.S_AXI_RID;
    assign WEIGHT_AXI_RDATA           = weight_bus.S_AXI_RDATA;
    assign WEIGHT_AXI_RRESP           = weight_bus.S_AXI_RRESP;
    assign WEIGHT_AXI_RLAST           = weight_bus.S_AXI_RLAST;
    assign WEIGHT_AXI_RVALID          = weight_bus.S_AXI_RVALID;

    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(AXI_BUS_ADDRESS_WIDTH)
    ) data_bus ();
    assign data_bus.S_AXI_ACLK      = S_AXI_ACLK;
    assign data_bus.S_AXI_ARESETN   = S_AXI_ARESETN;
    assign data_bus.S_AXI_AWID      = S_AXI_AWID;
    assign data_bus.S_AXI_AWADDR    = S_AXI_AWADDR;
    assign data_bus.S_AXI_AWLEN     = S_AXI_AWLEN;
    assign data_bus.S_AXI_AWSIZE    = S_AXI_AWSIZE;
    assign data_bus.S_AXI_AWBURST   = S_AXI_AWBURST;
    assign data_bus.S_AXI_AWLOCK    = S_AXI_AWLOCK;
    assign data_bus.S_AXI_AWVALID   = S_AXI_AWVALID;
    assign data_bus.S_AXI_WDATA     = S_AXI_WDATA;
    assign data_bus.S_AXI_WSTRB     = S_AXI_WSTRB;
    assign data_bus.S_AXI_WLAST     = S_AXI_WLAST;
    assign data_bus.S_AXI_WVALID    = S_AXI_WVALID;
    assign data_bus.S_AXI_BREADY    = S_AXI_BREADY;
    assign data_bus.S_AXI_ARID      = S_AXI_ARID;
    assign data_bus.S_AXI_ARADDR    = S_AXI_ARADDR;
    assign data_bus.S_AXI_ARLEN     = S_AXI_ARLEN;
    assign data_bus.S_AXI_ARSIZE    = S_AXI_ARSIZE;
    assign data_bus.S_AXI_ARBURST   = S_AXI_ARBURST;
    assign data_bus.S_AXI_ARLOCK    = S_AXI_ARLOCK;
    assign data_bus.S_AXI_ARVALID   = S_AXI_ARVALID;
    assign data_bus.S_AXI_RREADY    = S_AXI_RREADY;
    assign S_AXI_AWREADY            = data_bus.S_AXI_AWREADY;
    assign S_AXI_WREADY             = data_bus.S_AXI_WREADY;
    assign S_AXI_BID                = data_bus.S_AXI_BID;
    assign S_AXI_BRESP              = data_bus.S_AXI_BRESP;
    assign S_AXI_BVALID             = data_bus.S_AXI_BVALID;
    assign S_AXI_ARREADY            = data_bus.S_AXI_ARREADY;
    assign S_AXI_RID                = data_bus.S_AXI_RID;
    assign S_AXI_RDATA              = data_bus.S_AXI_RDATA;
    assign S_AXI_RRESP              = data_bus.S_AXI_RRESP;
    assign S_AXI_RLAST              = data_bus.S_AXI_RLAST;
    assign S_AXI_RVALID             = data_bus.S_AXI_RVALID;

    s_axi_lite_bus #(
        .C_S_AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(CONTROL_AXI_ADDR_WIDTH)
    ) control_bus ();
    assign control_bus.S_AXI_ACLK       = CONTROL_AXI_ACLK;
    assign control_bus.S_AXI_ARESETN    = CONTROL_AXI_ARESETN;
    assign control_bus.S_AXI_AWADDR     = CONTROL_AXI_AWADDR;
    assign control_bus.S_AXI_AWVALID    = CONTROL_AXI_AWVALID;
    assign control_bus.S_AXI_WDATA      = CONTROL_AXI_WDATA;
    assign control_bus.S_AXI_WSTRB      = CONTROL_AXI_WSTRB;
    assign control_bus.S_AXI_WVALID     = CONTROL_AXI_WVALID;
    assign control_bus.S_AXI_BREADY     = CONTROL_AXI_BREADY;
    assign control_bus.S_AXI_ARADDR     = CONTROL_AXI_ARADDR;
    assign control_bus.S_AXI_ARVALID    = CONTROL_AXI_ARVALID;
    assign control_bus.S_AXI_RREADY     = CONTROL_AXI_RREADY;  
    assign CONTROL_AXI_AWREADY          = control_bus.S_AXI_AWREADY;
    assign CONTROL_AXI_WREADY           = control_bus.S_AXI_WREADY;
    assign CONTROL_AXI_BRESP            = control_bus.S_AXI_BRESP;
    assign CONTROL_AXI_BVALID           = control_bus.S_AXI_BVALID;
    assign CONTROL_AXI_ARREADY          = control_bus.S_AXI_ARREADY;
    assign CONTROL_AXI_RDATA            = control_bus.S_AXI_RDATA;
    assign CONTROL_AXI_RRESP            = control_bus.S_AXI_RRESP;
    assign CONTROL_AXI_RVALID           = control_bus.S_AXI_RVALID;

    assign WEIGHT_AXI_ACLK      = clk;  
    assign WEIGHT_AXI_ARESETN   = resetn;
    assign S_AXI_ACLK           = clk;  
    assign S_AXI_ARESETN        = resetn;
    assign CONTROL_AXI_ACLK     = clk;  
    assign CONTROL_AXI_ARESETN  = resetn;

    NVP_v1_top dut ( 
        .clk                        (clk),
        .resetn                     (resetn),
        .i_data_bus                 (data_bus),
        .i_weight_bus               (weight_bus),
        .i_control_bus              (control_bus),
        .o_next_command_interrupt   (next_command_interrupt),
        .o_output_line_stored       (output_line_stored)
    );

    always begin
        #(CLOCK_PERIOD/2) clk = ~clk;
    end

    initial begin
        #CLOCK_PERIOD;
        $display("started simulation.");
        resetn    = 0;
        layer_one = new();
        layer_one.create();

        #CLOCK_PERIOD;
        layer_one.read_input();
        layer_one.read_weights(); 
        layer_one.read_ground_truth_outputs();

        #CLOCK_PERIOD;
        resetn = 1;
        for(int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
            register_file[i] = 32'h0000_0000;
        end

        #CLOCK_PERIOD;
        layer_one.create_export_file(export_file_name);

        #CLOCK_PERIOD;
        register_file[NUMBER_OF_CONV_LAYER_COLS_REGISTER][NUMBER_OF_CONV_LAYER_COLS_MSB:NUMBER_OF_CONV_LAYER_COLS_LSB]                      = ACTIVATION_COLS;
        register_file[EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER][EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB:EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB] = SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS;
        register_file[NUMBER_OF_CHANNELS_REGISTER][NUMBER_OF_CHANNELS_MSB:NUMBER_OF_CHANNELS_LSB]                                           = ACTIVATION_CHANNELS;  
        register_file[CHANNELS_MINUS_8_REGISTER][CHANNELS_MINUS_8_MSB:CHANNELS_MINUS_8_LSB]                                                 = ACTIVATION_CHANNELS-8;  
        register_file[KERNEL_STEPS_MINUS_1_REGISTER][KERNEL_STEPS_MINUS_1_MSB:KERNEL_STEPS_MINUS_1_LSB]                                     = KERNEL_STEPS-1;
        register_file[NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER][NUMBER_OF_OUTPUT_SLICING_STEPS_MSB:NUMBER_OF_OUTPUT_SLICING_STEPS_LSB]       = OUTPUT_SLICES; // TODO: calculate me properly
        register_file[CHANNEL_STEPS_REGISTER][CHANNEL_STEPS_MSB:CHANNEL_STEPS_LSB]                                                          = CHANNEL_STEPS;  
        register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX]                                                                     = 1;
        register_file[CONTROL_FLAGS_REGISTER][STRIDED_CONV_BIT_INDEX]                                                                       = STRIDED_CONV;
        register_file[CONTROL_FLAGS_REGISTER][PW_CONV_BIT_INDEX]                                                                            = 0;
        register_file[CONTROL_FLAGS_REGISTER][ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX]                                                         = 0;
        register_file[CONTROL_FLAGS_REGISTER][ELEMENT_WISE_ADD_BIT_INDEX]                                                                   = 0;
        register_file[CONTROL_FLAGS_REGISTER][STREAM_MODE_BIT_INDEX]                                                                        = SPARSE_MODE;

        #CLOCK_PERIOD;
        // output row 1
        register_file[CONTROL_FLAGS_REGISTER][STREAM_1_ENABLE_INDEX]                                                                        = 1;
        register_file[STREAM_1_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_1_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 1; // relative row 1 
        register_file[STREAM_1_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[CONTROL_FLAGS_REGISTER][STREAM_2_ENABLE_INDEX]                                                                        = 1;
        register_file[STREAM_2_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_2_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 2; // relative row 2
        register_file[STREAM_2_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[CONTROL_FLAGS_REGISTER][STREAM_3_ENABLE_INDEX]                                                                        = 0;
        register_file[STREAM_3_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_3_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 0; 
        register_file[STREAM_3_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[STREAM_WRITER_REGISTER][STREAM_WRITER_ADDRESS_MSB:STREAM_WRITER_ADDRESS_LSB]                                          = OUTPUT_LINE_1_START_ADDRESS; 

        #CLOCK_PERIOD;
        layer_one.export_register_file(export_file_name, 0, register_file);

        #CLOCK_PERIOD;
        // output row 2
        register_file[CONTROL_FLAGS_REGISTER][STREAM_1_ENABLE_INDEX]                                                                        = 1;
        register_file[STREAM_1_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_1_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 0; // relative row 
        register_file[STREAM_1_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[CONTROL_FLAGS_REGISTER][STREAM_2_ENABLE_INDEX]                                                                        = 1;
        register_file[STREAM_2_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_2_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 1; // relative row 
        register_file[STREAM_2_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[CONTROL_FLAGS_REGISTER][STREAM_3_ENABLE_INDEX]                                                                        = 1;
        register_file[STREAM_3_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_3_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = 2; // relative row
        register_file[STREAM_3_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = 0; 
        register_file[STREAM_WRITER_REGISTER][STREAM_WRITER_ADDRESS_MSB:STREAM_WRITER_ADDRESS_LSB]                                          = OUTPUT_LINE_2_START_ADDRESS; 

        #CLOCK_PERIOD;
        layer_one.export_register_file(export_file_name, 1, register_file);

        #CLOCK_PERIOD;
        layer_one.export_activations_and_weights(export_file_name);
        layer_one.close_export_file(export_file_name);

        $display("finished export.");
        // $stop;
        
    end

 
endmodule
