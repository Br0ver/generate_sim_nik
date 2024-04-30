/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Compression Router
*   Date:  11.02.2022
*   Author: hasan
*   Description: Decides either to accept input from north or from north_east, based on status of all west rounters 
*/

`timescale 1ns / 1ps

module sm_compression_router #(
    parameter int DATA_BIT_WIDTH            = 8,
    parameter int WEST_STATUS_ARRAY_BIT_WIDTH    = 4
)(
    input  logic                                    clk,
    input  logic                                    resetn,
    input  logic                                    i_enable,
    input  logic [WEST_STATUS_ARRAY_BIT_WIDTH-1:0]  i_west_status_array, 
    input  logic [DATA_BIT_WIDTH-1:0]               i_north_data, 
    input  logic                                    i_north_data_valid, 
    input  logic [DATA_BIT_WIDTH-1:0]               i_north_east_data, 
    input  logic                                    i_north_east_valid, 
    output logic [DATA_BIT_WIDTH-1:0]               o_data,
    output logic                                    o_data_valid
);

    logic [WEST_STATUS_ARRAY_BIT_WIDTH-1:0]    ONES;
    always_comb ONES = '{default:1};

    logic                       valid; 
    logic [DATA_BIT_WIDTH-1:0]  data;
    always_comb begin
        o_data   = data;
        o_data_valid = valid;
    end


    always_ff @(posedge clk) begin
        if(resetn==0) begin
            data    <= '{default:0};
            valid  <= '0;
        end
        else begin
            if(i_enable) begin
                case (&i_west_status_array)
                    1: begin
                        if (i_north_data_valid==1) begin
                            data    <= i_north_data;
                            valid  <= 1;
                        end
                        else begin
                            data    <= i_north_east_data;
                            valid  <= i_north_east_valid;
                        end
                    end
                    0: begin
                        data    <= i_north_east_data;
                        valid  <= i_north_east_valid;
                    end
                    default: begin
                        data    <= i_north_data;
                        valid  <= i_north_data_valid;
                        // status  <= i_north_east_status_bit;
                    end
                endcase
            end
        end    
    end

endmodule   