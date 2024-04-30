`timescale 1ns / 1ps
// `timescale <time unit> / <time precision>


module playground_systemverilog #(
    parameter integer N = 8,
    parameter integer M = 4
)(
    input  logic                clk,
    input  logic                resetn,
    input  logic                en,
    input  logic                d,
    output logic                q,
    output logic [N-1:0]        o_counter
);

    //// d-flipflop
    // always_ff @(posedge clk) begin
    //     if(resetn==0) begin
    //         q <= 0;
    //     end
    //     else begin
    //         q <= d;
    //     end
    // end

    //// d-flipflop with enable
    // always_ff @(posedge clk) begin
    //     if(resetn==0) begin
    //         q <= 0;
    //     end
    //     else begin
    //         if(en) begin
    //             q <= d;
    //         end
    //         else begin
    //             q <= q;
    //         end
    //     end
    // end

    //// N-bit counter
    // logic [N-1:0] counter;
    // always_ff @(posedge clk) begin
    //     if(resetn==0) begin
    //         counter <= 0;
    //     end
    //     else begin
    //         if(en) begin
    //             counter <= counter + 1;
    //         end
    //     end
    // end

    logic [N-1:0] counter;
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            counter <= 0;
        end
        else begin                
            if(counter == M)begin
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end
    always_comb begin
        o_counter = counter;
    end


endmodule