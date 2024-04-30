/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  NVP_v1_top testbench
*   Date:  21.12.2021
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

import test_package::*;
import NVP_v1_constants::*;
import test_NN_package::*;
// import ::*; 

module NVP_v1_top_tb();

    localparam CLOCK_PERIOD = 2;
    
    // Control AXI Buffer Interface
    logic  CONTROL_AXI_ACLK;
    logic  CONTROL_AXI_ARESETN;
    logic [CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_AWADDR;
    logic  CONTROL_AXI_AWVALID;
    logic  CONTROL_AXI_AWREADY;
    logic [CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_WDATA;
    logic [(CONTROL_AXI_DATA_WIDTH/8)-1 : 0] CONTROL_AXI_WSTRB;
    logic  CONTROL_AXI_WVALID;
    logic  CONTROL_AXI_WREADY;
    logic [1 : 0] CONTROL_AXI_BRESP;
    logic  CONTROL_AXI_BVALID;
    logic  CONTROL_AXI_BREADY;
    logic [CONTROL_AXI_ADDR_WIDTH-1 : 0] CONTROL_AXI_ARADDR;
    logic  CONTROL_AXI_ARVALID;
    logic  CONTROL_AXI_ARREADY; 
    logic [CONTROL_AXI_DATA_WIDTH-1 : 0] CONTROL_AXI_RDATA;
    logic [1 : 0] CONTROL_AXI_RRESP;
    logic  CONTROL_AXI_RVALID;
    logic  CONTROL_AXI_RREADY;

    // data bus interface signals
    localparam S_AXI_ID_WIDTH           = 1;
    logic  S_AXI_ACLK;
    logic  S_AXI_ARESETN;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_AWID = '{default:0};
    logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_AWADDR = '{default:0};
    logic [7 : 0] S_AXI_AWLEN = '{default:0};
    logic [2 : 0] S_AXI_AWSIZE = '{default:0};
    logic [1 : 0] S_AXI_AWBURST = '{default:0};
    logic  S_AXI_AWLOCK = '{default:0};
    logic  S_AXI_AWVALID = '{default:0};
    logic  S_AXI_AWREADY;
    logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_WDATA = '{default:0};
    logic [(AXI_BUS_BIT_WIDTH/8)-1 : 0] S_AXI_WSTRB = '{default:0};
    logic  S_AXI_WLAST = '{default:0};
    logic  S_AXI_WVALID = '{default:0};
    logic  S_AXI_WREADY;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_BID;
    logic [1 : 0] S_AXI_BRESP;
    logic  S_AXI_BVALID;
    logic  S_AXI_BREADY = '{default:0};
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_ARID = '{default:0};
    logic [AXI_BUS_ADDRESS_WIDTH-1 : 0] S_AXI_ARADDR = '{default:0};
    logic [7 : 0] S_AXI_ARLEN = '{default:0};
    logic [2 : 0] S_AXI_ARSIZE = '{default:0};
    logic [1 : 0] S_AXI_ARBURST = '{default:0};
    logic  S_AXI_ARLOCK = '{default:0};
    logic  S_AXI_ARVALID = '{default:0};
    logic  S_AXI_ARREADY;
    logic [S_AXI_ID_WIDTH-1 : 0] S_AXI_RID;
    logic [AXI_BUS_BIT_WIDTH-1 : 0] S_AXI_RDATA;
    logic [1 : 0] S_AXI_RRESP;
    logic  S_AXI_RLAST;
    logic  S_AXI_RVALID;
    logic  S_AXI_RREADY = '{default:0};


    // weight bus interface signals
    localparam WEIGHT_AXI_ID_WIDTH           = 1;
    logic  WEIGHT_AXI_ACLK;
    logic  WEIGHT_AXI_ARESETN;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_AWID = '{default:0};
    logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_AWADDR = '{default:0};
    logic [7 : 0] WEIGHT_AXI_AWLEN = '{default:0};
    logic [2 : 0] WEIGHT_AXI_AWSIZE = '{default:0};
    logic [1 : 0] WEIGHT_AXI_AWBURST = '{default:0};
    logic  WEIGHT_AXI_AWLOCK = '{default:0};
    logic  WEIGHT_AXI_AWVALID = '{default:0};
    logic  WEIGHT_AXI_AWREADY;
    logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_WDATA = '{default:0};
    logic [(WEIGHT_AXI_BUS_BIT_WIDTH/8)-1 : 0] WEIGHT_AXI_WSTRB = '{default:0};
    logic  WEIGHT_AXI_WLAST = '{default:0};
    logic  WEIGHT_AXI_WVALID = '{default:0};
    logic  WEIGHT_AXI_WREADY;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_BID;
    logic [1 : 0] WEIGHT_AXI_BRESP;
    logic  WEIGHT_AXI_BVALID;
    logic  WEIGHT_AXI_BREADY = '{default:0};
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_ARID = '{default:0};
    logic [WEIGHT_AXI_BUS_ADDRESS_WIDTH-1 : 0] WEIGHT_AXI_ARADDR = '{default:0};
    logic [7 : 0] WEIGHT_AXI_ARLEN = '{default:0};
    logic [2 : 0] WEIGHT_AXI_ARSIZE = '{default:0};
    logic [1 : 0] WEIGHT_AXI_ARBURST = '{default:0};
    logic  WEIGHT_AXI_ARLOCK = '{default:0};
    logic  WEIGHT_AXI_ARVALID = '{default:0};
    logic  WEIGHT_AXI_ARREADY;
    logic [WEIGHT_AXI_ID_WIDTH-1 : 0] WEIGHT_AXI_RID;
    logic [WEIGHT_AXI_BUS_BIT_WIDTH-1 : 0] WEIGHT_AXI_RDATA;
    logic [1 : 0] WEIGHT_AXI_RRESP;
    logic  WEIGHT_AXI_RLAST;
    logic  WEIGHT_AXI_RVALID;
    logic  WEIGHT_AXI_RREADY = '{default:0};


    // parameter LAYER_ID = 0;

    logic clk = 0;
    logic resetn = 1;
    logic next_command_interrupt;
    logic output_line_stored;
    // logic [REGISTER_WIDTH-1:0] output_line_i_end_address [OUTPUT_ACTIVATION_ROWS];

    // int address_offset;
    // int input_line_address;
    // int output_line_address,stream_writer_address, reg_file_stream_writer_address;
    // int relative_row_0, relative_row_1, relative_row_2;
    // int stream_read_0_address, stream_read_1_address, stream_read_2_address;
    // int input_row_index;
    // int previous_line_index;
    // int next_line_index;
    // int max_entries;
    // int stream_read_0_enable, stream_read_1_enable, stream_read_2_enable;
    // int unsigned output_line_i_length [OUTPUT_ACTIVATION_ROWS];

    

    // logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];

    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(WEIGHT_AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH)
    ) weight_bus ();
    
    virtual s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(WEIGHT_AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH)
    ) v_weight_bus;
    
    // Comment out this v bus bc errors and stuff and seemed to be not needed
    //assign v_weight_bus = weight_bus;
    
    assign weight_bus.S_AXI_ACLK      = WEIGHT_AXI_ACLK;
    assign weight_bus.S_AXI_ARESETN   = WEIGHT_AXI_ARESETN;
    assign weight_bus.S_AXI_AWID      = WEIGHT_AXI_AWID;
    assign weight_bus.S_AXI_AWADDR    = WEIGHT_AXI_AWADDR;
    assign weight_bus.S_AXI_AWLEN     = WEIGHT_AXI_AWLEN;
    assign weight_bus.S_AXI_AWSIZE    = WEIGHT_AXI_AWSIZE;
    assign weight_bus.S_AXI_AWBURST   = WEIGHT_AXI_AWBURST;
    assign weight_bus.S_AXI_AWLOCK    = WEIGHT_AXI_AWLOCK;
    assign weight_bus.S_AXI_AWVALID   = WEIGHT_AXI_AWVALID;
    assign weight_bus.S_AXI_WDATA     = WEIGHT_AXI_WDATA;
    assign weight_bus.S_AXI_WSTRB     = WEIGHT_AXI_WSTRB;
    assign weight_bus.S_AXI_WLAST     = WEIGHT_AXI_WLAST;
    assign weight_bus.S_AXI_WVALID    = WEIGHT_AXI_WVALID;
    assign weight_bus.S_AXI_BREADY    = WEIGHT_AXI_BREADY;
    assign weight_bus.S_AXI_ARID      = WEIGHT_AXI_ARID;
    assign weight_bus.S_AXI_ARADDR    = WEIGHT_AXI_ARADDR;
    assign weight_bus.S_AXI_ARLEN     = WEIGHT_AXI_ARLEN;
    assign weight_bus.S_AXI_ARSIZE    = WEIGHT_AXI_ARSIZE;
    assign weight_bus.S_AXI_ARBURST   = WEIGHT_AXI_ARBURST;
    assign weight_bus.S_AXI_ARLOCK    = WEIGHT_AXI_ARLOCK;
    assign weight_bus.S_AXI_ARVALID   = WEIGHT_AXI_ARVALID;
    assign weight_bus.S_AXI_RREADY    = WEIGHT_AXI_RREADY;
    assign WEIGHT_AXI_AWREADY         = weight_bus.S_AXI_AWREADY;
    assign WEIGHT_AXI_WREADY          = weight_bus.S_AXI_WREADY;
    assign WEIGHT_AXI_BID             = weight_bus.S_AXI_BID;
    assign WEIGHT_AXI_BRESP           = weight_bus.S_AXI_BRESP;
    assign WEIGHT_AXI_BVALID          = weight_bus.S_AXI_BVALID;
    assign WEIGHT_AXI_ARREADY         = weight_bus.S_AXI_ARREADY;
    assign WEIGHT_AXI_RID             = weight_bus.S_AXI_RID;
    assign WEIGHT_AXI_RDATA           = weight_bus.S_AXI_RDATA;
    assign WEIGHT_AXI_RRESP           = weight_bus.S_AXI_RRESP;
    assign WEIGHT_AXI_RLAST           = weight_bus.S_AXI_RLAST;
    assign WEIGHT_AXI_RVALID          = weight_bus.S_AXI_RVALID;

    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(AXI_BUS_ADDRESS_WIDTH)
    ) data_bus ();
    virtual s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(AXI_BUS_ADDRESS_WIDTH)
    ) v_data_bus;
    
        // Comment out this v bus bc errors and stuff and seemed to be not needed
    //assign v_data_bus = data_bus;
    assign data_bus.S_AXI_ACLK      = S_AXI_ACLK;
    assign data_bus.S_AXI_ARESETN   = S_AXI_ARESETN;
    assign data_bus.S_AXI_AWID      = S_AXI_AWID;
    assign data_bus.S_AXI_AWADDR    = S_AXI_AWADDR;
    assign data_bus.S_AXI_AWLEN     = S_AXI_AWLEN;
    assign data_bus.S_AXI_AWSIZE    = S_AXI_AWSIZE;
    assign data_bus.S_AXI_AWBURST   = S_AXI_AWBURST;
    assign data_bus.S_AXI_AWLOCK    = S_AXI_AWLOCK;
    assign data_bus.S_AXI_AWVALID   = S_AXI_AWVALID;
    assign data_bus.S_AXI_WDATA     = S_AXI_WDATA;
    assign data_bus.S_AXI_WSTRB     = S_AXI_WSTRB;
    assign data_bus.S_AXI_WLAST     = S_AXI_WLAST;
    assign data_bus.S_AXI_WVALID    = S_AXI_WVALID;
    assign data_bus.S_AXI_BREADY    = S_AXI_BREADY;
    assign data_bus.S_AXI_ARID      = S_AXI_ARID;
    assign data_bus.S_AXI_ARADDR    = S_AXI_ARADDR;
    assign data_bus.S_AXI_ARLEN     = S_AXI_ARLEN;
    assign data_bus.S_AXI_ARSIZE    = S_AXI_ARSIZE;
    assign data_bus.S_AXI_ARBURST   = S_AXI_ARBURST;
    assign data_bus.S_AXI_ARLOCK    = S_AXI_ARLOCK;
    assign data_bus.S_AXI_ARVALID   = S_AXI_ARVALID;
    assign data_bus.S_AXI_RREADY    = S_AXI_RREADY;
    assign S_AXI_AWREADY            = data_bus.S_AXI_AWREADY;
    assign S_AXI_WREADY             = data_bus.S_AXI_WREADY;
    assign S_AXI_BID                = data_bus.S_AXI_BID;
    assign S_AXI_BRESP              = data_bus.S_AXI_BRESP;
    assign S_AXI_BVALID             = data_bus.S_AXI_BVALID;
    assign S_AXI_ARREADY            = data_bus.S_AXI_ARREADY;
    assign S_AXI_RID                = data_bus.S_AXI_RID;
    assign S_AXI_RDATA              = data_bus.S_AXI_RDATA;
    assign S_AXI_RRESP              = data_bus.S_AXI_RRESP;
    assign S_AXI_RLAST              = data_bus.S_AXI_RLAST;
    assign S_AXI_RVALID             = data_bus.S_AXI_RVALID;

    s_axi_lite_bus #(
        .C_S_AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(CONTROL_AXI_ADDR_WIDTH)
    ) control_bus ();
    virtual s_axi_lite_bus #(
        .C_S_AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(CONTROL_AXI_ADDR_WIDTH)
    ) v_control_bus;
    
        // Comment out this v bus bc errors and stuff and seemed to be not needed
   // assign v_control_bus = control_bus;
    assign control_bus.S_AXI_ACLK       = CONTROL_AXI_ACLK;
    assign control_bus.S_AXI_ARESETN    = CONTROL_AXI_ARESETN;
    assign control_bus.S_AXI_AWADDR     = CONTROL_AXI_AWADDR;
    assign control_bus.S_AXI_AWVALID    = CONTROL_AXI_AWVALID;
    assign control_bus.S_AXI_WDATA      = CONTROL_AXI_WDATA;
    assign control_bus.S_AXI_WSTRB      = CONTROL_AXI_WSTRB;
    assign control_bus.S_AXI_WVALID     = CONTROL_AXI_WVALID;
    assign control_bus.S_AXI_BREADY     = CONTROL_AXI_BREADY;
    assign control_bus.S_AXI_ARADDR     = CONTROL_AXI_ARADDR;
    assign control_bus.S_AXI_ARVALID    = CONTROL_AXI_ARVALID;
    assign control_bus.S_AXI_RREADY     = CONTROL_AXI_RREADY;  
    assign CONTROL_AXI_AWREADY          = control_bus.S_AXI_AWREADY;
    assign CONTROL_AXI_WREADY           = control_bus.S_AXI_WREADY;
    assign CONTROL_AXI_BRESP            = control_bus.S_AXI_BRESP;
    assign CONTROL_AXI_BVALID           = control_bus.S_AXI_BVALID;
    assign CONTROL_AXI_ARREADY          = control_bus.S_AXI_ARREADY;
    assign CONTROL_AXI_RDATA            = control_bus.S_AXI_RDATA;
    assign CONTROL_AXI_RRESP            = control_bus.S_AXI_RRESP;
    assign CONTROL_AXI_RVALID           = control_bus.S_AXI_RVALID;

    assign WEIGHT_AXI_ACLK      = clk;  
    assign WEIGHT_AXI_ARESETN   = resetn;
    assign S_AXI_ACLK           = clk;  
    assign S_AXI_ARESETN        = resetn;
    assign CONTROL_AXI_ACLK     = clk;  
    assign CONTROL_AXI_ARESETN  = resetn;

