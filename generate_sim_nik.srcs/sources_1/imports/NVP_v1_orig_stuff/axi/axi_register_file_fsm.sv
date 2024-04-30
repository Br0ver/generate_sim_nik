/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: AXI to Memory
*   Date:   27.09.2021
*   Author: hasan
*   Description:  Converts the AXI Full interface to a generic register file interface.
*/


`timescale 1ns / 1ps

module axi_register_file_fsm #(
    parameter int AXI_DATA_WIDTH    = 32,
    parameter int AXI_ADDR_WIDTH    = 10
)(
    // AXI interface
    s_axi_lite_bus.slave axi_bus, 
    
    // Register interface
    output logic                                    ol_write_enable,
    output logic[AXI_DATA_WIDTH/8-1:0]  ol_write_strobes, // Write strobes are byte wise
    output logic[AXI_DATA_WIDTH-1:0]    ol_data,
    output logic[AXI_ADDR_WIDTH-
        $clog2(AXI_DATA_WIDTH/8)-1:0]   ol_write_address, // Addresses one word, even though AXI addresses bytes (the address is converted)

    input logic[AXI_DATA_WIDTH-1:0]     il_data,
    output logic[AXI_ADDR_WIDTH-
        $clog2(AXI_DATA_WIDTH/8)-1:0]   ol_read_address   // Addresses one word, even though AXI addresses bytes (the address is converted)
);

    localparam int BYTE_WIDTH = AXI_DATA_WIDTH/8;   // Workaround for a weird bug in Vivado simulator:
    localparam int ADDRESS_DIFFERENCE = $clog2(BYTE_WIDTH);     // If the data width parameter is passed directly to clog2, there is an error (not a constant)
    localparam int REG_ADDRESS_WIDTH = AXI_ADDR_WIDTH-ADDRESS_DIFFERENCE; // For address conversion (AXI addresses bytes)
    
    typedef enum logic[2:0] {IDLE = 0, READ = 1, READ_WAIT = 2, WRITE = 3, WRITE_WAIT = 4} axi_state_t;

    axi_state_t state_ff = IDLE;
    
    logic[REG_ADDRESS_WIDTH-1:0] l_axi_write_address_comb;
    logic[REG_ADDRESS_WIDTH-1:0] l_axi_read_address_comb;
    
    // Address conversion from byte to word
    assign l_axi_write_address_comb[REG_ADDRESS_WIDTH-1:0] = axi_bus.S_AXI_AWADDR[AXI_ADDR_WIDTH-1:ADDRESS_DIFFERENCE];
    assign l_axi_read_address_comb[REG_ADDRESS_WIDTH-1:0] = axi_bus.S_AXI_ARADDR[AXI_ADDR_WIDTH-1:ADDRESS_DIFFERENCE];
    
    assign ol_write_enable = axi_bus.S_AXI_WREADY & axi_bus.S_AXI_WVALID & state_ff == WRITE;
    
    assign ol_data = axi_bus.S_AXI_WDATA;
    
    assign axi_bus.S_AXI_RDATA = il_data;
    
    assign ol_write_strobes = axi_bus.S_AXI_WSTRB;
    
    always_ff @(posedge axi_bus.S_AXI_ACLK)
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
                    axi_bus.S_AXI_RVALID <= 0;
                    if(axi_bus.S_AXI_AWVALID) begin
                        ol_write_address <= l_axi_write_address_comb;
                        
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 0;
                        axi_bus.S_AXI_RRESP <= 0;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 1;
                        axi_bus.S_AXI_WREADY <= 1;
                        axi_bus.S_AXI_BRESP <= 2'b00;
                        
                        axi_bus.S_AXI_BVALID <= 0;
                        
                        state_ff <= WRITE;
                    end
                    else if(axi_bus.S_AXI_ARVALID) begin
                        ol_read_address <= l_axi_read_address_comb;
                        
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 1;
                        axi_bus.S_AXI_RRESP <= 2'b00;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 0;
                        axi_bus.S_AXI_WREADY <= 0;
                        axi_bus.S_AXI_BRESP <= 0;
                        axi_bus.S_AXI_BVALID <= 0;
                        
                        state_ff <= READ;
                    end
                    else begin
                        ol_write_address <= 0;
                        ol_read_address <= 0;
                    
                        // Read channel
                        axi_bus.S_AXI_ARREADY <= 0;
                        axi_bus.S_AXI_RRESP <= 0;
                        
                        // Write channel
                        axi_bus.S_AXI_AWREADY <= 0;
                        axi_bus.S_AXI_WREADY <= 0;
                        axi_bus.S_AXI_BRESP <= 0;
                        axi_bus.S_AXI_BVALID <= 0;

                        state_ff <= IDLE;
                    end
                end
                
                // Writes the data into the memory interface
                WRITE:
                begin
                    axi_bus.S_AXI_AWREADY <= 0;
                    if(axi_bus.S_AXI_WVALID) begin
                        // Prepare response if the last data is transmitted
                        axi_bus.S_AXI_BVALID <= 1;
                        axi_bus.S_AXI_WREADY <= 0;
                        state_ff <= WRITE_WAIT;
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
                
                // Reads data from memory interface
                READ:
                begin
                    axi_bus.S_AXI_ARREADY <= 0;
                    axi_bus.S_AXI_RVALID <= 1;
                    state_ff <= READ_WAIT;
                end
                
                // Waits until the response is read and exits read mode
                READ_WAIT:
                begin
                    if(axi_bus.S_AXI_RREADY) begin
                        axi_bus.S_AXI_RVALID <= 0;
                        state_ff <= IDLE;
                    end
                end
                
                default:
                    state_ff <= IDLE;
            endcase
        end
    end
    
endmodule