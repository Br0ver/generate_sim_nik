/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: BRAM with byte-wide write enable. 
*   Date:   18.01.2022
*   Author: hasan
*   Description:  Adapted from Xilinx's RAM HDL coding guidlines. 
*/

`timescale 1ns / 1ps


module bram_sdp_byte_write #(
    //--------------------------------------------------------------------------
    parameter  int NUMBER_OF_COLUMNS    = 8,
    parameter  int COLUMN_WIDTH         = 16,
    parameter  int DEPTH                = 128,
    localparam int ADDR_WIDTH           = $clog2(DEPTH),
    localparam int DATA_WIDTH           = NUMBER_OF_COLUMNS*COLUMN_WIDTH  
)(     
    input logic                         clk,     
    input logic                         ena,      
    input logic [NUMBER_OF_COLUMNS-1:0] wea,     
    input logic [ADDR_WIDTH-1:0]        addra,     
    input logic [DATA_WIDTH-1:0]        dina,     
    input logic                         enb,     
    input logic [ADDR_WIDTH-1:0]        addrb,     
    output logic [DATA_WIDTH-1:0]       doutb     
);   

    // Core Memory     
    (* ram_style = "block" *) logic [DATA_WIDTH-1:0]   ram_block [(2**ADDR_WIDTH)-1:0];   

    // Port-A Operation   
    always_ff @(posedge clk) begin  
        if(ena) begin         
            for(int i=0;i<NUMBER_OF_COLUMNS;i=i+1) begin            
                if(wea[i]) begin               
                    ram_block[addra][i*COLUMN_WIDTH +: COLUMN_WIDTH] <= dina[i*COLUMN_WIDTH +: COLUMN_WIDTH];            
                end         
            end         
            // doutA <= ram_block[addra];  
        end   
    end   
    
    
    // Port-B Operation:   
    always_ff @(posedge clk) begin
        if(enb) begin         
            // for(i=0;i<NUMBER_OF_COLUMNS;i=i+1) begin            
            //     if(weB[i]) begin               
            //         ram_block[addrb][i*COLUMN_WIDTH +: COLUMN_WIDTH] <= dinB[i*COLUMN_WIDTH +: COLUMN_WIDTH];            
            //     end         
            // end              
            doutb <= ram_block[addrb];        
        end   
    end

endmodule 