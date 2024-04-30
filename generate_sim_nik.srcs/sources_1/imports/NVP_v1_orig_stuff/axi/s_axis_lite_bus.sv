/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: s_axis_lite_bus
*   Date:   09.11.2021
*   Author: hasan
*   Description:    The bus definition for an AXIS Lite Slave interface.              
*/

// `timescale 1ns / 1ps
// interface s_axis_lite_bus #(
//     parameter int C_S_AXIS_DATA_WIDTH	= NVP_v1_constants::AXIS_BUS_BIT_WIDTH,
//     parameter int C_S_AXIS_ID_WIDTH	    = NVP_v1_constants::AXIS_BUS_ID_BIT_WIDTH
// )();
//     logic  S_AXIS_ACLK;    
//     logic  S_AXIS_ARESETN;
//     logic [C_S_AXIS_ID_WIDTH-1 : 0] S_AXIS_TID;
//     logic [C_S_AXIS_DATA_WIDTH-1 : 0] S_AXIS_TDATA;
//     logic  S_AXIS_TVALID;
//     logic  S_AXIS_TREADY;
//     logic  S_AXIS_TLAST;

//     modport slave (
//         input   S_AXIS_ACLK, S_AXIS_ARESETN,
//             S_AXIS_TDATA, S_AXIS_TVALID, S_AXIS_TLAST, S_AXIS_TID,
//         output S_AXIS_TREADY
//     );

// endinterface