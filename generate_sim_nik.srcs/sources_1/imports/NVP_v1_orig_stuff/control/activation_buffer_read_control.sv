/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Buffer  Read Control
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module activation_buffer_read_control #(   
    parameter int REGISTER_WIDTH                            = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS                       = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int ACTIVATION_BANK_BIT_WIDTH                 = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH              = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH, 
    parameter int ACTIVATION_BUFFER_BANK_COUNT              = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS         = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    parameter int NUMBER_OF_READ_STREAMS                    = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int AXI_BUS_BIT_WIDTH                         = NVP_v1_constants::AXI_BUS_BIT_WIDTH,
    parameter int AXI_BUS_ADDRESS_WIDTH                     = NVP_v1_constants::AXI_BUS_ADDRESS_WIDTH,
    parameter int STREAM_PING_PONG_BIT_INDEX                = NVP_v1_constants::STREAM_PING_PONG_BIT_INDEX,
    parameter int STREAM_START_ADDRESS_MSB                  = NVP_v1_constants::STREAM_START_ADDRESS_MSB,
    parameter int STREAM_START_ADDRESS_LSB                  = NVP_v1_constants::STREAM_START_ADDRESS_LSB,
    localparam int BANK_SELECTION_BIT_WIDTH                 = $clog2(ACTIVATION_BUFFER_BANK_COUNT),
    localparam int LINE_BUFFER_SELECTION_BIT_WIDTH          = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS),
    localparam int LINE_BUFFER_ADDRESS_BIT_WIDTH            = $clog2(ACTIVATION_LINE_BUFFER_DEPTH),
    localparam int PING                                     = NVP_v1_constants::PING,
    localparam int PONG                                     = NVP_v1_constants::PONG
)(
    input logic                     clk,
    input logic                     resetn,
    s_axi_bus                       i_data_bus,
    register_file_if                latched_reg_file,
    activation_buffer_control_if    activation_buffer_ctrl,
    streamed_data_if                streamed_data,
    output logic debug_stream_read_enable_1,
    output logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]    debug_stream_read_start_address_1,
    output logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]    debug_stream_read_address_1,
    output logic debug_latched_reg_file_start_stream_readers,
    output logic debug_latchedddd_stream_read_enable_1,
    output logic debug_latchedddd_stream_read_enable_2,
    output logic debug_latchedddd_stream_read_enable_3
    
    
);
    
    // --------------------------------------
    // ------ AXI Reader Control
	// --------------------------------------
    s_axi_bus #(
        .C_S_AXI_ID_WIDTH(1),
        .C_S_AXI_DATA_WIDTH(AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH(AXI_BUS_ADDRESS_WIDTH)
    ) axi_read_channel ();
        always_comb axi_read_channel.S_AXI_ACLK     = i_data_bus.S_AXI_ACLK;
        always_comb axi_read_channel.S_AXI_ARESETN  = i_data_bus.S_AXI_ARESETN;
        // Leave the write channel unconnected
        always_comb axi_read_channel.S_AXI_AWID     = '{default: 1'b0};
        always_comb axi_read_channel.S_AXI_AWADDR   = '{default: 1'b0};
        always_comb axi_read_channel.S_AXI_AWLEN    = '{default: 1'b0};
        always_comb axi_read_channel.S_AXI_AWSIZE   = '{default: 1'b0};
        always_comb axi_read_channel.S_AXI_AWBURST  = '{default: 1'b0};
        always_comb axi_read_channel.S_AXI_AWLOCK   = 0;
        always_comb axi_read_channel.S_AXI_AWVALID  = 0;
        always_comb axi_read_channel.S_AXI_WDATA    = 0;
        always_comb axi_read_channel.S_AXI_WSTRB    = 0;
        always_comb axi_read_channel.S_AXI_WLAST    = 0;
        always_comb axi_read_channel.S_AXI_WVALID   = 0;
        // always_comb axi_read_channel.S_AXI_AWREADY  = '{default: 1'b0}; //
        // always_comb axi_read_channel.S_AXI_WREADY   = '{default: 1'b0}; //
        // always_comb axi_read_channel.S_AXI_BID      = '{default: 1'b0}; //
        // always_comb axi_read_channel.S_AXI_BRESP    = '{default: 1'b0}; //
        // always_comb axi_read_channel.S_AXI_BVALID   = '{default: 1'b0}; //
        always_comb axi_read_channel.S_AXI_BREADY   = 0;
        // Assign the read channel 
        always_comb axi_read_channel.S_AXI_ARID     = i_data_bus.S_AXI_ARID;
        always_comb axi_read_channel.S_AXI_ARADDR   = i_data_bus.S_AXI_ARADDR;
        always_comb axi_read_channel.S_AXI_ARLEN    = i_data_bus.S_AXI_ARLEN;
        always_comb axi_read_channel.S_AXI_ARSIZE   = i_data_bus.S_AXI_ARSIZE;
        always_comb axi_read_channel.S_AXI_ARBURST  = i_data_bus.S_AXI_ARBURST;
        always_comb axi_read_channel.S_AXI_ARLOCK   = i_data_bus.S_AXI_ARLOCK;
        always_comb axi_read_channel.S_AXI_ARVALID  = i_data_bus.S_AXI_ARVALID;
        always_comb axi_read_channel.S_AXI_RREADY   = i_data_bus.S_AXI_RREADY;

        always_comb i_data_bus.S_AXI_ARREADY        = axi_read_channel.S_AXI_ARREADY;
        always_comb i_data_bus.S_AXI_RID            = axi_read_channel.S_AXI_RID;
        always_comb i_data_bus.S_AXI_RDATA          = axi_read_channel.S_AXI_RDATA;
        always_comb i_data_bus.S_AXI_RRESP          = axi_read_channel.S_AXI_RRESP;
        always_comb i_data_bus.S_AXI_RLAST          = axi_read_channel.S_AXI_RLAST;
        always_comb i_data_bus.S_AXI_RVALID         = axi_read_channel.S_AXI_RVALID;
    logic                                                           axi_read_enable;
    logic[AXI_BUS_ADDRESS_WIDTH-$clog2(AXI_BUS_BIT_WIDTH/8)-1:0]    axi_read_address; // Addresses one word, even though AXI addresses bytes (the address is converted)
    logic[AXI_BUS_BIT_WIDTH-1:0]                                    axi_read_data_in;
    axi_memory_fsm #(
        .C_S_AXI_DATA_WIDTH (AXI_BUS_BIT_WIDTH),
        .C_S_AXI_ADDR_WIDTH (AXI_BUS_ADDRESS_WIDTH),
        .RAM_OUTPUT_PIPES   (1) // Defines the latency of the memory output // TODO: check me... why is this correct?
    ) axi_read_bridge ( 
        .clk                (clk),
        .axi_bus            (axi_read_channel),    
        .o_enable           (axi_read_enable),    
        .o_write_enable     (),        
        .o_write_strobes    (),                
        .o_data             (),
        .o_address          (axi_read_address),    
        .i_data             (axi_read_data_in)
    );


    // --------------------------------------
    // ------ Stream readers control
	// --------------------------------------
    logic                                               stream_read_enable          [NUMBER_OF_READ_STREAMS]; 
    logic                                               stream_read_ping_pong_ptr   [NUMBER_OF_READ_STREAMS]; 
    logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]    stream_read_start_address   [NUMBER_OF_READ_STREAMS]; 
    logic [$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]    stream_read_address         [NUMBER_OF_READ_STREAMS]; 
    always_comb begin
        stream_read_ping_pong_ptr[0]    = latched_reg_file.stream_1_ptr[STREAM_PING_PONG_BIT_INDEX]; 
        stream_read_ping_pong_ptr[1]    = latched_reg_file.stream_2_ptr[STREAM_PING_PONG_BIT_INDEX];
        stream_read_ping_pong_ptr[2]    = latched_reg_file.stream_3_ptr[STREAM_PING_PONG_BIT_INDEX];
        stream_read_start_address[0]    = latched_reg_file.stream_1_ptr[STREAM_START_ADDRESS_MSB : STREAM_START_ADDRESS_LSB];
        stream_read_start_address[1]    = latched_reg_file.stream_2_ptr[STREAM_START_ADDRESS_MSB : STREAM_START_ADDRESS_LSB];
        stream_read_start_address[2]    = latched_reg_file.stream_3_ptr[STREAM_START_ADDRESS_MSB : STREAM_START_ADDRESS_LSB];    
        stream_read_enable[0]           = latched_reg_file.stream_1_enable; 
        stream_read_enable[1]           = latched_reg_file.stream_2_enable;
        stream_read_enable[2]           = latched_reg_file.stream_3_enable;
    end
    generate
        for (genvar i=0; i < NUMBER_OF_READ_STREAMS; i++) begin
            stream_reader_control #(   
                .REGISTER_WIDTH                     (REGISTER_WIDTH),
                .NUMBER_OF_REGISTERS                (NUMBER_OF_REGISTERS),
                .ACTIVATION_LINE_BUFFER_DEPTH       (ACTIVATION_LINE_BUFFER_DEPTH),
                .NUMBER_OF_ACTIVATION_LINE_BUFFERS  (NUMBER_OF_ACTIVATION_LINE_BUFFERS)
            ) stream_reader_control_i (
                .clk                            (clk),
                .resetn                         (resetn),
                .latched_reg_file               (latched_reg_file),
                .i_stream_read_enable           (stream_read_enable[i]),
                .i_stream_read_start_address    (stream_read_start_address[i]),
                .o_stream_read_address_ff       (stream_read_address[i]),
                .i_streamed_data_ready          (streamed_data.ready[i]),
                .o_streamed_data_valid          (streamed_data.valid[i])
            );
        end
    endgenerate


    always_comb begin 
        debug_stream_read_enable_1 = stream_read_enable[0];
        debug_latchedddd_stream_read_enable_1 = latched_reg_file.stream_1_enable;
        debug_latchedddd_stream_read_enable_2 = latched_reg_file.stream_2_enable;
        debug_latchedddd_stream_read_enable_3 = latched_reg_file.stream_3_enable;
        debug_stream_read_start_address_1 = stream_read_start_address[0]; 
        debug_stream_read_address_1 = stream_read_address[0];
        debug_latched_reg_file_start_stream_readers = latched_reg_file.start_stream_readers;
    end
    
    // --------------------------------------
    // ------ Read control (AXI and stream readers scheduling/priority)
	// --------------------------------------
    logic [BANK_SELECTION_BIT_WIDTH-1:0] axi_bank_selection_bits; 
    logic [LINE_BUFFER_SELECTION_BIT_WIDTH-1:0] axi_line_buffer_selection_bits;
    logic [LINE_BUFFER_ADDRESS_BIT_WIDTH-1:0] axi_read_address_converted; 
    always_comb axi_bank_selection_bits         = axi_read_address[BANK_SELECTION_BIT_WIDTH-1:0];
    always_comb axi_read_address_converted      = axi_read_address[LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_ADDRESS_BIT_WIDTH];
    always_comb axi_line_buffer_selection_bits  = axi_read_address[LINE_BUFFER_SELECTION_BIT_WIDTH+LINE_BUFFER_ADDRESS_BIT_WIDTH+BANK_SELECTION_BIT_WIDTH-1 -: LINE_BUFFER_SELECTION_BIT_WIDTH];

    always_comb begin // Select buffer. stream readers have priority over axi
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            // if(streamed_data.ready[i]==1) begin
            //     if(stream_read_ping_pong_ptr[i]==PING) begin
            //         activation_buffer_ctrl.read_port_addr[i] = stream_read_address[i];
            //         activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = axi_read_address_converted; 
            //     end
            //     else begin // PONG
            //         activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = stream_read_address[i];
            //         activation_buffer_ctrl.read_port_addr[i] = axi_read_address_converted;
            //     end
            // end
            // else begin
            //     activation_buffer_ctrl.read_port_addr[i]                        = axi_read_address_converted;
            //     activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = axi_read_address_converted;
            // end

            // if(axi_read_enable) begin
            // if(streamed_data.ready[i]==1) begin
            if(stream_read_ping_pong_ptr[i]==PING) begin
                activation_buffer_ctrl.read_port_addr[i] = stream_read_address[i];
                activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = axi_read_address_converted; 
            end
            else begin // PONG
                activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = stream_read_address[i];
                activation_buffer_ctrl.read_port_addr[i] = axi_read_address_converted;
            end
            // end
            // else begin
            //     if(axi_read_enable) begin
            //         activation_buffer_ctrl.read_port_addr[i]                        = axi_read_address_converted;
            //         activation_buffer_ctrl.read_port_addr[NUMBER_OF_READ_STREAMS+i] = axi_read_address_converted;
            //     end
            // end

        end
        
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
//            streamed_data.data[i] = activation_buffer_ctrl.read_port_data_out[i]; 
             if(stream_read_ping_pong_ptr[i]==PING) begin
                 streamed_data.data[i] = activation_buffer_ctrl.read_port_data_out[i]; 
             end
             else begin // PONG
                 streamed_data.data[i] = activation_buffer_ctrl.read_port_data_out[NUMBER_OF_READ_STREAMS+i]; 
             end
        end
    end
    always_comb begin // TODO:: check buffer latency. probably need to use a sequential process
        // use axi_read_enable && axi_read_address to select which buffer to read from 
            // axi_read_data_in <=     activation_buffer_ctrl.read_port_data_out[] ? 

         for (int i=0; i<NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
             if(axi_line_buffer_selection_bits==i) begin
                 // for (int j=0; j<ACTIVATION_BUFFER_BANK_COUNT; j++) begin
                 //     if(axi_bank_selection_bits==j) begin
                 //         axi_read_data_in = activation_buffer_ctrl.read_port_data_out[i][(j+1)*AXI_BUS_BIT_WIDTH-:AXI_BUS_BIT_WIDTH];
                 //     end
                 //     else begin
                 //         axi_read_data_in = activation_buffer_ctrl.read_port_data_out[i][(j+1*)];
                 //     end
                 // end
                 // axi_read_data_in = activation_buffer_ctrl.read_port_data_out[i][(axi_bank_selection_bits+1)*AXI_BUS_BIT_WIDTH-1-:AXI_BUS_BIT_WIDTH];
                 axi_read_data_in = activation_buffer_ctrl.read_port_data_out[i][(ACTIVATION_BUFFER_BANK_COUNT-axi_bank_selection_bits)*AXI_BUS_BIT_WIDTH-1-:AXI_BUS_BIT_WIDTH];
             end
             // else begin
             //     axi_read_data_in = 0;
             // end
         end

//        axi_read_data_in = activation_buffer_ctrl.read_port_data_out[3][(ACTIVATION_BUFFER_BANK_COUNT-axi_bank_selection_bits)*AXI_BUS_BIT_WIDTH-1-:AXI_BUS_BIT_WIDTH];

        // case (axi_line_buffer_selection_bits)
        //     0: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[0];
        //     1: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[1];
        //     2: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[2];
        //     3: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[3];
        //     4: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[4];
        //     5: axi_read_data_in <= activation_buffer_ctrl.read_port_data_out[5];
        //     default: axi_read_data_in <= '0;
        // endcase
    end
    
    


endmodule
