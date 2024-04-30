`timescale 1ns / 1ps

module playground_systemverilog_tb();

    localparam int CLOCK_PERIOD = 10;
    localparam int N = 8;
    localparam int M = 4;

    logic         clk = 0;
    logic         resetn = 1;
    logic [N-1:0] counter;   
    logic         en;
    logic         d;
    logic         q;

    playground_systemverilog #(
        .N (N),
        .M (M)
    ) dut (
        .clk        (clk),
        .resetn     (resetn),
        .en         (en),
        .d          (d),
        .q          (q),
        .o_counter  (counter)
    );

    always begin
        #(CLOCK_PERIOD/2) clk = ~clk;
    end

    initial begin
		#CLOCK_PERIOD;
        resetn = 0;
        en = 0;
        d = 0;
        #CLOCK_PERIOD;
        resetn = 1;
        #CLOCK_PERIOD;
        #(10*CLOCK_PERIOD);

        $display("finished simulation.");
        $stop;
        
    end

 
endmodule

