/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP_v1_top wrapper
*   Date:  15.02.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

import NVP_v1_constants::*;

module NVP_v1_top_wrapper_systemverilog #(
    localparam C_CONTROL_AXI_DATA_WIDTH  = NVP_v1_constants::CONTROL_AXI_DATA_WIDTH,
    localparam C_CONTROL_AXI_ADDR_WIDTH	 = NVP_v1_constants::CONTROL_AXI_ADDR_WIDTH,
    localparam S_AXI_ID_WIDTH           = 1,
    localparam AXI_BUS_BIT_WIDTH        = NVP_v1_constants::AXI_BUS_BIT_WIDTH,
    localparam AXI_BUS_ADDRESS_WIDTH    = NVP_v1_constants::AXI_BUS_ADDRESS_WIDTH,
    localparam WEIGHT_AXI_ID_WIDTH           = 1,
    localparam WEIGHT_AXI_BUS_BIT_WIDTH        = NVP_v1_constants::WEIGHT_AXI_BUS_BIT_WIDTH,
    localparam WEIGHT_AXI_BUS_ADDRESS_WIDTH    = NVP_v1_constants::WEIGHT_AXI_BUS_ADDRESS_WIDTH,
    localparam NUMBER_OF_READ_STREAMS    = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    localparam ACTIVATION_BIT_WIDTH    = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    localparam COLUMN_VALUE_BIT_WIDTH    = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    localparam CHANNEL_VALUE_BIT_WIDTH    = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    localparam ROW_VALUE_BIT_WIDTH    = NVP_v1_constants::ROW_VALUE_BIT_WIDTH

    // localparam AXIS_BUS_ID_BIT_WIDTH    = NVP_v1_constants::AXIS_BUS_ID_BIT_WIDTH,
    // localparam AXIS_BUS_DATA_BIT_WIDTH  = NVP_v1_constants::AXIS_BUS_BIT_WIDTH
)(
    input logic             clk,
    input logic             resetn,
    output logic            o_next_command_interrupt,
    output logic            o_output_line_stored,
    output logic [NUMBER_OF_READ_STREAMS-1:0]  debug_last_column    ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_0_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_0_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_0_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_0_relative_row   ,
    output logic                               debug_0_valid          ,
    output logic                               debug_0_ready          ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_1_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_1_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_1_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_1_relative_row   ,
    output logic                               debug_1_valid          ,
    output logic                               debug_1_ready          ,
    output logic [ACTIVATION_BIT_WIDTH-1:0]    debug_2_data           ,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_2_toggled_column ,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_2_channel        ,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]     debug_2_relative_row   ,
    output logic                               debug_2_valid          ,
    output logic                               debug_2_ready          ,
    output logic unsigned [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]    debug_quantized_activations, 
    output logic                                        debug_quantized_activations_valid,

    // Control bus
    input logic  CONTROL_AXI_ACLK,
    input logic  CONTROL_AXI_ARESETN,
    input logic [C_CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_AWADDR,
    input logic  CONTROL_AXI_AWVALID,
    output logic  CONTROL_AXI_AWREADY,
    input logic [C_CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_WDATA,
    input logic [(C_CONTROL_AXI_DATA_WIDTH/8)-1 : 0] CONTROL_AXI_WSTRB,
    input logic  CONTROL_AXI_WVALID,
    output logic  CONTROL_AXI_WREADY,
    output logic [1 : 0] CONTROL_AXI_BRESP,
    output logic  CONTROL_AXI_BVALID,
    input logic  CONTROL_AXI_BREADY,
    input logic [C_CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_ARADDR,
    input logic  CONTROL_AXI_ARVALID,
    output logic  CONTROL_AXI_ARREADY,
    output logic [C_CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_RDATA,
    output logic [1 : 0] CONTROL_AXI_RRESP,
    output logic  CONTROL_AXI_RVALID,
    input logic  CONTROL_AXI_RREADY,

    // data bus
    input logic  S_AXI_ACLK,
    input logic  S_AXI_ARESETN,
    input logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_AWADDR,
    input logic [7 : 0] S_AXI_AWLEN,
    input logic [2 : 0] S_AXI_AWSIZE,
    input logic [1 : 0] S_AXI_AWBURST,
    input logic  S_AXI_AWLOCK,
    input logic  S_AXI_AWVALID,
    output logic  S_AXI_AWREADY,
    input logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_WDATA,
    input logic [(AXI_BUS_BIT_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input logic  S_AXI_WLAST,
    input logic  S_AXI_WVALID,
    output logic  S_AXI_WREADY,
    output logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output logic [1 : 0] S_AXI_BRESP,
    output logic  S_AXI_BVALID,
    input logic  S_AXI_BREADY,
    input logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_ARADDR,
    input logic [7 : 0] S_AXI_ARLEN,
    input logic [2 : 0] S_AXI_ARSIZE,
    input logic [1 : 0] S_AXI_ARBURST,
    input logic  S_AXI_ARLOCK,
    input logic  S_AXI_ARVALID,
    output logic  S_AXI_ARREADY,
    output logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_RDATA,
    output logic [1 : 0] S_AXI_RRESP,
    output logic  S_AXI_RLAST,
    output logic  S_AXI_RVALID,
    input logic  S_AXI_RREADY,

    // data bus
    input logic  WEIGHT_AXI_ACLK,
    input logic  WEIGHT_AXI_ARESETN,
    input logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_AWID,
    input logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_AWADDR,
    input logic [7 : 0] WEIGHT_AXI_AWLEN,
    input logic [2 : 0] WEIGHT_AXI_AWSIZE,
    input logic [1 : 0] WEIGHT_AXI_AWBURST,
    input logic  WEIGHT_AXI_AWLOCK,
    input logic  WEIGHT_AXI_AWVALID,
    output logic  WEIGHT_AXI_AWREADY,
    input logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_WDATA,
    input logic [(WEIGHT_AXI_BUS_BIT_WIDTH/8)-1 : 0] WEIGHT_AXI_WSTRB,
    input logic  WEIGHT_AXI_WLAST,
    input logic  WEIGHT_AXI_WVALID,
    output logic  WEIGHT_AXI_WREADY,
    output logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_BID,
    output logic [1 : 0] WEIGHT_AXI_BRESP,
    output logic  WEIGHT_AXI_BVALID,
    input logic  WEIGHT_AXI_BREADY,
    input logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_ARID,
    input logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_ARADDR,
    input logic [7 : 0] WEIGHT_AXI_ARLEN,
    input logic [2 : 0] WEIGHT_AXI_ARSIZE,
    input logic [1 : 0] WEIGHT_AXI_ARBURST,
    input logic  WEIGHT_AXI_ARLOCK,
    input logic  WEIGHT_AXI_ARVALID,
    output logic  WEIGHT_AXI_ARREADY,
    output logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_RID,
    output logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_RDATA,
    output logic [1 : 0] WEIGHT_AXI_RRESP,
    output logic  WEIGHT_AXI_RLAST,
    output logic  WEIGHT_AXI_RVALID,
    input logic  WEIGHT_AXI_RREADY

    // // weight bus interface signals
    // // input logic [AXIS_BUS_ID_BIT_WIDTH-1 : 0]   S_AXIS_TID,
    // input logic  S_AXIS_ACLK,    
    // input logic  S_AXIS_ARESETN,
    // input logic [AXIS_BUS_DATA_BIT_WIDTH-1 : 0] S_AXIS_TDATA,
    // input logic  S_AXIS_TVALID,
    // output logic  S_AXIS_TREADY,
    // input logic  S_AXIS_TLAST
);


    // s_axis_lite_bus #(
    //     .C_S_AXIS_ID_WIDTH	 (AXIS_BUS_ID_BIT_WIDTH),
    //     .C_S_AXIS_DATA_WIDTH (AXIS_BUS_DATA_BIT_WIDTH)
    // ) weight_bus ();
    // assign weight_bus.S_AXIS_ACLK       = S_AXIS_ACLK;
    // assign weight_bus.S_AXIS_ARESETN    = S_AXIS_ARESETN;
    // assign weight_bus.S_AXIS_TID        = 0;
    // assign weight_bus.S_AXIS_TDATA      = S_AXIS_TDATA;
    // assign weight_bus.S_AXIS_TVALID     = S_AXIS_TVALID;
    // assign weight_bus.S_AXIS_TLAST      = S_AXIS_TLAST;
    // assign S_AXIS_TREADY                = weight_bus.S_AXIS_TREADY;

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
    assign S_AXI_RID                = data_bus.S_AXI_RID;
    assign S_AXI_BID                = data_bus.S_AXI_BID;
    assign S_AXI_AWREADY            = data_bus.S_AXI_AWREADY;
    assign S_AXI_WREADY             = data_bus.S_AXI_WREADY;
    assign S_AXI_BRESP              = data_bus.S_AXI_BRESP;
    assign S_AXI_BVALID             = data_bus.S_AXI_BVALID;
    assign S_AXI_ARREADY            = data_bus.S_AXI_ARREADY;
    assign S_AXI_RDATA              = data_bus.S_AXI_RDATA;
    assign S_AXI_RRESP              = data_bus.S_AXI_RRESP;
    assign S_AXI_RLAST              = data_bus.S_AXI_RLAST;
    assign S_AXI_RVALID             = data_bus.S_AXI_RVALID;

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
    assign WEIGHT_AXI_RID                = weight_bus.S_AXI_RID;
    assign WEIGHT_AXI_BID                = weight_bus.S_AXI_BID;
    assign WEIGHT_AXI_AWREADY            = weight_bus.S_AXI_AWREADY;
    assign WEIGHT_AXI_WREADY             = weight_bus.S_AXI_WREADY;
    assign WEIGHT_AXI_BRESP              = weight_bus.S_AXI_BRESP;
    assign WEIGHT_AXI_BVALID             = weight_bus.S_AXI_BVALID;
    assign WEIGHT_AXI_ARREADY            = weight_bus.S_AXI_ARREADY;
    assign WEIGHT_AXI_RDATA              = weight_bus.S_AXI_RDATA;
    assign WEIGHT_AXI_RRESP              = weight_bus.S_AXI_RRESP;
    assign WEIGHT_AXI_RLAST              = weight_bus.S_AXI_RLAST;
    assign WEIGHT_AXI_RVALID             = weight_bus.S_AXI_RVALID;


    s_axi_lite_bus #(
        .C_S_AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(CONTROL_AXI_ADDR_WIDTH)
    ) control_bus(); 	
    assign control_bus.S_AXI_ACLK    = CONTROL_AXI_ACLK;
    assign control_bus.S_AXI_ARESETN = CONTROL_AXI_ARESETN;
    assign control_bus.S_AXI_AWADDR  = CONTROL_AXI_AWADDR;
    assign control_bus.S_AXI_AWVALID = CONTROL_AXI_AWVALID;
    assign control_bus.S_AXI_WDATA  = CONTROL_AXI_WDATA;
    assign control_bus.S_AXI_WSTRB  = CONTROL_AXI_WSTRB;
    assign control_bus.S_AXI_WVALID = CONTROL_AXI_WVALID;
    assign control_bus.S_AXI_BREADY  = CONTROL_AXI_BREADY;
    assign control_bus.S_AXI_ARADDR  = CONTROL_AXI_ARADDR;
    assign control_bus.S_AXI_ARVALID = CONTROL_AXI_ARVALID;
    assign control_bus.S_AXI_RREADY = CONTROL_AXI_RREADY;  
    assign CONTROL_AXI_AWREADY = control_bus.S_AXI_AWREADY;
    assign CONTROL_AXI_WREADY  = control_bus.S_AXI_WREADY;
    assign CONTROL_AXI_BRESP   = control_bus.S_AXI_BRESP;
    assign CONTROL_AXI_BVALID  = control_bus.S_AXI_BVALID;
    assign CONTROL_AXI_ARREADY = control_bus.S_AXI_ARREADY;
    assign CONTROL_AXI_RDATA   = control_bus.S_AXI_RDATA;
    assign CONTROL_AXI_RRESP   = control_bus.S_AXI_RRESP;
    assign CONTROL_AXI_RVALID  = control_bus.S_AXI_RVALID;



    NVP_v1_top NVP_v1 ( 
        .clk                        (clk),
        .resetn                     (resetn),
        .i_data_bus                 (data_bus),
        .i_weight_bus               (weight_bus),
        .i_control_bus              (control_bus),
        .o_next_command_interrupt   (o_next_command_interrupt),
        .o_output_line_stored       (o_output_line_stored),
        .*
    );

    // assign o_activation_buffer_data_out_1 = o_activation_buffer_data_out[0];
    // assign o_activation_buffer_data_out_2 = o_activation_buffer_data_out[1];
    // assign o_activation_buffer_data_out_3 = o_activation_buffer_data_out[2];
    // assign o_activation_buffer_data_out_4 = o_activation_buffer_data_out[3];
    // assign o_activation_buffer_data_out_5 = o_activation_buffer_data_out[4];
    // assign o_activation_buffer_data_out_6 = o_activation_buffer_data_out[5];
endmodule