//     task create_export_file(
//             input string file_name
//             );
//             string txt_file;
//             int fd1;
//             txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
//             $display("%s", txt_file);
//             fd1 = $fopen(txt_file,"w"); 
//             $fwrite(fd1,"/* \n\
// *   Institute of Neuroinformatics - Sensors Group - UZH/ETHz \n\
// *   Title: \n\
// *   Date:   18.03.2022 \n\
// *   Author: hasan \n\
// *   Description: \n\
// */ \n\
// \n\
// #ifndef SRC_TEST_NEURAL_NET_H_ \n\
// #define SRC_TEST_NEURAL_NET_H_ \n\ \n\ 
// #define LAYER_0_INPUT_COLS  %0d \n\
// #define LAYER_0_INPUT_ROWS  %0d \n\
// #define LAYER_0_INPUT_CH    %0d \n\
// #define LAYER_0_KERNEL_K    %0d \n\
// #define LAYER_0_OUTPUT_COLS %0d \n\
// #define LAYER_0_OUTPUT_ROWS %0d \n\
// #define LAYER_0_OUTPUT_CH   %0d \n\ \n\ 
// #define LAYER_1_KERNEL_K    %0d \n\
// #define LAYER_1_OUTPUT_COLS %0d \n\
// #define LAYER_1_OUTPUT_ROWS %0d \n\
// #define LAYER_1_OUTPUT_CH   %0d \n\ \n\ 
// uint32_t number_of_pre_reg = %0d;\n\
// uint32_t number_of_intra_reg = %0d;\n\ \n\ 
// ", 
//         ACTIVATION_COLS, 
//         ACTIVATION_ROWS, 
//         ACTIVATION_CHANNELS, 
//         LAYER_0_KERNEL_K, 
//         LAYER_0_NUMBER_OF_OUTPUT_COLS, 
//         LAYER_0_NUMBER_OF_OUTPUT_ROWS, 
//         LAYER_0_NUMBER_OF_OUTPUT_CH,
//         LAYER_1_KERNEL_K, 
//         LAYER_1_NUMBER_OF_OUTPUT_COLS, 
//         LAYER_1_NUMBER_OF_OUTPUT_ROWS, 
//         LAYER_1_NUMBER_OF_OUTPUT_CH,
//         NUMBER_OF_PRE_REGISTERS, 
//         NUMBER_OF_INTRA_REGISTERS
//         );
//             $fclose(fd1);
//             return;
//     endtask

    task create_export_file(
            input string file_name
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("%s", txt_file);
            fd1 = $fopen(txt_file,"w"); 
            $fwrite(fd1,"/* \n\ *   Institute of Neuroinformatics - Sensors Group - UZH/ETHz \n\ *   Title: \n\ *   Date:   18.03.2022 \n\ *   Author: hasan \n\ *   Description: \n\ */ \n\ \n\ #ifndef SRC_TEST_NEURAL_NET_H_ \n\ #define SRC_TEST_NEURAL_NET_H_ \n\ \n\ #define LAYER_0_INPUT_COLS  %0d \n\ #define LAYER_0_INPUT_ROWS  %0d \n\ #define LAYER_0_INPUT_CH    %0d \n\ uint32_t number_of_pre_reg = %0d;\n\ uint32_t number_of_intra_reg = %0d;\n\ \n\ ",         ACTIVATION_COLS,   ACTIVATION_ROWS,         ACTIVATION_CHANNELS,         NUMBER_OF_PRE_REGISTERS,         NUMBER_OF_INTRA_REGISTERS   );
            
            $fclose(fd1);
            return;
    endtask

    task close_export_file(
        input string file_name
        );
        string txt_file;
        int fd1;
        txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
        fd1 = $fopen(txt_file,"a"); 
        $fwrite(fd1,"\n #endif /* SRC_TEST_NEURAL_NET_H_ */ \n\ ");
        $fclose(fd1);
        return;
    endtask

    NVP_v1_top dut ( 
        .clk                        (clk),
        .resetn                     (resetn),
        .i_data_bus                 (data_bus),
        .i_weight_bus               (weight_bus),
        .i_control_bus              (control_bus),
        .o_next_command_interrupt   (next_command_interrupt),
        .o_output_line_stored       (output_line_stored)
    );

    always begin
        #(CLOCK_PERIOD/2) clk = ~clk;
    end

    //let max(a,b) = (a > b) ? a : b;

    initial begin 
		
        $display("data_bus, AXI_BUS_BIT_WIDTH=%0d, AXI_BUS_ADDRESS_WIDTH=%0d", AXI_BUS_BIT_WIDTH, AXI_BUS_ADDRESS_WIDTH);
        $display("weight_bus, WEIGHT_AXI_BUS_BIT_WIDTH=%0d, WEIGHT_AXI_BUS_ADDRESS_WIDTH=%0d", WEIGHT_AXI_BUS_BIT_WIDTH, WEIGHT_AXI_BUS_ADDRESS_WIDTH);
        $display("control_bus, CONTROL_AXI_DATA_WIDTH=%0d, CONTROL_AXI_ADDR_WIDTH=%0d", CONTROL_AXI_DATA_WIDTH, CONTROL_AXI_ADDR_WIDTH);


        #CLOCK_PERIOD;
        resetn    = 0;

        // Don't forget to update these commands according to the number of layers in the neural network. 
        layer_0 = new();
        layer_0.create();
        layer_1 = new();
        layer_1.create();
        layer_2 = new();
        layer_2.create();
        layer_3 = new();
        layer_3.create();
        layer_4 = new();
        layer_4.create();
        layer_5 = new();
        layer_5.create();
        layer_6 = new();
        layer_6.create();
        layer_7 = new();
        layer_7.create();
        layer_8 = new();
        layer_8.create();
        layer_9 = new();
        layer_9.create();
        layer_10 = new();
        layer_10.create();
        layer_11 = new();
        layer_11.create();
        layer_12 = new();
        layer_12.create();
        layer_13 = new();
        layer_13.create();
        // layer_14 = new();
        // layer_14.create();
        create_export_file(SDK_FILE_NAME);

        #CLOCK_PERIOD;
        layer_0.read_input();
        layer_0.read_weights(); 
        layer_1.read_weights(); 
        layer_2.read_weights(); 
        layer_3.read_weights(); 
        layer_4.read_weights(); 
        layer_5.read_weights(); 
        layer_6.read_weights(); 
        layer_7.read_weights(); 
        layer_8.read_weights(); 
        layer_9.read_weights(); 
        layer_10.read_weights(); 
        layer_11.read_weights(); 
        layer_12.read_weights(); 
        layer_13.read_weights(); 
        // layer_14.read_weights(); 
        
        layer_0.read_ground_truth_outputs(); 
        layer_1.read_ground_truth_outputs(); 
        layer_2.read_ground_truth_outputs(); 
        layer_3.read_ground_truth_outputs(); 
        layer_4.read_ground_truth_outputs(); 
        layer_5.read_ground_truth_outputs(); 
        layer_6.read_ground_truth_outputs(); 
        layer_7.read_ground_truth_outputs(); 
        layer_8.read_ground_truth_outputs(); 
        layer_9.read_ground_truth_outputs(); 
        layer_10.read_ground_truth_outputs(); 
        layer_11.read_ground_truth_outputs(); 
        layer_12.read_ground_truth_outputs(); 
        layer_13.read_ground_truth_outputs(); 
        // layer_14.read_ground_truth_outputs(); 

        #CLOCK_PERIOD;
        layer_0.export_activations(SDK_FILE_NAME);
        layer_0.export_weights(SDK_FILE_NAME);
        layer_1.export_weights(SDK_FILE_NAME);
        layer_2.export_weights(SDK_FILE_NAME);
        layer_3.export_weights(SDK_FILE_NAME);
        layer_4.export_weights(SDK_FILE_NAME);
        layer_5.export_weights(SDK_FILE_NAME);
        layer_6.export_weights(SDK_FILE_NAME);
        layer_7.export_weights(SDK_FILE_NAME);
        layer_8.export_weights(SDK_FILE_NAME);
        layer_9.export_weights(SDK_FILE_NAME);
        layer_10.export_weights(SDK_FILE_NAME);
        layer_11.export_weights(SDK_FILE_NAME);
        layer_12.export_weights(SDK_FILE_NAME);
        layer_13.export_weights(SDK_FILE_NAME);
        // layer_14.export_weights(SDK_FILE_NAME);
        
        #CLOCK_PERIOD;
        resetn = 1;
        #CLOCK_PERIOD;

        // $display("%d", signed'(-1)); 
        // $display("%d", signed'(-1)>255); 

        //----------------------
        // Generated code start
        //----------------------

$display("execute layer_0");
    layer_0.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_0.validate_outputs();

        
    $display("execute layer_1");
    layer_1.row_i = layer_0.output_row_i;
    // layer_1.row_i = layer_0.ground_truth_output_row_i;
    layer_1.row_i_number_of_entries = layer_0.output_row_i_number_of_entries;
    layer_1.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_1.validate_outputs();

        
    $display("execute layer_2");
    layer_2.row_i = layer_1.output_row_i;
    // layer_2.row_i = layer_1.ground_truth_output_row_i;
    layer_2.row_i_number_of_entries = layer_1.output_row_i_number_of_entries;
    layer_2.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_2.validate_outputs();

        
    $display("execute layer_3");
    layer_3.row_i = layer_2.output_row_i;
    // layer_3.row_i = layer_2.ground_truth_output_row_i;
    layer_3.row_i_number_of_entries = layer_2.output_row_i_number_of_entries;
    layer_3.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_3.validate_outputs();

        
    $display("execute layer_4");
    layer_4.row_i = layer_3.output_row_i;
    // layer_4.row_i = layer_3.ground_truth_output_row_i;
    layer_4.row_i_number_of_entries = layer_3.output_row_i_number_of_entries;
    layer_4.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_4.validate_outputs();

        
    $display("execute layer_5");
    layer_5.row_i = layer_4.output_row_i;
    // layer_5.row_i = layer_4.ground_truth_output_row_i;
    layer_5.row_i_number_of_entries = layer_4.output_row_i_number_of_entries;
    layer_5.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_5.validate_outputs();

        
    $display("execute layer_6");
    layer_6.row_i = layer_5.output_row_i;
    // layer_6.row_i = layer_5.ground_truth_output_row_i;
    layer_6.row_i_number_of_entries = layer_5.output_row_i_number_of_entries;
    layer_6.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_6.validate_outputs();

        
    $display("execute layer_7");
    layer_7.row_i = layer_6.output_row_i;
    // layer_7.row_i = layer_6.ground_truth_output_row_i;
    layer_7.row_i_number_of_entries = layer_6.output_row_i_number_of_entries;
    layer_7.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_7.validate_outputs();

        
    $display("execute layer_8");
    layer_8.row_i = layer_7.output_row_i;
    // layer_8.row_i = layer_7.ground_truth_output_row_i;
    layer_8.row_i_number_of_entries = layer_7.output_row_i_number_of_entries;
    layer_8.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_8.validate_outputs();

        
    $display("execute layer_9");
    layer_9.row_i = layer_8.output_row_i;
    // layer_9.row_i = layer_8.ground_truth_output_row_i;
    layer_9.row_i_number_of_entries = layer_8.output_row_i_number_of_entries;
    layer_9.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_9.validate_outputs();

        
    $display("execute layer_10");
    layer_10.row_i = layer_9.output_row_i;
    // layer_10.row_i = layer_9.ground_truth_output_row_i;
    layer_10.row_i_number_of_entries = layer_9.output_row_i_number_of_entries;
    layer_10.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_10.validate_outputs();

        
    $display("execute layer_11");
    layer_11.row_i = layer_10.output_row_i;
    // layer_11.row_i = layer_10.ground_truth_output_row_i;
    layer_11.row_i_number_of_entries = layer_10.output_row_i_number_of_entries;
    layer_11.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_11.validate_outputs();

        
    $display("execute layer_12");
    layer_12.row_i = layer_11.output_row_i;
    // layer_12.row_i = layer_11.ground_truth_output_row_i;
    layer_12.row_i_number_of_entries = layer_11.output_row_i_number_of_entries;
    layer_12.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_12.validate_outputs();

        
    $display("execute layer_13");
    layer_13.row_i = layer_12.output_row_i;
    // layer_13.row_i = layer_12.ground_truth_output_row_i;
    layer_13.row_i_number_of_entries = layer_12.output_row_i_number_of_entries;
    layer_13.execute(
            .clk                    (clk),
            .data_bus               (data_bus),
            .weight_bus             (weight_bus),
            .control_bus            (control_bus),
            .next_command_interrupt (next_command_interrupt),
            .output_line_stored     (output_line_stored)
        );
    layer_13.validate_outputs();

        
    // $display("execute layer_14");
    // layer_14.row_i = layer_13.output_row_i;
    // // layer_14.row_i = layer_13.ground_truth_output_row_i;
    // layer_14.row_i_number_of_entries = layer_13.output_row_i_number_of_entries;
    // layer_14.execute(
    //         .clk                    (clk),
    //         .data_bus               (data_bus),
    //         .weight_bus             (weight_bus),
    //         .control_bus            (control_bus),
    //         .next_command_interrupt (next_command_interrupt),
    //         .output_line_stored     (output_line_stored)
    //     );
    // layer_14.validate_outputs();

        //----------------------
        // Generated code end
        //----------------------
        

        // !! Update me !!
        layer_0.export_output_activations(SDK_FILE_NAME, 1); // export_all = 1. This exports the ground truth values
        layer_1.export_output_activations(SDK_FILE_NAME, 1);
        layer_2.export_output_activations(SDK_FILE_NAME, 1);
        layer_3.export_output_activations(SDK_FILE_NAME, 1);
        layer_4.export_output_activations(SDK_FILE_NAME, 1);
        layer_5.export_output_activations(SDK_FILE_NAME, 1);
        layer_6.export_output_activations(SDK_FILE_NAME, 1);
        layer_7.export_output_activations(SDK_FILE_NAME, 1);
        layer_8.export_output_activations(SDK_FILE_NAME, 1);
        layer_9.export_output_activations(SDK_FILE_NAME, 1);
        layer_10.export_output_activations(SDK_FILE_NAME, 1);
        layer_11.export_output_activations(SDK_FILE_NAME, 1);
        layer_12.export_output_activations(SDK_FILE_NAME, 1);
        layer_13.export_output_activations(SDK_FILE_NAME, 1);
        // layer_14.export_output_activations(SDK_FILE_NAME, 1);

        close_export_file(SDK_FILE_NAME);
        $display("finished simulation.");
        
    end

 
endmodule
