/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP Accelerator v1 Top Module
*   Date:  05.11.2021
*   Author: hasan
*   Description: The Accelerator's top level module. Connects all the submodules.  
*/

`timescale 1ns / 1ps

module NVP_v1_top_wrapper_verilog #(
    parameter C_CONTROL_AXI_DATA_WIDTH  = 32,
    parameter C_CONTROL_AXI_ADDR_WIDTH  = 6,
    parameter S_AXI_ID_WIDTH            = 1,
    parameter AXI_BUS_BIT_WIDTH         = 64,
    parameter AXI_BUS_ADDRESS_WIDTH     = 16,
    parameter WEIGHT_AXI_ID_WIDTH           = 1,
    parameter WEIGHT_AXI_BUS_BIT_WIDTH        = 64,
    parameter WEIGHT_AXI_BUS_ADDRESS_WIDTH    = 16,
    parameter NUMBER_OF_READ_STREAMS    = 3,
    parameter ACTIVATION_BIT_WIDTH      = 8,
    parameter COLUMN_VALUE_BIT_WIDTH    = 2, 
    parameter CHANNEL_VALUE_BIT_WIDTH   = 7,
    parameter ROW_VALUE_BIT_WIDTH       = 2
)( 
    input wire             clk,
    input wire             resetn,
    output wire            o_next_command_interrupt,
    output wire            o_output_line_stored,

// Control bus
    input wire  CONTROL_AXI_ACLK,
    input wire  CONTROL_AXI_ARESETN,
    input wire [C_CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_AWADDR,
    input wire  CONTROL_AXI_AWVALID,
    output wire  CONTROL_AXI_AWREADY,
    input wire [C_CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_WDATA,
    input wire [(C_CONTROL_AXI_DATA_WIDTH/8)-1 : 0] CONTROL_AXI_WSTRB,
    input wire  CONTROL_AXI_WVALID,
    output wire  CONTROL_AXI_WREADY,
    output wire [1 : 0] CONTROL_AXI_BRESP,
    output wire  CONTROL_AXI_BVALID,
    input wire  CONTROL_AXI_BREADY,
    input wire [C_CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_ARADDR,
    input wire  CONTROL_AXI_ARVALID,
    output wire  CONTROL_AXI_ARREADY,
    output wire [C_CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_RDATA,
    output wire [1 : 0] CONTROL_AXI_RRESP,
    output wire  CONTROL_AXI_RVALID,
    input wire  CONTROL_AXI_RREADY,

    // data bus
    input  wire  S_AXI_ACLK,
    input  wire  S_AXI_ARESETN,
    input  wire [S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID,
    input  wire [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_AWADDR,
    input  wire [7 : 0] S_AXI_AWLEN,
    input  wire [2 : 0] S_AXI_AWSIZE,
    input  wire [1 : 0] S_AXI_AWBURST,
    input  wire  S_AXI_AWLOCK,
    input  wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input  wire [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_WDATA,
    input  wire [(AXI_BUS_BIT_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire  S_AXI_WLAST,
    input  wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [S_AXI_ID_WIDTH-1 : 0] S_AXI_BID,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input  wire  S_AXI_BREADY,
    input  wire [S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID,
    input  wire [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_ARADDR,
    input  wire [7 : 0] S_AXI_ARLEN,
    input  wire [2 : 0] S_AXI_ARSIZE,
    input  wire [1 : 0] S_AXI_ARBURST,
    input  wire  S_AXI_ARLOCK,
    input  wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [S_AXI_ID_WIDTH-1 : 0] S_AXI_RID,
    output wire [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RLAST,
    output wire  S_AXI_RVALID,
    input  wire  S_AXI_RREADY,

    // weight bus
    input  wire  WEIGHT_AXI_ACLK,
    input  wire  WEIGHT_AXI_ARESETN,
    input  wire [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_AWID,
    input  wire [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_AWADDR,
    input  wire [7 : 0] WEIGHT_AXI_AWLEN,
    input  wire [2 : 0] WEIGHT_AXI_AWSIZE,
    input  wire [1 : 0] WEIGHT_AXI_AWBURST,
    input  wire  WEIGHT_AXI_AWLOCK,
    input  wire  WEIGHT_AXI_AWVALID,
    output wire  WEIGHT_AXI_AWREADY,
    input  wire [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_WDATA,
    input  wire [(WEIGHT_AXI_BUS_BIT_WIDTH/8)-1 : 0] WEIGHT_AXI_WSTRB,
    input  wire  WEIGHT_AXI_WLAST,
    input  wire  WEIGHT_AXI_WVALID,
    output wire  WEIGHT_AXI_WREADY,
    output wire [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_BID,
    output wire [1 : 0] WEIGHT_AXI_BRESP,
    output wire  WEIGHT_AXI_BVALID,
    input  wire  WEIGHT_AXI_BREADY,
    input  wire [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_ARID,
    input  wire [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_ARADDR,
    input  wire [7 : 0] WEIGHT_AXI_ARLEN,
    input  wire [2 : 0] WEIGHT_AXI_ARSIZE,
    input  wire [1 : 0] WEIGHT_AXI_ARBURST,
    input  wire  WEIGHT_AXI_ARLOCK,
    input  wire  WEIGHT_AXI_ARVALID,
    output wire  WEIGHT_AXI_ARREADY,
    output wire [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_RID,
    output wire [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_RDATA,
    output wire [1 : 0] WEIGHT_AXI_RRESP,
    output wire  WEIGHT_AXI_RLAST,
    output wire  WEIGHT_AXI_RVALID,
    input  wire  WEIGHT_AXI_RREADY

//    output wire [NUMBER_OF_READ_STREAMS-1:0]  debug_last_column    ,
//    output wire [ACTIVATION_BIT_WIDTH-1:0]    debug_0_data           ,
//    output wire [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_0_toggled_column ,
//    output wire [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_0_channel        ,
//    output wire [ROW_VALUE_BIT_WIDTH-1:0]     debug_0_relative_row   ,
//    output wire                               debug_0_valid          ,
//    output wire                               debug_0_ready          ,
//    output wire [ACTIVATION_BIT_WIDTH-1:0]    debug_1_data           ,
//    output wire [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_1_toggled_column ,
//    output wire [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_1_channel        ,
//    output wire [ROW_VALUE_BIT_WIDTH-1:0]     debug_1_relative_row   ,
//    output wire                               debug_1_valid          ,
//    output wire                               debug_1_ready          ,
//    output wire [ACTIVATION_BIT_WIDTH-1:0]    debug_2_data           ,
//    output wire [COLUMN_VALUE_BIT_WIDTH-1:0]  debug_2_toggled_column ,
//    output wire [CHANNEL_VALUE_BIT_WIDTH-1:0] debug_2_channel        ,
//    output wire [ROW_VALUE_BIT_WIDTH-1:0]     debug_2_relative_row   ,
//    output wire                               debug_2_valid          ,
//    output wire                               debug_2_ready          ,
//    output wire unsigned [ACTIVATION_BIT_WIDTH*ACTIVATION_BIT_WIDTH-1:0]    debug_quantized_activations, 
//    output wire                                        debug_quantized_activations_valid

    // input  wire                                 s_axis_aclk,    
    // input  wire                                 s_axis_aresetn,
    // input  wire [AXIS_BUS_DATA_BIT_WIDTH-1:0]   s_axis_tdata,
    // input  wire [AXIS_BUS_DATA_BIT_WIDTH/8-1:0] s_axis_tkeep,
    // input  wire                                 s_axis_tvalid,
    // output wire                                 s_axis_tready,
    // input  wire                                 s_axis_tlast
);


    NVP_v1_top_wrapper_systemverilog top (
    .clk                        (clk),                                                                       
    .resetn                     (resetn),                                                               
    .o_next_command_interrupt   (o_next_command_interrupt), 
    .o_output_line_stored       (o_output_line_stored), 

    .CONTROL_AXI_ACLK       (CONTROL_AXI_ACLK),
    .CONTROL_AXI_ARESETN    (CONTROL_AXI_ARESETN),                                     
    .CONTROL_AXI_AWADDR     (CONTROL_AXI_AWADDR),                                                   
    .CONTROL_AXI_AWVALID    (CONTROL_AXI_AWVALID),                                                            
    .CONTROL_AXI_WDATA      (CONTROL_AXI_WDATA),                                                      
    .CONTROL_AXI_WSTRB      (CONTROL_AXI_WSTRB),                                                      
    .CONTROL_AXI_WVALID     (CONTROL_AXI_WVALID),                                                   
    .CONTROL_AXI_ARADDR     (CONTROL_AXI_ARADDR),                                                   
    .CONTROL_AXI_ARVALID    (CONTROL_AXI_ARVALID),                                                            
    .CONTROL_AXI_BREADY     (CONTROL_AXI_BREADY),                                                   
    .CONTROL_AXI_RREADY     (CONTROL_AXI_RREADY),                                                   
    .CONTROL_AXI_AWREADY    (CONTROL_AXI_AWREADY),                                                            
    .CONTROL_AXI_WREADY     (CONTROL_AXI_WREADY),                                                   
    .CONTROL_AXI_BRESP      (CONTROL_AXI_BRESP),                                                      
    .CONTROL_AXI_BVALID     (CONTROL_AXI_BVALID),                                                   
    .CONTROL_AXI_ARREADY    (CONTROL_AXI_ARREADY),                                                            
    .CONTROL_AXI_RDATA      (CONTROL_AXI_RDATA),                                                      
    .CONTROL_AXI_RRESP      (CONTROL_AXI_RRESP),                                                      
    .CONTROL_AXI_RVALID     (CONTROL_AXI_RVALID),   

    .S_AXI_ACLK      (S_AXI_ACLK),
    .S_AXI_ARESETN   (S_AXI_ARESETN),
    .S_AXI_AWID      (S_AXI_AWID),
    .S_AXI_AWADDR    (S_AXI_AWADDR),
    .S_AXI_AWLEN     (S_AXI_AWLEN),
    .S_AXI_AWSIZE    (S_AXI_AWSIZE),
    .S_AXI_AWBURST   (S_AXI_AWBURST),
    .S_AXI_AWLOCK    (S_AXI_AWLOCK),
    .S_AXI_AWVALID   (S_AXI_AWVALID),
    .S_AXI_WDATA     (S_AXI_WDATA),
    .S_AXI_WSTRB     (S_AXI_WSTRB),
    .S_AXI_WLAST     (S_AXI_WLAST),
    .S_AXI_WVALID    (S_AXI_WVALID),
    .S_AXI_BREADY    (S_AXI_BREADY),
    .S_AXI_ARID      (S_AXI_ARID),
    .S_AXI_ARADDR    (S_AXI_ARADDR),
    .S_AXI_ARLEN     (S_AXI_ARLEN),
    .S_AXI_ARSIZE    (S_AXI_ARSIZE),
    .S_AXI_ARBURST   (S_AXI_ARBURST),
    .S_AXI_ARLOCK    (S_AXI_ARLOCK),
    .S_AXI_ARVALID   (S_AXI_ARVALID),
    .S_AXI_RREADY    (S_AXI_RREADY),
    .S_AXI_AWREADY   (S_AXI_AWREADY),
    .S_AXI_WREADY    (S_AXI_WREADY),
    .S_AXI_BID       (S_AXI_BID),
    .S_AXI_BRESP     (S_AXI_BRESP),
    .S_AXI_BVALID    (S_AXI_BVALID),
    .S_AXI_ARREADY   (S_AXI_ARREADY),
    .S_AXI_RID       (S_AXI_RID),
    .S_AXI_RDATA     (S_AXI_RDATA),
    .S_AXI_RRESP     (S_AXI_RRESP),
    .S_AXI_RLAST     (S_AXI_RLAST),
    .S_AXI_RVALID    (S_AXI_RVALID),

    .WEIGHT_AXI_ACLK      (WEIGHT_AXI_ACLK),
    .WEIGHT_AXI_ARESETN   (WEIGHT_AXI_ARESETN),
    .WEIGHT_AXI_AWID      (WEIGHT_AXI_AWID),
    .WEIGHT_AXI_AWADDR    (WEIGHT_AXI_AWADDR),
    .WEIGHT_AXI_AWLEN     (WEIGHT_AXI_AWLEN),
    .WEIGHT_AXI_AWSIZE    (WEIGHT_AXI_AWSIZE),
    .WEIGHT_AXI_AWBURST   (WEIGHT_AXI_AWBURST),
    .WEIGHT_AXI_AWLOCK    (WEIGHT_AXI_AWLOCK),
    .WEIGHT_AXI_AWVALID   (WEIGHT_AXI_AWVALID),
    .WEIGHT_AXI_WDATA     (WEIGHT_AXI_WDATA),
    .WEIGHT_AXI_WSTRB     (WEIGHT_AXI_WSTRB),
    .WEIGHT_AXI_WLAST     (WEIGHT_AXI_WLAST),
    .WEIGHT_AXI_WVALID    (WEIGHT_AXI_WVALID),
    .WEIGHT_AXI_BREADY    (WEIGHT_AXI_BREADY),
    .WEIGHT_AXI_ARID      (WEIGHT_AXI_ARID),
    .WEIGHT_AXI_ARADDR    (WEIGHT_AXI_ARADDR),
    .WEIGHT_AXI_ARLEN     (WEIGHT_AXI_ARLEN),
    .WEIGHT_AXI_ARSIZE    (WEIGHT_AXI_ARSIZE),
    .WEIGHT_AXI_ARBURST   (WEIGHT_AXI_ARBURST),
    .WEIGHT_AXI_ARLOCK    (WEIGHT_AXI_ARLOCK),
    .WEIGHT_AXI_ARVALID   (WEIGHT_AXI_ARVALID),
    .WEIGHT_AXI_RREADY    (WEIGHT_AXI_RREADY),
    .WEIGHT_AXI_AWREADY   (WEIGHT_AXI_AWREADY),
    .WEIGHT_AXI_WREADY    (WEIGHT_AXI_WREADY),
    .WEIGHT_AXI_BID       (WEIGHT_AXI_BID),
    .WEIGHT_AXI_BRESP     (WEIGHT_AXI_BRESP),
    .WEIGHT_AXI_BVALID    (WEIGHT_AXI_BVALID),
    .WEIGHT_AXI_ARREADY   (WEIGHT_AXI_ARREADY),
    .WEIGHT_AXI_RID       (WEIGHT_AXI_RID),
    .WEIGHT_AXI_RDATA     (WEIGHT_AXI_RDATA),
    .WEIGHT_AXI_RRESP     (WEIGHT_AXI_RRESP),
    .WEIGHT_AXI_RLAST     (WEIGHT_AXI_RLAST),
    .WEIGHT_AXI_RVALID    (WEIGHT_AXI_RVALID),

    .debug_last_column      (debug_last_column),              
    .debug_0_data           (debug_0_data),    
    .debug_0_toggled_column (debug_0_toggled_column),            
    .debug_0_channel        (debug_0_channel),        
    .debug_0_relative_row   (debug_0_relative_row),            
    .debug_0_valid          (debug_0_valid),    
    .debug_0_ready          (debug_0_ready),    
    .debug_1_data           (debug_1_data),    
    .debug_1_toggled_column (debug_1_toggled_column),            
    .debug_1_channel        (debug_1_channel),        
    .debug_1_relative_row   (debug_1_relative_row),            
    .debug_1_valid          (debug_1_valid),    
    .debug_1_ready          (debug_1_ready),    
    .debug_2_data           (debug_2_data),    
    .debug_2_toggled_column (debug_2_toggled_column),            
    .debug_2_channel        (debug_2_channel),        
    .debug_2_relative_row   (debug_2_relative_row),            
    .debug_2_valid          (debug_2_valid),    
    .debug_2_ready          (debug_2_ready),
    .debug_quantized_activations (debug_quantized_activations),
    .debug_quantized_activations_valid (debug_quantized_activations_valid)

    // // .S_AXI_TID (S_AXI_TID),  
    // .S_AXIS_ACLK    (s_axis_aclk),
    // .S_AXIS_ARESETN (s_axis_aresetn),                                                    
    // .S_AXIS_TDATA   (s_axis_tdata),                                                         
    // .S_AXIS_TVALID  (s_axis_tvalid),                                                      
    // .S_AXIS_TREADY  (s_axis_tready),                                                    
    // .S_AXIS_TLAST   (s_axis_tlast)
);

endmodule