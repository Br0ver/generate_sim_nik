/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: AXI to Memory
*   Date:   20.09.2021
*   Author: hasan
*   Description:  Converts the AXI Full interface to a generic memory interface.
*/

`timescale 1ns / 1ps

module axi_memory_fsm #(
    parameter int C_S_AXI_DATA_WIDTH = 32,
    parameter int C_S_AXI_ADDR_WIDTH = 8,
    parameter int RAM_OUTPUT_PIPES  = 1 // Defines the latency of the memory output
)(
    input logic clk,
    // AXI interface
    s_axi_bus.slave axi_bus, 
    
    // Memory interface
    output logic                                                        o_enable,
    output logic                                                        o_write_enable,
    output logic[C_S_AXI_DATA_WIDTH/8-1:0]                              o_write_strobes, // Write strobes are byte wise
    output logic[C_S_AXI_DATA_WIDTH-1:0]                                o_data,
    output logic[C_S_AXI_ADDR_WIDTH-$clog2(C_S_AXI_DATA_WIDTH/8)-1:0]   o_address, // Addresses one word, even though AXI addresses bytes (the address is converted)
    input logic[C_S_AXI_DATA_WIDTH-1:0]                                 i_data
);

    localparam int BYTE_WIDTH = C_S_AXI_DATA_WIDTH/8;   
    localparam int ADDRESS_DIFFERENCE = $clog2(BYTE_WIDTH);     // If the data width parameter is passed directly to clog2, there is an error (not a constant)
    localparam int MEM_ADDRESS_WIDTH = C_S_AXI_ADDR_WIDTH-ADDRESS_DIFFERENCE; // For address conversion (AXI addresses bytes)

    typedef enum logic[2:0] {IDLE = 0, READ = 1, READ_INCREMENT = 2, READ_WAIT = 3, WRITE = 4, WRITE_WAIT = 5} axi_state_t;

    axi_state_t state_ff = IDLE;
    
    logic[MEM_ADDRESS_WIDTH-1:0] l_start_address_ff = 0;
    logic[MEM_ADDRESS_WIDTH-1:0] l_incr_address_ff = 0;

    logic[1:0] burst_mode_ff = 0;
    
    logic[$clog2(RAM_OUTPUT_PIPES):0] l_clocks_to_wait_ff = 0;
    
    logic[7:0] l_words_to_read_ff = 0;
    
    logic l_read_enable;
    
    logic[7:0] l_wrap_length_ff = 0;
    logic[MEM_ADDRESS_WIDTH-1:0] l_wrap_boundary_ff = 0;
    
    logic[MEM_ADDRESS_WIDTH-1:0] l_axi_write_address_comb;
    logic[MEM_ADDRESS_WIDTH-1:0] l_axi_read_address_comb;
    
    function logic[MEM_ADDRESS_WIDTH-1:0] f_calculate_boundary(
        input logic[MEM_ADDRESS_WIDTH-1:0] il_start_address,
        input logic[7:0] il_burst_length
    );
        logic[MEM_ADDRESS_WIDTH-1:0] l_boundary;
        
        // Only the burst sizes 2, 4, 8 and 16 are allowed in Wrap mode
        // This generates the wrap boundary
        case(il_burst_length)
             1: l_boundary = {il_start_address[MEM_ADDRESS_WIDTH-1:1], 1'b0};
             3: l_boundary = {il_start_address[MEM_ADDRESS_WIDTH-1:2], 2'b00};
             7: l_boundary = {il_start_address[MEM_ADDRESS_WIDTH-1:3], 3'b000};
            15: l_boundary = {il_start_address[MEM_ADDRESS_WIDTH-1:4], 4'b0000};
            default: l_boundary = il_start_address;
        endcase
        
        return l_boundary;
    endfunction
    
    // Address conversion from byte to word
    assign l_axi_write_address_comb[MEM_ADDRESS_WIDTH-1:0] = axi_bus.S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH-1:ADDRESS_DIFFERENCE];
    assign l_axi_read_address_comb[MEM_ADDRESS_WIDTH-1:0] = axi_bus.S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH-1:ADDRESS_DIFFERENCE];
    
    assign o_enable = o_write_enable | l_read_enable;
    assign o_write_enable = axi_bus.S_AXI_WREADY & axi_bus.S_AXI_WVALID & state_ff == WRITE;
    
    assign o_data = axi_bus.S_AXI_WDATA;
    
    assign axi_bus.S_AXI_RDATA = i_data;
    
    assign o_write_strobes = axi_bus.S_AXI_WSTRB;
    
    always_comb
    begin
        case(burst_mode_ff)
            2'b00: // Fixed burst
                o_address <= l_start_address_ff;
            2'b01: // Increment burst
                o_address <= l_incr_address_ff;
            2'b10: // Wrap burst
                o_address <= l_incr_address_ff;
            default: // Illegal - Fixed burst
                o_address <= l_start_address_ff;
        endcase
    end
    
    // always_ff @(posedge axi_bus.S_AXI_ACLK)
    always_ff @(posedge clk)
    begin
        if(~axi_bus.S_AXI_ARESETN) begin
            state_ff <= IDLE;
            // These MUST be resetted for correct AXI implementation
            axi_bus.S_AXI_BVALID <= 0;
            axi_bus.S_AXI_RVALID <= 0;
        end
        else begin
            case(state_ff)
                IDLE:
                begin
                    axi_bus.S_AXI_RLAST <= 0;
                    axi_bus.S_AXI_RVALID <= 0;
                    l_read_enable <= 0;
                    if(axi_bus.S_AXI_AWVALID) begin
                        l_start_address_ff <= l_axi_write_address_comb;
                        l_incr_address_ff <= l_axi_write_address_comb;
                        
                        l_wrap_length_ff <= axi_bus.S_AXI_AWLEN;
                        l_wrap_boundary_ff <= f_calculate_boundary(
                            l_axi_write_address_comb,
                            axi_bus.S_AXI_AWLEN
                        );
                        
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 0;
                        axi_bus.S_AXI_RRESP <= 0;
                        axi_bus.S_AXI_RID <= 0;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 1;
                        axi_bus.S_AXI_WREADY <= 1;
                        if(axi_bus.S_AXI_AWLOCK == 2'b01) begin
                            axi_bus.S_AXI_BRESP <= 2'b01;
                        end
                        else begin
                            axi_bus.S_AXI_BRESP <= 2'b00;
                        end
                        axi_bus.S_AXI_BID <= axi_bus.S_AXI_AWID;
                        axi_bus.S_AXI_BVALID <= 0;
                        
                        
                        burst_mode_ff <= axi_bus.S_AXI_AWBURST;
                        state_ff <= WRITE;
                    end
                    else if(axi_bus.S_AXI_ARVALID) begin
                        l_start_address_ff <= l_axi_read_address_comb;
                        l_incr_address_ff <= l_axi_read_address_comb;
                        
                        l_wrap_length_ff <= axi_bus.S_AXI_ARLEN;
                        l_wrap_boundary_ff <= f_calculate_boundary(
                            l_axi_read_address_comb,
                            axi_bus.S_AXI_ARLEN
                        );
                        
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 1;
                        if(axi_bus.S_AXI_ARLOCK == 2'b01) begin
                            axi_bus.S_AXI_RRESP <= 2'b01;
                        end
                        else begin
                            axi_bus.S_AXI_RRESP <= 2'b00;
                        end
                        axi_bus.S_AXI_RID <= axi_bus.S_AXI_ARID;
                        
                        l_clocks_to_wait_ff <= RAM_OUTPUT_PIPES;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 0;
                        axi_bus.S_AXI_WREADY <= 0;
                        axi_bus.S_AXI_BRESP <= 0;
                        axi_bus.S_AXI_BID <= 0;
                        axi_bus.S_AXI_BVALID <= 0;
                        
                        burst_mode_ff <= axi_bus.S_AXI_ARBURST;
                        state_ff <= READ;
                        
                        l_words_to_read_ff <= axi_bus.S_AXI_ARLEN;
                        l_read_enable <= 1;
                    end
                    else begin
                        l_start_address_ff <= 0;
                        l_incr_address_ff <= 0;
                        
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 0;
                        axi_bus.S_AXI_RRESP <= 0;
                        axi_bus.S_AXI_RID <= 0;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 0;
                        axi_bus.S_AXI_WREADY <= 0;
                        axi_bus.S_AXI_BRESP <= 0;
                        axi_bus.S_AXI_BID <= 0;
                        axi_bus.S_AXI_BVALID <= 0;

                        burst_mode_ff <= 0;
                        state_ff <= IDLE;
                    end
                end
                
                // Writes the data into the memory interface
                WRITE:
                begin
                    axi_bus.S_AXI_AWREADY <= 0;
                    if(axi_bus.S_AXI_WVALID) begin
                        if(axi_bus.S_AXI_WLAST) begin
                            // Prepare response if the last data is transmitted
                            axi_bus.S_AXI_BVALID <= 1;
                            axi_bus.S_AXI_WREADY <= 0;
                            state_ff <= WRITE_WAIT;
                        end
                        
                        if(axi_bus.S_AXI_WREADY) begin
                            // Check if burst mode is wrap
                            if(burst_mode_ff == 2'b10) begin
                                // Check if the boundary address is crossed
                                if(l_incr_address_ff == l_wrap_boundary_ff + l_wrap_length_ff) begin
                                    // Wrap to the boundary address
                                    l_incr_address_ff <= l_wrap_boundary_ff;
                                end
                                else begin
                                    // Increment for Wrap burst mode
                                    l_incr_address_ff <= l_incr_address_ff + 1;
                                end
                            end
                            else begin
                                // Increment for Incr burst mode
                                l_incr_address_ff <= l_incr_address_ff + 1;
                            end
                        end
                    end
                end
                
                // Waits until the response is read and exits write mode
                WRITE_WAIT:
                begin
                    if(axi_bus.S_AXI_BREADY) begin
                        axi_bus.S_AXI_BVALID <= 0;
                        state_ff <= IDLE;
                    end
                end
                
                // Reads data from memory interface and waits for it (depending on the number of pipelines in memory)
                READ:
                begin
                    axi_bus.S_AXI_ARREADY <= 0;
                    // Check if data is ready
                    if(l_clocks_to_wait_ff == 0) begin
                        axi_bus.S_AXI_RVALID <= 1;
                        // Check if it's the last one
                        if(l_words_to_read_ff == 0) begin
                            axi_bus.S_AXI_RLAST <= 1;
                            state_ff <= READ_WAIT;
                        end
                        else begin
                            state_ff <= READ_INCREMENT;
                        end
                    end
                    
                    l_clocks_to_wait_ff <= l_clocks_to_wait_ff - 1;
                end
                
                // Increments the address for the memory read port
                READ_INCREMENT:
                begin
                    if(axi_bus.S_AXI_RREADY) begin
                        // Check if burst mode is wrap
                        if(burst_mode_ff == 2'b10) begin
                            // Check if the boundary address is crossed
                            if(l_incr_address_ff == l_wrap_boundary_ff + l_wrap_length_ff) begin
                                // Wrap to the boundary address
                                l_incr_address_ff <= l_wrap_boundary_ff;
                            end
                            else begin
                                // Increment for Wrap burst mode
                                l_incr_address_ff <= l_incr_address_ff + 1;
                            end
                        end
                        else begin
                            // Increment for Incr burst mode
                            l_incr_address_ff <= l_incr_address_ff + 1;
                        end
                    
                        l_words_to_read_ff <= l_words_to_read_ff - 1;
                        l_clocks_to_wait_ff <= RAM_OUTPUT_PIPES;
                        axi_bus.S_AXI_RVALID <= 0;
                        state_ff <= READ;
                    end
                end
                
                // Waits until the transaction is finished and exits read mode
                READ_WAIT:
                begin
                    axi_bus.S_AXI_RLAST <= 0;
                    axi_bus.S_AXI_RVALID <= 0;
                    l_read_enable <= 0;
                    state_ff <= IDLE;
                end
                
                default:
                    state_ff <= IDLE;
            endcase
        end
    end
    
    generate
        if (0) begin
            initial begin
                $warning("INSIDE axi_memory_fsm:");
                $warning("BYTE_WIDTH: %d", BYTE_WIDTH);
                $warning("ADDRESS_DIFFERENCE: %d", ADDRESS_DIFFERENCE);
                $warning("MEM_ADDRESS_WIDTH: %d", MEM_ADDRESS_WIDTH);
            end
        end
    endgenerate



endmodule