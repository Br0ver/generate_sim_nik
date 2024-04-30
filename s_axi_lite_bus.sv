/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: s_axi_lite_bus
*   Date:   27.09.2021
*   Author: hasan
*   Description:    The bus definition for an AXI Lite Slave interface.              
*/

`timescale 1ns / 1ps
interface s_axi_lite_bus #(
    parameter int C_S_AXI_DATA_WIDTH	= NVP_v1_constants::CONTROL_AXI_DATA_WIDTH,
    parameter int C_S_AXI_ADDR_WIDTH	= NVP_v1_constants::CONTROL_AXI_ADDR_WIDTH
)();
    logic  S_AXI_ACLK;    
    logic  S_AXI_ARESETN;
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
    logic  S_AXI_AWVALID;
    logic  S_AXI_AWREADY;
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
    logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
    logic  S_AXI_WVALID;
    logic  S_AXI_WREADY;
    logic [1 : 0] S_AXI_BRESP;
    logic  S_AXI_BVALID;
    logic  S_AXI_BREADY;
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
    logic  S_AXI_ARVALID;
    logic  S_AXI_ARREADY;
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
    logic [1 : 0] S_AXI_RRESP;
    logic  S_AXI_RVALID;
    logic  S_AXI_RREADY;

    modport slave (
        input   S_AXI_ACLK, S_AXI_ARESETN,
            S_AXI_AWADDR, S_AXI_AWVALID,
            S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WVALID,
            S_AXI_BREADY, 
            S_AXI_ARADDR, S_AXI_ARVALID, S_AXI_RREADY,
        output S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BRESP, S_AXI_BVALID,
            S_AXI_ARREADY, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RVALID
    );

endinterface