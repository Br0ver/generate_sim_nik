/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  compute unit workload statistics testbench
*   Date:  17.11.2021
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

import test_package::*;


program compute_unit_workload_statistics_tb();

    localparam int CLOCK_PERIOD = 10;

    localparam int WEIGHT_BIT_WIDTH     = 8;
    localparam int ACTIVATION_BIT_WIDTH = 8;

    localparam int INPUT_WIDTH          = 32;
    localparam int INPUT_HEIGHT         = 3;
    localparam int INPUT_CHANNELS       = 16;

    localparam int NUMBER_OF_KERNELS    = 16;
    localparam int KERNEL_HEIGHT        = 3;
    localparam int KERNEL_WIDTH         = 3;
    localparam int KERNEL_CHANNELS      = INPUT_CHANNELS;




    layer_i layer_1;
	
    initial begin
		#CLOCK_PERIOD;
        layer_1 = new();
        layer_1.randomize();
        layer_1.sparsify();
        layer_1.display_sparsity();
        #CLOCK_PERIOD;
        
        
        // for(int i = 0; i < 3*128*3; i++) begin
        //     input_image[i] = i;
        // end
        // #CLOCK_PERIOD;

        // fork 
        //     begin
        //         #CLOCK_PERIOD; 
        //         for(int i = 0; i < 1*3*128; i++) begin
        //             #CLOCK_PERIOD; 
        //             S_AXI_TID       = 0;
        //             S_AXIS_TVALID   = 1;
        //             S_AXIS_TDATA    = input_image[i];
        //             if (i == 1*3*128-1)
        //                 S_AXIS_TLAST = 1;
        //         end
        //         #CLOCK_PERIOD;
        //         S_AXIS_TLAST  = 0;
        //         S_AXIS_TVALID = 0;
        //         #CLOCK_PERIOD;
        //         for(int i = 1*3*128; i < 2*3*128; i++) begin
        //             #CLOCK_PERIOD; 
        //             S_AXI_TID       = 1;
        //             S_AXIS_TVALID   = 1;
        //             S_AXIS_TDATA    = input_image[i];
        //             if (i == 2*3*128-1)
        //                 S_AXIS_TLAST = 1;
        //         end
        //         #CLOCK_PERIOD;
        //         S_AXIS_TLAST  = 0;
        //         S_AXIS_TVALID = 0;
        //         #CLOCK_PERIOD;
        //         for(int i = 2*3*128; i < 3*3*128; i++) begin
        //             #CLOCK_PERIOD; 
        //             S_AXI_TID       = 2;
        //             S_AXIS_TVALID   = 1;
        //             S_AXIS_TDATA    = input_image[i];
        //             if (i == 3*3*128-1)
        //                 S_AXIS_TLAST = 1;
        //         end
        //         #CLOCK_PERIOD;
        //         S_AXIS_TLAST  = 0;
        //         S_AXIS_TVALID = 0;
        //         #CLOCK_PERIOD;
        //     end

        //     begin
        //         for(int i = 0; i < 1*3*128; i++) begin
        //             #CLOCK_PERIOD
        //             if (i%3 == 0 || i%2 == 0 || i%4 == 0) begin 
        //                 stream_1_read_ready = 1;
        //             end 
        //             else begin 
        //                 stream_1_read_ready = 0;
        //             end

        //             if (i%6 == 0) begin 
        //                 stream_2_read_ready = 1;
        //             end 
        //             else begin 
        //                 stream_2_read_ready = 0;
        //             end

        //             if (i%10 == 0) begin 
        //                 stream_3_read_ready = 1;
        //             end 
        //             else begin 
        //                 stream_3_read_ready = 0;
        //             end
        //         end
        //     end
        // join
        // wait fork;
        #100


        $display("finished simulation.");
        $stop;
        
    end

 
endprogram

