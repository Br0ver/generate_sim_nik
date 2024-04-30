/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: s_axi_bus
*   Date:   20.09.2021
*   Author: hasan
*   Description: The bus definition for an AXI Full Slave interface.              
*/

`timescale 1ns / 1ps
interface s_axi_bus #(
    parameter int C_S_AXI_ID_WIDTH	    = 1,
    parameter int C_S_AXI_DATA_WIDTH	= 32,
    parameter int C_S_AXI_ADDR_WIDTH	= 15
)();
    logic  S_AXI_ACLK;
    logic  S_AXI_ARESETN;

    // write address channel
    logic [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID;
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
    logic [7 : 0] S_AXI_AWLEN;
    logic [2 : 0] S_AXI_AWSIZE;
    logic [1 : 0] S_AXI_AWBURST;
    logic  S_AXI_AWLOCK;
    logic  S_AXI_AWVALID;
    logic  S_AXI_AWREADY;

    // write data channel
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
    logic [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
    logic  S_AXI_WLAST;
    logic  S_AXI_WVALID;
    logic  S_AXI_WREADY;

    // write response channel
    logic [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_BID;
    logic [1 : 0] S_AXI_BRESP;
    logic  S_AXI_BVALID;
    logic  S_AXI_BREADY;

    // read address channel
    logic [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID;
    logic [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
    logic [7 : 0] S_AXI_ARLEN;
    logic [2 : 0] S_AXI_ARSIZE;
    logic [1 : 0] S_AXI_ARBURST;
    logic  S_AXI_ARLOCK;
    logic  S_AXI_ARVALID;
    logic  S_AXI_ARREADY;

    // read data channel
    logic [C_S_AXI_ID_WIDTH-1 : 0] S_AXI_RID;
    logic [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
    logic [1 : 0] S_AXI_RRESP;
    logic  S_AXI_RLAST;
    logic  S_AXI_RVALID;
    logic  S_AXI_RREADY;

    modport slave (
        input   S_AXI_ACLK, S_AXI_ARESETN,
            S_AXI_AWID, S_AXI_AWADDR, S_AXI_AWLEN, S_AXI_AWSIZE, S_AXI_AWBURST, S_AXI_AWLOCK, S_AXI_AWVALID,
            S_AXI_WDATA, S_AXI_WSTRB, S_AXI_WLAST, S_AXI_WVALID,
            S_AXI_BREADY, 
            S_AXI_ARID, S_AXI_ARADDR, S_AXI_ARLEN, S_AXI_ARSIZE, S_AXI_ARBURST, S_AXI_ARLOCK, S_AXI_ARVALID, S_AXI_RREADY,
        output S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BID, S_AXI_BRESP, S_AXI_BVALID,
            S_AXI_ARREADY, S_AXI_RID, S_AXI_RDATA, S_AXI_RRESP, S_AXI_RLAST, S_AXI_RVALID
    );

endinterface