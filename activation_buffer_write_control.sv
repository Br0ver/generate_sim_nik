/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Buffer Write Control
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module activation_buffer_write_control #(   
    parameter int REGISTER_WIDTH                        = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS                   = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int ACTIVATION_BANK_BIT_WIDTH           = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH               = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT          = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS     = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    parameter  int OUTPUT_WRITER_ADDRESS_BIT_WIDTH       = NVP_v1_constants::OUTPUT_WRITER_ADDRESS_BIT_WIDTH,

    parameter int AXI_BUS_BIT_WIDTH                     = NVP_v1_constants::AXI_BUS_BIT_WIDTH,
    parameter int AXI_BUS_ADDRESS_WIDTH                 = NVP_v1_constants::AXI_BUS_ADDRESS_WIDTH,
    localparam int BANK_SELECTION_BIT_WIDTH    = $clog2(ACTIVATION_BUFFER_BANK_COUNT),
    localparam int LINE_BUFFER_SELECTION_BIT_WIDTH          = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS),
    localparam int LINE_BUFFER_ADDRESS_BIT_WIDTH          = $clog2(ACTIVATION_LINE_BUFFER_DEPTH)

)(
    input logic                                         clk,
    input logic                                         resetn,
    s_axi_bus                                           i_data_bus,
    // s_axis_lite_bus                                     i_weight_bus,
    register_file_if                                    reg_file,
    activation_buffer_control_if                        activation_buffer_ctrl,
    // axis_to_weight_memory_if                            axis_to_weight_memory,
    input logic [ACTIVATION_BANK_BIT_WIDTH-1:0]         i_output_array,
    input logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]   i_output_address,
    input logic                                         i_output_valid
);

    // --------------------------------------
    // ------ Stream writer control - output data storing TODO:: fixme
	// --------------------------------------
    // stream_writer_control #(   
    //     .REGISTER_WIDTH                        
    //     .NUMBER_OF_REGISTERS                   
    //     .ACTIVATION_BANK_BIT_WIDTH             
    //     .ACTIVATION_LINE_BUFFER_DEPTH          
    //     .ACTIVATION_BUFFER_BANK_COUNT          
    //     .NUMBER_OF_ACTIVATION_LINE_BUFFERS     
    // ) stream_writer_control_unit (
    //     .clk,
    //     .resetn,
    //     .i_weight_bus,
    //     .reg_file,
    //     .activation_buffer_ctrl,
    //     .axis_to_weight_memory
    // );

    // // --------------------------------------
    // // ------ Weight AXIS writer control
	// // --------------------------------------
    // always_comb begin
    //     axis_to_weight_memory.data     = i_weight_bus.S_AXIS_TDATA;
    //     axis_to_weight_memory.valid    = i_weight_bus.S_AXIS_TVALID;
    //     axis_to_weight_memory.last     = i_weight_bus.S_AXIS_TLAST;
    //     i_weight_bus.S_AXIS_TREADY     = axis_to_weight_memory.ready; 
    // end


    // --------------------------------------
    // ------ Data AXI writer control
	// --------------------------------------
    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(AXI_BUS_ADDRESS_WIDTH)
    ) axi_write_channel ();
        always_comb axi_write_channel.S_AXI_ACLK     = i_data_bus.S_AXI_ACLK;
        always_comb axi_write_channel.S_AXI_ARESETN  = i_data_bus.S_AXI_ARESETN;
        // Assign the write channel
        always_comb axi_write_channel.S_AXI_AWID     = i_data_bus.S_AXI_AWID;
        always_comb axi_write_channel.S_AXI_AWADDR   = i_data_bus.S_AXI_AWADDR;
        always_comb axi_write_channel.S_AXI_AWLEN    = i_data_bus.S_AXI_AWLEN;
        always_comb axi_write_channel.S_AXI_AWSIZE   = i_data_bus.S_AXI_AWSIZE;
        always_comb axi_write_channel.S_AXI_AWBURST  = i_data_bus.S_AXI_AWBURST;
        always_comb axi_write_channel.S_AXI_AWLOCK   = i_data_bus.S_AXI_AWLOCK;
        always_comb axi_write_channel.S_AXI_AWVALID  = i_data_bus.S_AXI_AWVALID;
        always_comb axi_write_channel.S_AXI_WDATA    = i_data_bus.S_AXI_WDATA;
        always_comb axi_write_channel.S_AXI_WSTRB    = i_data_bus.S_AXI_WSTRB;
        always_comb axi_write_channel.S_AXI_WLAST    = i_data_bus.S_AXI_WLAST;
        always_comb axi_write_channel.S_AXI_WVALID   = i_data_bus.S_AXI_WVALID;
        always_comb axi_write_channel.S_AXI_BREADY   = i_data_bus.S_AXI_BREADY;
        always_comb i_data_bus.S_AXI_AWREADY         = axi_write_channel.S_AXI_AWREADY;
        always_comb i_data_bus.S_AXI_WREADY          = axi_write_channel.S_AXI_WREADY;
        always_comb i_data_bus.S_AXI_BID             = axi_write_channel.S_AXI_BID;
        always_comb i_data_bus.S_AXI_BRESP           = axi_write_channel.S_AXI_BRESP;
        always_comb i_data_bus.S_AXI_BVALID          = axi_write_channel.S_AXI_BVALID;
        // Leave the read channel unconnected
        always_comb axi_write_channel.S_AXI_ARID     = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARADDR   = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARLEN    = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARSIZE   = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARBURST  = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARLOCK   = 0;
        always_comb axi_write_channel.S_AXI_ARVALID  = 0;
        // always_comb axi_write_channel.S_AXI_ARREADY  = '{default: 1'b0}; // 
        // always_comb axi_write_channel.S_AXI_RID      = '{default: 1'b0}; // 
        // always_comb axi_write_channel.S_AXI_RDATA    = '{default: 1'b0}; // 
        // always_comb axi_write_channel.S_AXI_RRESP    = '{default: 1'b0}; // 
        // always_comb axi_write_channel.S_AXI_RLAST    = '{default: 1'b0}; // 
        // always_comb axi_write_channel.S_AXI_RVALID   = '{default: 1'b0}; // 
        always_comb axi_write_channel.S_AXI_RREADY   = 0;
    logic                                                           axi_write_enable;
    logic                                                           axi_write_write_enable;
    logic[AXI_BUS_BIT_WIDTH/8-1:0]                                  axi_write_write_strobes; // Write strobes are byte wise
    logic[AXI_BUS_BIT_WIDTH-1:0]                                    axi_write_data;
    logic[AXI_BUS_ADDRESS_WIDTH-$clog2(AXI_BUS_BIT_WIDTH/8)-1:0]    axi_write_address; // Addresses one word, even though AXI addresses bytes (the address is converted)
    // logic[C_S_AXI_DATA_WIDTH-1:0]                                i_data;
    axi_memory_fsm #(
        .C_S_AXI_DATA_WIDTH (AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH (AXI_BUS_ADDRESS_WIDTH),
        .RAM_OUTPUT_PIPES   (1) // Defines the latency of the memory output
    ) axi_write_bridge (
        .clk                (clk),
        .axi_bus            (axi_write_channel),    
        .o_enable           (axi_write_enable),    
        .o_write_enable     (axi_write_write_enable),        
        .o_write_strobes    (axi_write_write_strobes),                
        .o_data             (axi_write_data),
        .o_address          (axi_write_address),    
        .i_data             ()
    );

    // --------------------------------------
    // ------ Write control (AXI and output write scheduling/priority)
	// --------------------------------------
    logic [BANK_SELECTION_BIT_WIDTH-1:0]        stream_writer_bank_selection_bits; 
    logic [LINE_BUFFER_SELECTION_BIT_WIDTH-1:0] stream_writer_line_buffer_selection_bits;
    logic [LINE_BUFFER_ADDRESS_BIT_WIDTH-1:0]   stream_writer_write_address_converted; 
    always_comb stream_writer_bank_selection_bits         = i_output_address[BANK_SELECTION_BIT_WIDTH-1:0];
    always_comb stream_writer_write_address_converted     = i_output_address[LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_ADDRESS_BIT_WIDTH];
    always_comb stream_writer_line_buffer_selection_bits  = i_output_address[LINE_BUFFER_SELECTION_BIT_WIDTH+LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_SELECTION_BIT_WIDTH];
            
        // logic [ACTIVATION_BANK_BIT_WIDTH-1:0]         output_array;
        // logic [OUTPUT_WRITER_ADDRESS_BIT_WIDTH-1:0]   output_address;
        // logic                                         output_valid;

    logic [BANK_SELECTION_BIT_WIDTH-1:0]        axi_bank_selection_bits; 
    logic [LINE_BUFFER_SELECTION_BIT_WIDTH-1:0] axi_line_buffer_selection_bits;
    logic [LINE_BUFFER_ADDRESS_BIT_WIDTH-1:0]   axi_write_address_converted; 
    always_comb axi_bank_selection_bits         = axi_write_address[BANK_SELECTION_BIT_WIDTH-1:0];
    always_comb axi_write_address_converted     = axi_write_address[LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_ADDRESS_BIT_WIDTH];
    always_comb axi_line_buffer_selection_bits  = axi_write_address[LINE_BUFFER_SELECTION_BIT_WIDTH+LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_SELECTION_BIT_WIDTH];

    always_comb begin       //TODO:: fixme: add output write control  
        // activation_buffer_ctrl.write_port_data_in   = axi_write_data;
        // activation_buffer_ctrl.write_port_addr      = axi_write_address_converted;  

        // for (int i=0; i<ACTIVATION_BUFFER_BANK_COUNT; i++) begin
        //     if(axi_bank_selection_bits==i) begin
        //         activation_buffer_ctrl.write_port_wen[i] = 1;
        //     end
        //     else begin
        //         activation_buffer_ctrl.write_port_wen[i] = 0;
        //     end
        // end

        // for (int i=0; i<NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
        //     if(axi_line_buffer_selection_bits==i) begin
        //         activation_buffer_ctrl.write_port_enable[i] = axi_write_enable;
        //     end
        //     else begin
        //         activation_buffer_ctrl.write_port_enable[i] = 0;
        //     end
        // end


        // for (int i=0; i<NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
        //     if(stream_writer_line_buffer_selection_bits==i) begin
        //         activation_buffer_ctrl.write_port_data_in[i]    = i_output_array;
        //         activation_buffer_ctrl.write_port_addr[i]       = stream_writer_write_address_converted;  
        //         activation_buffer_ctrl.write_port_enable[i]     = i_output_valid;
        //         for (int j=0; j<ACTIVATION_BUFFER_BANK_COUNT; j++) begin
        //             if(stream_writer_bank_selection_bits==j) begin
        //                 activation_buffer_ctrl.write_port_wen[i][j] = 1;
        //             end
        //             else begin
        //                 activation_buffer_ctrl.write_port_wen[i][j] = 0;
        //             end
        //         end
        //     end
        //     else begin
        //         if(axi_line_buffer_selection_bits==i) begin
        //             activation_buffer_ctrl.write_port_data_in[i]    = axi_write_data;
        //             activation_buffer_ctrl.write_port_addr[i]       = axi_write_address_converted;  
        //             activation_buffer_ctrl.write_port_enable[i]     = axi_write_enable;
        //             for (int j=0; j<ACTIVATION_BUFFER_BANK_COUNT; j++) begin
        //                 if(axi_bank_selection_bits==j) begin
        //                     activation_buffer_ctrl.write_port_wen[i][j] = 1;
        //                 end
        //                 else begin
        //                     activation_buffer_ctrl.write_port_wen[i][j] = 0;
        //                 end
        //             end
        //         end
        //         else begin
        //             activation_buffer_ctrl.write_port_data_in[i]    = '0;
        //             activation_buffer_ctrl.write_port_addr[i]       = '0;
        //             activation_buffer_ctrl.write_port_enable[i]     = '0;
        //             activation_buffer_ctrl.write_port_wen[i]        = '0;
        //         end
        //     end
        // end

        for (int i=0; i<NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
            if(axi_line_buffer_selection_bits==i) begin
                activation_buffer_ctrl.write_port_data_in[i]    = axi_write_data;
                activation_buffer_ctrl.write_port_addr[i]       = axi_write_address_converted;  
                activation_buffer_ctrl.write_port_enable[i]     = axi_write_enable;
                for (int j=0; j<ACTIVATION_BUFFER_BANK_COUNT; j++) begin
                    if(axi_bank_selection_bits==j) begin
                        activation_buffer_ctrl.write_port_wen[i][j] = 1;
                    end
                    else begin
                        activation_buffer_ctrl.write_port_wen[i][j] = 0;
                    end
                end
            end
            else begin
                if(stream_writer_line_buffer_selection_bits==i) begin
                    activation_buffer_ctrl.write_port_data_in[i]    = i_output_array;
                    activation_buffer_ctrl.write_port_addr[i]       = stream_writer_write_address_converted;  
                    activation_buffer_ctrl.write_port_enable[i]     = i_output_valid;
                    for (int j=0; j<ACTIVATION_BUFFER_BANK_COUNT; j++) begin
                        if(stream_writer_bank_selection_bits==j) begin
                            activation_buffer_ctrl.write_port_wen[i][j] = 1;
                        end
                        else begin
                            activation_buffer_ctrl.write_port_wen[i][j] = 0;
                        end
                    end
                end
                else begin
                    activation_buffer_ctrl.write_port_data_in[i]    = '0;
                    activation_buffer_ctrl.write_port_addr[i]       = '0;
                    activation_buffer_ctrl.write_port_enable[i]     = '0;
                    activation_buffer_ctrl.write_port_wen[i]        = '0;
                end
            end
        end
        
        
    end

endmodule
