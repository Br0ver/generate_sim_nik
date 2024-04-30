/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Weight Buffer Write Control
*   Date:   14.03.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module weight_buffer_write_control #(   
    parameter  REGISTER_WIDTH                           = NVP_v1_constants::REGISTER_WIDTH,
    parameter  NUMBER_OF_REGISTERS                      = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter  WEIGHT_AXI_BUS_BIT_WIDTH                 = NVP_v1_constants::WEIGHT_AXI_BUS_BIT_WIDTH,
    parameter  WEIGHT_AXI_BUS_ADDRESS_WIDTH             = NVP_v1_constants::WEIGHT_AXI_BUS_ADDRESS_WIDTH,
    parameter  WEIGHT_BANK_BIT_WIDTH                    = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH,
    parameter  WEIGHT_LINE_BUFFER_DEPTH                 = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter  WEIGHT_BUFFER_BANK_COUNT                 = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter  NUMBER_OF_WEIGHT_LINE_BUFFERS            = NVP_v1_constants::NUMBER_OF_WEIGHT_LINE_BUFFERS,
    parameter  BIAS_BUFFER_BANK_COUNT                   = NVP_v1_constants::BIAS_BUFFER_BANK_COUNT,
    parameter  BIAS_LINE_BUFFER_DEPTH                   = NVP_v1_constants::BIAS_LINE_BUFFER_DEPTH,
    localparam WEIGHT_BANK_SELECTION_BIT_WIDTH          = $clog2(WEIGHT_BUFFER_BANK_COUNT),
    localparam WEIGHT_LINE_BUFFER_SELECTION_BIT_WIDTH   = $clog2(NUMBER_OF_WEIGHT_LINE_BUFFERS),
    localparam WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH     = $clog2(WEIGHT_LINE_BUFFER_DEPTH),
    localparam BIAS_LINE_BUFFER_ADDRESS_BIT_WIDTH       = $clog2(BIAS_LINE_BUFFER_DEPTH),
    localparam BIAS_BANK_SELECTION_BIT_WIDTH            = $clog2(BIAS_BUFFER_BANK_COUNT)

)(
    input logic                 clk,
    input logic                 resetn,
    s_axi_bus                   i_weight_bus,
    weight_buffer_control_if    weight_buffer_ctrl
);



    // --------------------------------------
    // ------ Data AXI writer control
	// --------------------------------------
    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(WEIGHT_AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH)
    ) axi_write_channel ();
        always_comb axi_write_channel.S_AXI_ACLK     = i_weight_bus.S_AXI_ACLK;
        always_comb axi_write_channel.S_AXI_ARESETN  = i_weight_bus.S_AXI_ARESETN;
        // Assign the write channel
        always_comb axi_write_channel.S_AXI_AWID     = i_weight_bus.S_AXI_AWID;
        always_comb axi_write_channel.S_AXI_AWADDR   = i_weight_bus.S_AXI_AWADDR;
        always_comb axi_write_channel.S_AXI_AWLEN    = i_weight_bus.S_AXI_AWLEN;
        always_comb axi_write_channel.S_AXI_AWSIZE   = i_weight_bus.S_AXI_AWSIZE;
        always_comb axi_write_channel.S_AXI_AWBURST  = i_weight_bus.S_AXI_AWBURST;
        always_comb axi_write_channel.S_AXI_AWLOCK   = i_weight_bus.S_AXI_AWLOCK;
        always_comb axi_write_channel.S_AXI_AWVALID  = i_weight_bus.S_AXI_AWVALID;
        always_comb axi_write_channel.S_AXI_WDATA    = i_weight_bus.S_AXI_WDATA;
        always_comb axi_write_channel.S_AXI_WSTRB    = i_weight_bus.S_AXI_WSTRB;
        always_comb axi_write_channel.S_AXI_WLAST    = i_weight_bus.S_AXI_WLAST;
        always_comb axi_write_channel.S_AXI_WVALID   = i_weight_bus.S_AXI_WVALID;
        always_comb axi_write_channel.S_AXI_BREADY   = i_weight_bus.S_AXI_BREADY;
        always_comb i_weight_bus.S_AXI_AWREADY         = axi_write_channel.S_AXI_AWREADY;
        always_comb i_weight_bus.S_AXI_WREADY          = axi_write_channel.S_AXI_WREADY;
        always_comb i_weight_bus.S_AXI_BID             = axi_write_channel.S_AXI_BID;
        always_comb i_weight_bus.S_AXI_BRESP           = axi_write_channel.S_AXI_BRESP;
        always_comb i_weight_bus.S_AXI_BVALID          = axi_write_channel.S_AXI_BVALID;
        // Leave the read channel unconnected
        always_comb axi_write_channel.S_AXI_ARID     = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARADDR   = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARLEN    = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARSIZE   = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARBURST  = '{default: 1'b0};
        always_comb axi_write_channel.S_AXI_ARLOCK   = 0;
        always_comb axi_write_channel.S_AXI_ARVALID  = 0;
        always_comb axi_write_channel.S_AXI_RREADY   = 0;
    logic                                                                       axi_write_enable;
    logic                                                                       axi_write_write_enable;
    logic[WEIGHT_AXI_BUS_BIT_WIDTH/8-1:0]                                       axi_write_write_strobes; // Write strobes are byte wise
    logic[WEIGHT_AXI_BUS_BIT_WIDTH-1:0]                                         axi_write_data;
    logic[WEIGHT_AXI_BUS_ADDRESS_WIDTH-$clog2(WEIGHT_AXI_BUS_BIT_WIDTH/8)+1:0]  axi_write_address; // Addresses one word, even though AXI addresses bytes (the address is converted) (TODO:: check "+1" is correct ... bias buffer selection bit)
    // logic[C_S_AXI_DATA_WIDTH-1:0]                                i_data;
    axi_memory_fsm #(
        .C_S_AXI_DATA_WIDTH (WEIGHT_AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH (WEIGHT_AXI_BUS_ADDRESS_WIDTH),
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
    logic [WEIGHT_BANK_SELECTION_BIT_WIDTH-1:0]         axi_bank_selection_bits; 
    logic [WEIGHT_LINE_BUFFER_SELECTION_BIT_WIDTH-1:0]  axi_line_buffer_selection_bits;
    logic [WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH-1:0]    axi_write_address_converted; 
    logic                                               axi_bias_buffer_selection_bit; 
    always_comb axi_bank_selection_bits         = axi_write_address[WEIGHT_BANK_SELECTION_BIT_WIDTH-1:0];
    always_comb axi_write_address_converted     = axi_write_address[WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH+WEIGHT_BANK_SELECTION_BIT_WIDTH-1 -: WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH];
    always_comb axi_line_buffer_selection_bits  = axi_write_address[WEIGHT_LINE_BUFFER_SELECTION_BIT_WIDTH+WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH+WEIGHT_BANK_SELECTION_BIT_WIDTH-1 -: WEIGHT_LINE_BUFFER_SELECTION_BIT_WIDTH];
    always_comb axi_bias_buffer_selection_bit   = axi_write_address[WEIGHT_LINE_BUFFER_SELECTION_BIT_WIDTH+WEIGHT_LINE_BUFFER_ADDRESS_BIT_WIDTH+WEIGHT_BANK_SELECTION_BIT_WIDTH];

    always_comb begin         
        for (int i=0; i<NUMBER_OF_WEIGHT_LINE_BUFFERS; i++) begin
            if(axi_line_buffer_selection_bits==i && axi_bias_buffer_selection_bit==0) begin
                weight_buffer_ctrl.write_port_data_in[i]    = axi_write_data;
                weight_buffer_ctrl.write_port_addr[i]       = axi_write_address_converted;  
                weight_buffer_ctrl.write_port_enable[i]     = axi_write_enable;
                for (int j=0; j<WEIGHT_BUFFER_BANK_COUNT; j++) begin
                    if(axi_bank_selection_bits==j) begin
                        weight_buffer_ctrl.write_port_wen[i][j] = 1;
                    end
                    else begin
                        weight_buffer_ctrl.write_port_wen[i][j] = 0;
                    end
                end
            end
            else begin
                weight_buffer_ctrl.write_port_data_in[i]    = '0;
                weight_buffer_ctrl.write_port_addr[i]       = '0;
                weight_buffer_ctrl.write_port_enable[i]     = '0;
                weight_buffer_ctrl.write_port_wen[i]        = '0;
            end
        end 

        
    end

    logic [BIAS_BANK_SELECTION_BIT_WIDTH-1:0]         axi_bias_bank_selection_bits; 
    logic [BIAS_LINE_BUFFER_ADDRESS_BIT_WIDTH-1:0]    axi_bias_write_address_converted; 
    always_comb axi_bias_bank_selection_bits         = axi_write_address[BIAS_BANK_SELECTION_BIT_WIDTH-1:0];
    always_comb axi_bias_write_address_converted     = axi_write_address[BIAS_LINE_BUFFER_ADDRESS_BIT_WIDTH+BIAS_BANK_SELECTION_BIT_WIDTH-1 -: BIAS_LINE_BUFFER_ADDRESS_BIT_WIDTH];
    always_comb 
    if (axi_bias_buffer_selection_bit==1) begin
        weight_buffer_ctrl.bias_write_port_data_in    = axi_write_data;
        weight_buffer_ctrl.bias_write_port_addr       = axi_bias_write_address_converted;  
        weight_buffer_ctrl.bias_write_port_enable     = axi_write_enable;
        for (int j=0; j<BIAS_BUFFER_BANK_COUNT; j++) begin
            if(axi_bias_bank_selection_bits==j) begin
                weight_buffer_ctrl.bias_write_port_wen[j] = 1;
            end
            else begin
                weight_buffer_ctrl.bias_write_port_wen[j] = 0;
            end
        end
    end
    else begin
        weight_buffer_ctrl.bias_write_port_data_in  = '0;          
        weight_buffer_ctrl.bias_write_port_addr     = '0;
        weight_buffer_ctrl.bias_write_port_enable   = '0;    
        weight_buffer_ctrl.bias_write_port_wen   = '0;    
    end

endmodule
