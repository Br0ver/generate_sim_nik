/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Delay Unit
*   Date:   29.01.2022
*   Author: hasan
*   Description: A configurable delay module. 
*/

`timescale 1ns / 1ps

module delay_unit #(   
    parameter int DATA_WIDTH    = 16, 
    parameter int DELAY_CYCLES  = 1
)(
    input  logic                     clk,
    input  logic                     resetn,
    input  logic [DATA_WIDTH-1:0]    i_input_data,
    input  logic                     i_input_data_valid,
    output logic [DATA_WIDTH-1:0]    o_output_data,
    output logic                     o_output_data_valid
);

    logic [DATA_WIDTH-1:0]  data_delay_registers  [DELAY_CYCLES];
    logic                   valid_delay_registers [DELAY_CYCLES];

    always_ff @(posedge clk) begin
        if(resetn==0) begin
            for(int i=0; i<DELAY_CYCLES; i++) begin
                data_delay_registers[i]     <= '{default:0};
                valid_delay_registers[i]    <= '0;
            end
        end
        else begin
            data_delay_registers[0]     <= i_input_data;
            valid_delay_registers[0]    <= i_input_data_valid;
            
            for(int i=1; i<DELAY_CYCLES; i++) begin
                data_delay_registers[i]     <= data_delay_registers[i-1];
                valid_delay_registers[i]    <= valid_delay_registers[i-1];
            end
        end
    end

    always_comb o_output_data       = data_delay_registers[DELAY_CYCLES-1];
    always_comb o_output_data_valid = valid_delay_registers[DELAY_CYCLES-1];

endmodule