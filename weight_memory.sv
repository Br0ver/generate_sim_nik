/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Weight memory
*   Date:   08.12.2021
*   Author: hasan
*   Description:  Instantiates three buffers
*/

`timescale 1ns / 1ps

module weight_memory #(   
    // parameter  int AXIS_BUS_BIT_WIDTH           = NVP_v1_constants::AXIS_BUS_BIT_WIDTH,
    // parameter  int WEIGHT_BANK_DEPTH          = NVP_v1_constants::WEIGHT_BANK_DEPTH,
    parameter  WEIGHT_BANK_BIT_WIDTH            = NVP_v1_constants::WEIGHT_BANK_BIT_WIDTH,
    parameter  WEIGHT_LINE_BUFFER_DEPTH         = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter  WEIGHT_BUFFER_BANK_COUNT         = NVP_v1_constants::WEIGHT_BUFFER_BANK_COUNT,
    parameter  WEIGHT_AXI_BUS_BIT_WIDTH         = NVP_v1_constants::WEIGHT_AXI_BUS_BIT_WIDTH,
    parameter  NUMBER_OF_WEIGHT_LINE_BUFFERS    = NVP_v1_constants::NUMBER_OF_WEIGHT_LINE_BUFFERS,
    parameter  BIAS_BANK_BIT_WIDTH              = NVP_v1_constants::BIAS_BANK_BIT_WIDTH,
    parameter  BIAS_BIT_WIDTH                   = NVP_v1_constants::BIAS_BIT_WIDTH,
    parameter  BIAS_BUFFER_BANK_COUNT           = NVP_v1_constants::BIAS_BUFFER_BANK_COUNT,
    parameter  BIAS_LINE_BUFFER_DEPTH           = NVP_v1_constants::BIAS_LINE_BUFFER_DEPTH,
    localparam PING                             = NVP_v1_constants::PING,
    localparam PONG                             = NVP_v1_constants::PONG, 
    localparam PING_PONG                        = 2
)(
    input logic                                         clk,
    input logic                                         resetn,
    input logic[$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]   i_reg_file_weight_buffer_address_offset,
    s_axi_bus                                           i_weight_bus,
    weight_buffer_control_if                            weight_buffer_ctrl,
    computation_control_if                              computation_ctrl
);

    // // --------------------------------------
    // // ------ array and bank selection and enable signals 
	// // --------------------------------------
    // logic                                       weight_memory_ready;
    // logic[WEIGHT_BUFFER_BANK_COUNT-1:0]         weight_memory_write_enable_ff;
    // logic[$clog2(WEIGHT_BUFFER_BANK_COUNT)-1:0] weight_memory_bank_pointer;

    weight_buffer_write_control weight_buffer_write_control_unit (   
        .clk                (clk),
        .resetn             (resetn),
        .i_weight_bus       (i_weight_bus),
        .weight_buffer_ctrl (weight_buffer_ctrl)
    );


    // output register
    logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] read_port_data_out_ff [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            computation_ctrl.weight_memory_data <= '{default:0};
        end
        else begin
            read_port_data_out_ff <= weight_buffer_ctrl.read_port_data_out;
            computation_ctrl.weight_memory_data <= read_port_data_out_ff;
        end
    end

    always_comb begin
        // computation_ctrl.weight_memory_data     = weight_buffer_ctrl.read_port_data_out;


        for (int i=0; i < NUMBER_OF_WEIGHT_LINE_BUFFERS; i++) begin
            weight_buffer_ctrl.read_port_addr[i]    = computation_ctrl.weight_memory_address[i] + i_reg_file_weight_buffer_address_offset; 
        end
    end

    // // Bias memory read
    // always_ff @(posedge clk) begin
    //     if (resetn==0) begin
    //         computation_ctrl.bias_memory_data <= '{default:0};
    //     end
    //     else begin
    //         computation_ctrl.bias_memory_data <= weight_buffer_ctrl.bias_read_port_data_out;
    //     end
    // end
    // Bias memory read
    always_comb begin
        computation_ctrl.bias_memory_data = weight_buffer_ctrl.bias_read_port_data_out;
    end

    always_comb begin
        weight_buffer_ctrl.bias_read_port_addr   = computation_ctrl.bias_memory_address; 
    end


    // logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_memory_data_in;
    // logic[NUMBER_OF_WEIGHT_LINE_BUFFERS-1:0]                  weight_memory_en [PING_PONG];
    // logic[WEIGHT_BUFFER_BANK_COUNT-1:0]                       weight_memory_write_enable;
    // logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                      weight_memory_bus_address_in;
    // logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_memory_data_out [PING_PONG][NUMBER_OF_WEIGHT_LINE_BUFFERS];


    // logic[$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0] read_port_addr [NUMBER_OF_WEIGHT_LINE_BUFFERS];
    // always_comb begin
    //     for (genvar i=0; i < NUMBER_OF_WEIGHT_LINE_BUFFERS; i++) begin
    //         read_port_addr[i] = weight_buffer_ctrl.read_port_addr[i]; 
    //     end
    // end

    generate 
        for (genvar i=0; i < NUMBER_OF_WEIGHT_LINE_BUFFERS; i++) begin
            banked_line_buffer #(   
                .BANK_BIT_WIDTH    (WEIGHT_BANK_BIT_WIDTH),
                .BANK_COUNT        (WEIGHT_BUFFER_BANK_COUNT),
                .BANK_DEPTH        (WEIGHT_LINE_BUFFER_DEPTH)
            )weight_line_buffer_i(
                .clk                    (clk),    
                .i_write_port_en        (weight_buffer_ctrl.write_port_enable[i]),                
                .i_write_port_wen       (weight_buffer_ctrl.write_port_wen[i]),                
                .i_write_port_addr      (weight_buffer_ctrl.write_port_addr[i]),                
                .i_write_port_data_in   (weight_buffer_ctrl.write_port_data_in[i]),                    
                .i_read_port_en         ('{default:1}),            
                .i_read_port_addr       (weight_buffer_ctrl.read_port_addr[i]),                
                .o_read_port_data_out   (weight_buffer_ctrl.read_port_data_out[i])                       
            );
        end
    endgenerate


    banked_line_buffer #(   
        .BANK_BIT_WIDTH    (BIAS_BANK_BIT_WIDTH), 
        .BANK_COUNT        (BIAS_BUFFER_BANK_COUNT),
        .BANK_DEPTH        (BIAS_LINE_BUFFER_DEPTH)
    )bias_line_buffer(
        .clk                    (clk),    
        .i_write_port_en        (weight_buffer_ctrl.bias_write_port_enable),                
        .i_write_port_wen       (weight_buffer_ctrl.bias_write_port_wen),                
        .i_write_port_addr      (weight_buffer_ctrl.bias_write_port_addr),                
        .i_write_port_data_in   (weight_buffer_ctrl.bias_write_port_data_in),                    
        .i_read_port_en         ('{default:1}),            
        .i_read_port_addr       (weight_buffer_ctrl.bias_read_port_addr),                
        .o_read_port_data_out   (weight_buffer_ctrl.bias_read_port_data_out)                       
    );
    

    // --------------------------------------
    // ------ Weight row buffer instance  
	// --------------------------------------
    // logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_memory_data_in;
    // logic[NUMBER_OF_WEIGHT_LINE_BUFFERS-1:0]                    weight_memory_en [PING_PONG];
    // logic[WEIGHT_BUFFER_BANK_COUNT-1:0]                       weight_memory_write_enable;
    // logic[$clog2(WEIGHT_BANK_DEPTH)-1:0]                      weight_memory_bus_address_in;
    // logic[WEIGHT_BANK_BIT_WIDTH*WEIGHT_BUFFER_BANK_COUNT-1:0] weight_memory_data_out [PING_PONG][NUMBER_OF_WEIGHT_LINE_BUFFERS];
    // generate  // ping-pong weight buffers
    //     for (genvar i=0; i < PING_PONG; i++) begin
    //         weight_row_buffer #(   
    //             .WEIGHT_BANK_BIT_WIDTH        (WEIGHT_BANK_BIT_WIDTH),
    //             .WEIGHT_BANK_DEPTH            (WEIGHT_BANK_DEPTH),
    //             .WEIGHT_BUFFER_BANK_COUNT       (WEIGHT_BUFFER_BANK_COUNT),
    //             .NUMBER_OF_WEIGHT_LINE_BUFFERS    (NUMBER_OF_WEIGHT_LINE_BUFFERS)
    //         ) weight_buffer_i (
    //             .clk                                (clk),
    //             .resetn                             (resetn),
    //             .i_weight_memory_data_in            (weight_memory_data_in),        
    //             .i_weight_memory_en                 (weight_memory_en[i]),
    //             .i_weight_memory_write_enable       (weight_memory_write_enable),            
    //             .i_weight_memory_bus_address_in     (weight_memory_bus_address_in),        
    //             .i_weight_memory_compute_address_in (computation_ctrl.weight_memory_address),        
    //             .o_weight_memory_data_out           (weight_memory_data_out[i])        
    //         );
    //     end
    // endgenerate

    // // --------------------------------------
    // // ------ Weight array selection 
    // // number of weight arrays = number of PE arrays per row 
	// // --------------------------------------
    // // enum {PING, PONG} read_PING_PONG_fsm; 
    // logic write_PING_PONG_fsm; 
    // enum logic[1:0] {WEIGHT_ARRAY_1, WEIGHT_ARRAY_2, WEIGHT_ARRAY_3} weight_array_selection_fsm; 
    // always_ff @(posedge clk) begin
    //     if (resetn == 0) begin
    //         weight_array_selection_fsm  <= WEIGHT_ARRAY_1;
    //         write_PING_PONG_fsm         <= PING;
    //     end 
    //     else begin
    //         case (weight_array_selection_fsm)
    //             WEIGHT_ARRAY_1: begin
    //                 if (axis_to_weight_memory.last && axis_to_weight_memory.valid && weight_memory_ready) begin
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_2;
    //                 end
    //                 else begin 
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_1;
    //                 end
    //             end
    //             WEIGHT_ARRAY_2: begin
    //                 if (axis_to_weight_memory.last && axis_to_weight_memory.valid && weight_memory_ready) begin
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_3;
    //                 end
    //                 else begin 
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_2;
    //                 end
    //             end
    //             WEIGHT_ARRAY_3: begin
    //                 if (axis_to_weight_memory.last && axis_to_weight_memory.valid && weight_memory_ready) begin
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_1;
    //                     write_PING_PONG_fsm        <= (write_PING_PONG_fsm==PING)? PONG : PING;
    //                 end
    //                 else begin 
    //                     weight_array_selection_fsm <= WEIGHT_ARRAY_3;
    //                 end
    //             end
    //             default: weight_array_selection_fsm <= WEIGHT_ARRAY_1;
    //         endcase
    //     end
    // end 

    
    // // --------------------------------------
    // // ------ select weight array to write into. 
	// // --------------------------------------
    // logic[NUMBER_OF_WEIGHT_LINE_BUFFERS-1:0]  weight_memory_en_ff;
    // always_comb begin
    //     case (weight_array_selection_fsm)
    //         WEIGHT_ARRAY_1: begin
    //             weight_memory_en_ff[0] = 1;
    //             weight_memory_en_ff[1] = 0;
    //             weight_memory_en_ff[2] = 0;
    //         end
    //         WEIGHT_ARRAY_2: begin
    //             weight_memory_en_ff[0] = 0;
    //             weight_memory_en_ff[1] = 1;
    //             weight_memory_en_ff[2] = 0;
    //         end
    //         WEIGHT_ARRAY_3: begin
    //             weight_memory_en_ff[0] = 0;
    //             weight_memory_en_ff[1] = 0;
    //             weight_memory_en_ff[2] = 1;
    //         end
    //         default: weight_memory_en_ff = '0;
    //     endcase
    // end

    // // --------------------------------------
    // // ------ assign selection and enable signals
	// // --------------------------------------
    // always_comb begin
    //     // ready signal
    //     weight_memory_ready   = 1; // fixme?
    //     axis_to_weight_memory.ready = weight_memory_ready;

    //     // write port enable. (at the moment, read port enable is set to 1)
    //     weight_memory_en[PING] = (write_PING_PONG_fsm==PING)? weight_memory_en_ff : '0; // ping
    //     weight_memory_en[PONG] = (write_PING_PONG_fsm==PONG)? weight_memory_en_ff : '0; // pong

    //     // data in
    //     // broadcast axis data. write_enable will only enable the correct column/bank.
    //     for (int i=0; i<WEIGHT_BUFFER_BANK_COUNT; i++) begin
    //         weight_memory_data_in[(i+1)*WEIGHT_BANK_BIT_WIDTH-1 -:WEIGHT_BANK_BIT_WIDTH] = axis_to_weight_memory.data;
    //     end

    //     // write enable
    //     // weight_memory_write_enable = weight_memory_write_enable_ff && axis_to_weight_memory.valid && weight_memory_ready;
    //     for (int i=0; i<WEIGHT_BUFFER_BANK_COUNT; i++) begin
    //         weight_memory_write_enable[i] = weight_memory_write_enable_ff[i] && axis_to_weight_memory.valid && weight_memory_ready;
    //     end
        

    //     // data out
    //     computation_ctrl.weight_memory_data = (i_reg_file_weight_ping_or_pong==PING)? weight_memory_data_out[PING] : weight_memory_data_out[PONG];
    // end
    // // always_ff @(posedge clk) begin
    // //     if (resetn == 0) begin
    // //         computation_ctrl.weight_memory_data <= '{default:0};
    // //     end else begin
    // //         computation_ctrl.weight_memory_data <= (i_reg_file_weight_ping_or_pong==PING)? weight_memory_data_out[PING] : weight_memory_data_out[PONG];
    // //     end
    // // end
    
    // // --------------------------------------
    // // ------ bank selection fsm 
	// // --------------------------------------
    // always_ff @(posedge clk) begin
    //     if (resetn == 0) begin
    //         weight_memory_write_enable_ff    <= 1;
    //         weight_memory_bus_address_in     <= '0;
    //         weight_memory_bank_pointer       <= '0;
    //     end else begin
    //         if (axis_to_weight_memory.valid && weight_memory_ready) begin
    //             if(axis_to_weight_memory.last==1) begin
    //                 weight_memory_bus_address_in  <= 0;
    //                 weight_memory_bank_pointer    <= 0;
    //                 weight_memory_write_enable_ff <= 1;
    //             end
    //             else begin
    //                 if(weight_memory_bank_pointer==WEIGHT_BUFFER_BANK_COUNT-1) begin
    //                     weight_memory_bus_address_in  <= weight_memory_bus_address_in + 1;
    //                     weight_memory_bank_pointer    <= 0;
    //                     weight_memory_write_enable_ff <= 1;
    //                 end
    //                 else begin
    //                     weight_memory_bank_pointer <= weight_memory_bank_pointer + 1;

    //                     // rotate write enable
    //                     weight_memory_write_enable_ff[0] <= weight_memory_write_enable_ff[WEIGHT_BUFFER_BANK_COUNT-1];
    //                     for (int i=1; i<WEIGHT_BUFFER_BANK_COUNT; i++) begin
    //                         weight_memory_write_enable_ff[i] <= weight_memory_write_enable_ff[i-1];
    //                     end
    //                 end
    //             end
    //         end
    //         // else begin
    //         // end
    //     end
    // end


    // logic [8-1:0]        dissected_weight_data [8];
    // always_comb begin
    //     // slice input weights into "WEIGHT_BIT_WIDTH" chunks.
    //     for (int i=0; i<8; i++) begin
    //         dissected_weight_data[i] = weight_memory_data_in[(i+1)*8-1 -: 8];
    //     end
    // end

     
endmodule
