/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Test Package
*   Date:   20.09.2021
*   Author: hasan
*   Description: Defines Classes and Functions needed for testing. 
*/

`timescale 1ns / 1ps



package test_package;

    //let max(a,b) = (a > b) ? a : b;
    //`define MAX(a, b) ((a) > (b) ? (a) : (b))
    import NVP_v1_constants::*;

    class AXI_full_stimulus #(
        parameter AXI_DATA_WIDTH = 32,
        parameter AXI_ADDRESS_WIDTH = 32
    );
    
        task automatic write_AXI_full_data(
            input logic[AXI_DATA_WIDTH-1:0] data[0:(2**$bits(byte unsigned))-1],
            input byte unsigned             length,
            input int                   start_address,
            
            // Call by reference enables the task to read and write the external signals at execution
            ref logic                           AXI_ACLK,
            
            ref logic[0 : 0]                    AXI_AWID,
            ref logic[AXI_ADDRESS_WIDTH-1 : 0]  AXI_AWADDR,
            ref logic[7 : 0]                    AXI_AWLEN,
            ref logic[2 : 0]                    AXI_AWSIZE,
            ref logic[1 : 0]                    AXI_AWBURST,
            ref logic                           AXI_AWLOCK,
            ref logic                           AXI_AWVALID,
            const ref logic                     AXI_AWREADY,
            ref logic[AXI_DATA_WIDTH-1 : 0]     AXI_WDATA,
            ref logic[(AXI_DATA_WIDTH/8)-1 : 0] AXI_WSTRB,
            ref logic                           AXI_WLAST,
            ref logic                           AXI_WVALID,
            const ref logic                     AXI_WREADY,
            const ref logic[0 : 0]              AXI_BID,
            const ref logic[1 : 0]              AXI_BRESP,
            const ref logic                     AXI_BVALID,
            ref logic                           AXI_BREADY );
            AXI_AWID = 1'b0;
            AXI_AWADDR = start_address;
            AXI_AWLEN = length;
            AXI_AWSIZE = 3'b010; // 4 Bytes in each transfer
            AXI_AWBURST = 2'b01; // INCR burst
            AXI_AWLOCK = 1'b0;
            
            @(posedge AXI_ACLK);
            
            // Send the address
            AXI_AWVALID = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_AWREADY);
            AXI_AWID = 0;
            AXI_AWADDR = 0;
            AXI_AWLEN = 0;
            AXI_AWSIZE = 3'b000;
            AXI_AWBURST = 2'b00;
            AXI_AWLOCK = 1'b0;
            // Address is invalid now
            AXI_AWVALID = 1'b0;
            
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            // Send the burst of data
            AXI_WLAST = 1'b0;
            for(int i = 0; i <= length; i++) begin
                // do begin
                //     @(posedge AXI_ACLK);
                // end
                // while(!AXI_WREADY);

                AXI_WDATA = data[i];
                AXI_WSTRB = '{default: 1'b1};
                AXI_WVALID = 1'b1;
                
                // Assert WLAST if the last word is transmitted
                if(i == length) begin
                    AXI_WLAST = 1'b1;
                end
                else begin
                    AXI_WLAST = 1'b0;
                end
                
                do begin
                    @(posedge AXI_ACLK);
                end
                while(!AXI_WREADY);
            end
            AXI_WDATA = 0;
            AXI_WSTRB = 0;
            AXI_WLAST = 1'b0;
            AXI_WVALID = 1'b0;
            
            // Take the response
            AXI_BREADY = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_BVALID);
            AXI_BREADY = 1'b0;
        endtask
    
        task automatic read_AXI_full_data(
            output logic[AXI_DATA_WIDTH-1:0]    data[0:(2**$bits(byte unsigned))-1],
            input byte unsigned                 length,
            input int                       start_address,
        
            // Call by reference enables the task to read and write the external signals at execution
            ref logic                               AXI_ACLK,
            
            ref logic[0 : 0]                        AXI_ARID,
            ref logic[AXI_ADDRESS_WIDTH-1 : 0]      AXI_ARADDR,
            ref logic[7 : 0]                        AXI_ARLEN,
            ref logic[2 : 0]                        AXI_ARSIZE,
            ref logic[1 : 0]                        AXI_ARBURST,
            ref logic                               AXI_ARLOCK,
            ref logic                               AXI_ARVALID,
            const ref logic                         AXI_ARREADY,
            const ref logic[0 : 0]                  AXI_RID,
            const ref logic[AXI_DATA_WIDTH-1 : 0]   AXI_RDATA,
            const ref logic[1 : 0]                  AXI_RRESP,
            const ref logic                         AXI_RLAST,
            const ref logic                         AXI_RVALID,
            ref logic                               AXI_RREADY 
            );
            byte unsigned word_index = 0;
            
            AXI_ARID = 1'b0;
            AXI_ARADDR = start_address;
            AXI_ARLEN = length;
            AXI_ARSIZE = 3'b010; // 4 Bytes in each transfer
            AXI_ARBURST = 2'b01; // INCR burst
            AXI_ARLOCK = 1'b0;
            
            @(posedge AXI_ACLK);
            // Send the address
            AXI_ARVALID = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_ARREADY);
            AXI_ARID = 0;
            AXI_ARADDR = 0;
            AXI_ARLEN = 0;
            AXI_ARSIZE = 3'b000;
            AXI_ARBURST = 2'b00;
            AXI_ARLOCK = 1'b0;
            // Address is invalid now
            AXI_ARVALID = 1'b0;
            
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            // Read the burst of data
            AXI_RREADY = 1'b1;
            do begin
                @(posedge AXI_ACLK);
                if(AXI_RVALID) begin
                    data[word_index] = AXI_RDATA;
                    word_index++;
                end
            end
            while(!AXI_RLAST);
            AXI_RREADY = 1'b0;  
        endtask
    endclass
    
    
    class AXI_lite_stimulus #(
        parameter AXI_DATA_WIDTH = 32,
        parameter AXI_ADDRESS_WIDTH = 6
    );
        task automatic write_AXI_lite_data(
            input logic[AXI_DATA_WIDTH-1:0] data,
            input int                   address,
            
            // Call by reference enables the task to read and write the external signals at execution
            const ref logic                         AXI_ACLK,
            
            ref logic[AXI_ADDRESS_WIDTH-1 : 0]      AXI_AWADDR,
            ref logic                               AXI_AWVALID,
            const ref logic                         AXI_AWREADY,
            ref logic[AXI_DATA_WIDTH-1 : 0]         AXI_WDATA,
            ref logic[(AXI_DATA_WIDTH/8)-1 : 0]     AXI_WSTRB,
            ref logic                               AXI_WVALID,
            const ref logic                         AXI_WREADY,
            const ref logic[1 : 0]                  AXI_BRESP,
            const ref logic                         AXI_BVALID,
            ref logic                               AXI_BREADY
        );
            AXI_AWADDR = address;
            @(posedge AXI_ACLK);
            // Send the address
            AXI_AWVALID = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_AWREADY);
            AXI_AWADDR = 0;
            // Address is invalid now
            AXI_AWVALID = 1'b0;
            
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            AXI_WDATA = data;
            AXI_WSTRB = '{default: 1'b1};
            @(posedge AXI_ACLK);
            // Send the data
            AXI_WVALID = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_WREADY);
            AXI_WDATA = 0;
            AXI_WSTRB = 0;
            // Data is invalid now
            AXI_WVALID = 1'b0;
            
            // Take the response
            AXI_BREADY = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_BVALID);
            AXI_BREADY = 1'b0;
        endtask
        
        task automatic read_AXI_lite_data(
            output logic[AXI_DATA_WIDTH-1:0]    data,
            input int                       address,
            
            // Call by reference enables the task to read and write the external signals at execution
            const ref logic                         AXI_ACLK,
            
            ref logic[AXI_ADDRESS_WIDTH-1 : 0]      AXI_ARADDR,
            ref logic                               AXI_ARVALID,
            const ref logic                         AXI_ARREADY,
            const ref logic[AXI_DATA_WIDTH-1 : 0]   AXI_RDATA,
            const ref logic[1 : 0]                  AXI_RRESP,
            const ref logic                         AXI_RVALID,
            ref logic                               AXI_RREADY
        );
        
            AXI_ARADDR = address;
            @(posedge AXI_ACLK);
            // Send the address
            AXI_ARVALID = 1'b1;
            do begin
                @(posedge AXI_ACLK);
            end
            while(!AXI_ARREADY);
            AXI_ARADDR = 0;
            // Address is invalid now
            AXI_ARVALID = 1'b0;
            
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            @(posedge AXI_ACLK);
            
            AXI_RREADY = 1'b1;
            do begin
                @(posedge AXI_ACLK);
                if(AXI_RVALID) begin
                    data = AXI_RDATA;
                end
            end
            while(!AXI_RVALID);
            AXI_RREADY = 1'b0;
        endtask
    endclass
    
    // Wraps a logic array to be able to store the data on the heap and not on the stack
    // (otherwise a very large variable can't be handled by the simulator when calling a function with it).
    class memory_class #(
        parameter int WORD_WIDTH,
        parameter int MEMORY_DEPTH
    );
        logic[WORD_WIDTH-1:0] memory [0:MEMORY_DEPTH-1];
    endclass
    
    class AXI_full_transfer #(
        parameter AXI_DATA_WIDTH = 32,
        parameter AXI_ADDRESS_WIDTH = 32,
        
        parameter WORD_WIDTH = 16,
        parameter DATA_SIZE = 256   // Describes how many words should be transferred
    );
        AXI_full_stimulus #(
            .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
            .AXI_ADDRESS_WIDTH(AXI_ADDRESS_WIDTH)
        ) axi_stimulus;
        
        function new();
            axi_stimulus = new();
        endfunction
		
        task automatic write_data(
            input memory_class #(.WORD_WIDTH(WORD_WIDTH), .MEMORY_DEPTH(DATA_SIZE)) data,
            input int transfer_size, // must be less than or equal DATA_SIZE
            input int start_address,

            virtual s_axi_bus #(
                .C_S_AXI_ID_WIDTH(1),
                .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .C_S_AXI_ADDR_WIDTH(AXI_ADDRESS_WIDTH)
            ) memory_bus
            );
            logic[AXI_DATA_WIDTH-1:0] axi_buffer[0:(2**$bits(byte unsigned))-1]; // One transfer can be 256 AXI words
            
            // localparam int WORD_MULTIPLIER = AXI_DATA_WIDTH/WORD_WIDTH;
            // localparam int AXI_TRANSFER_SIZE = (DATA_SIZE+WORD_MULTIPLIER-1)/WORD_MULTIPLIER;
            // localparam int NUMBER_OF_TRANSFERS = (AXI_TRANSFER_SIZE+256-1)/256;

            int WORD_MULTIPLIER = AXI_DATA_WIDTH/WORD_WIDTH;
            int AXI_TRANSFER_SIZE = (transfer_size+WORD_MULTIPLIER-1)/WORD_MULTIPLIER;
            int NUMBER_OF_TRANSFERS = (AXI_TRANSFER_SIZE+256-1)/256;
            
            int w = 0;
            int address = 0;
            int j;
            for(int i = 0; i < NUMBER_OF_TRANSFERS; i++) begin // Loop through all transfers
                for(j = 0; j < 256; j++) begin // Write transfer buffer
                    if(w >= transfer_size) begin
                        break; 
                    end
                    
                    for(int k = 0; k < WORD_MULTIPLIER; k++) begin
                        axi_buffer[j][k*WORD_WIDTH +: WORD_WIDTH] = data.memory[w+k]; // Write the next word to the transfer buffer
                    end
                    w += WORD_MULTIPLIER;
                end
                
				axi_stimulus.write_AXI_full_data(
						.data(axi_buffer),
						.length(j-1),
						.start_address(start_address+address), // Addresses bytes
						
						.AXI_ACLK   (memory_bus.S_AXI_ACLK),  
						.AXI_AWID   (memory_bus.S_AXI_AWID),
						.AXI_AWADDR (memory_bus.S_AXI_AWADDR),
						.AXI_AWLEN  (memory_bus.S_AXI_AWLEN),
						.AXI_AWSIZE (memory_bus.S_AXI_AWSIZE),
						.AXI_AWBURST(memory_bus.S_AXI_AWBURST),
						.AXI_AWLOCK (memory_bus.S_AXI_AWLOCK),
						.AXI_AWVALID(memory_bus.S_AXI_AWVALID),
						.AXI_AWREADY(memory_bus.S_AXI_AWREADY),
						.AXI_WDATA  (memory_bus.S_AXI_WDATA),
						.AXI_WSTRB  (memory_bus.S_AXI_WSTRB),
						.AXI_WLAST  (memory_bus.S_AXI_WLAST),
						.AXI_WVALID (memory_bus.S_AXI_WVALID),
						.AXI_WREADY (memory_bus.S_AXI_WREADY),
						.AXI_BID    (memory_bus.S_AXI_BID),
						.AXI_BRESP  (memory_bus.S_AXI_BRESP),
						.AXI_BVALID (memory_bus.S_AXI_BVALID),
						.AXI_BREADY (memory_bus.S_AXI_BREADY)
					);
				
                address += 256*AXI_DATA_WIDTH/8;
            end
        endtask
        
        task automatic read_data(
            output memory_class #(.WORD_WIDTH(WORD_WIDTH), .MEMORY_DEPTH(DATA_SIZE)) data,
            input int transfer_size, // must be less than or equal DATA_SIZE
            input int start_address,
            virtual s_axi_bus #(
                .C_S_AXI_ID_WIDTH(1),
                .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
                .C_S_AXI_ADDR_WIDTH(AXI_ADDRESS_WIDTH)
            ) memory_bus

            );
            logic[AXI_DATA_WIDTH-1:0] axi_buffer[0:(2**$bits(byte unsigned))-1]; // One transfer can be 256 AXI words
            
            // localparam int WORD_MULTIPLIER = AXI_DATA_WIDTH/WORD_WIDTH;
            // localparam int AXI_TRANSFER_SIZE = (DATA_SIZE+WORD_MULTIPLIER-1)/WORD_MULTIPLIER;
            // localparam int NUMBER_OF_TRANSFERS = (AXI_TRANSFER_SIZE+256-1)/256;

            int WORD_MULTIPLIER = AXI_DATA_WIDTH/WORD_WIDTH;
            int AXI_TRANSFER_SIZE = (transfer_size+WORD_MULTIPLIER-1)/WORD_MULTIPLIER;
            int NUMBER_OF_TRANSFERS = (AXI_TRANSFER_SIZE+256-1)/256;
            
            int w = 0;
            int address = 0;
            int j;
            
            data = new;
            
            for(int i = 0; i < NUMBER_OF_TRANSFERS; i++) begin // Loop through all transfers
                axi_stimulus.read_AXI_full_data(
                    .data(axi_buffer),
                    .length(j-1),
                    .start_address(start_address+address), // Addresses bytes
                    .AXI_ACLK   (memory_bus.S_AXI_ACLK),
                    .AXI_ARID   (memory_bus.S_AXI_ARID),
                    .AXI_ARADDR (memory_bus.S_AXI_ARADDR),
                    .AXI_ARLEN  (memory_bus.S_AXI_ARLEN),
                    .AXI_ARSIZE (memory_bus.S_AXI_ARSIZE),
                    .AXI_ARBURST(memory_bus.S_AXI_ARBURST),
                    .AXI_ARLOCK (memory_bus.S_AXI_ARLOCK),
                    .AXI_ARVALID(memory_bus.S_AXI_ARVALID),
                    .AXI_ARREADY(memory_bus.S_AXI_ARREADY),
                    .AXI_RID    (memory_bus.S_AXI_RID),
                    .AXI_RDATA  (memory_bus.S_AXI_RDATA),
                    .AXI_RRESP  (memory_bus.S_AXI_RRESP),
                    .AXI_RLAST  (memory_bus.S_AXI_RLAST),
                    .AXI_RVALID (memory_bus.S_AXI_RVALID),
                    .AXI_RREADY (memory_bus.S_AXI_RREADY)
                );
            
                for(j = 0; j < 256; j++) begin // Read transfer buffer
                    if(w >= transfer_size) begin
                        break; 
                    end
                    
                    for(int k = 0; k < WORD_MULTIPLIER; k++) begin
                        data.memory[w+k] = axi_buffer[j][k*WORD_WIDTH +: WORD_WIDTH]; // Read the next word from the transfer buffer
                    end
                    w += WORD_MULTIPLIER;
                end
                
                address += 256*AXI_DATA_WIDTH/8;
            end
        endtask
    endclass

    class layer_i #(
        parameter  WEIGHT_BIT_WIDTH                 = 8,
        parameter  WEIGHT_AXI_BUS_DATA_BIT_WIDTH    = 64,
        parameter  WEIGHT_AXI_BUS_ADDRESS_WIDTH     = 10,
        parameter  ACTIVATION_BIT_WIDTH             = 8,
        parameter  AXI_BUS_DATA_BIT_WIDTH           = 64,
        parameter  AXI_BUS_ADDRESS_WIDTH            = 10,
        parameter  NUMBER_OF_WEIGHT_ARRAY_ENTRIES   = 64,
        parameter  CONTROL_AXI_DATA_WIDTH         = 32,
        parameter  CONTROL_AXI_ADDR_WIDTH         = 6,
        parameter  ACTIVATION_MIN_VALUE             = -1*2**(ACTIVATION_BIT_WIDTH-1),
        parameter  ACTIVATION_MAX_VALUE             = 2**(ACTIVATION_BIT_WIDTH-1)-1,
        parameter  ARRAYS_SIZE                      = 1024,
        parameter  NUMBER_OF_COLS                   = 128,
        parameter  NUMBER_OF_CH                     = 64,
        parameter  NUMBER_OF_ROWS                   = 64,
        parameter  KERNEL_K                         = 3,
        parameter  NUMBER_OF_OUTPUT_COLS            = 128,
        parameter  NUMBER_OF_OUTPUT_CH              = 64,
        parameter  NUMBER_OF_OUTPUT_ROWS            = 64,
        parameter  BASE_DIRECTORY                   = "",
        parameter  REGISTER_WIDTH                   = 32,
        parameter  NUMBER_OF_REGISTERS              = 10
    );

        int row_i_number_of_entries [NUMBER_OF_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) row_i [NUMBER_OF_ROWS];

        int output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) ground_truth_output_row_i [NUMBER_OF_OUTPUT_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) output_row_i [NUMBER_OF_OUTPUT_ROWS];

        AXI_full_transfer #(
            .AXI_DATA_WIDTH   (AXI_BUS_DATA_BIT_WIDTH),
            .AXI_ADDRESS_WIDTH(AXI_BUS_ADDRESS_WIDTH),
            .WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH),
            .DATA_SIZE(ARRAYS_SIZE)   // Describes how many words should be transferred
        ) axi_full_transfer;

        AXI_full_transfer #(
            .AXI_DATA_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH),
            .AXI_ADDRESS_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH),
            .WORD_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH),
            .DATA_SIZE(NUMBER_OF_WEIGHT_ARRAY_ENTRIES)   // Describes how many words should be transferred
        ) weight_axi_full_transfer;

        AXI_lite_stimulus #(
            .AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH), 
            .AXI_ADDRESS_WIDTH(CONTROL_AXI_ADDR_WIDTH)
        ) axi_lite_stimulus;
        
        // logic[WEIGHT_AXI_BUS_DATA_BIT_WIDTH-1:0] weights_array_i [3][NUMBER_OF_WEIGHT_ARRAY_ENTRIES];
        memory_class #(.WORD_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(NUMBER_OF_WEIGHT_ARRAY_ENTRIES)) weights_array_i [3];
        int weight_array_i_number_of_entries[3];

        function automatic void create();
            axi_lite_stimulus = new();
            axi_full_transfer = new();
            weight_axi_full_transfer = new();
            for(int row_index = 0; row_index < NUMBER_OF_ROWS; row_index++) begin
                row_i[row_index] = new();
            end
            for(int row_index = 0; row_index < NUMBER_OF_OUTPUT_ROWS; row_index++) begin
                ground_truth_output_row_i[row_index] = new();
                output_row_i[row_index] = new();
            end
            for(int row_index = 0; row_index < 3; row_index++) begin
                weights_array_i[row_index] = new();
            end
        endfunction

        function automatic void initialize_constant_inputs();
            for(int row_index = 0; row_index < NUMBER_OF_ROWS; row_index++) begin
                for(int i = 0; i < ARRAYS_SIZE; i++) begin
                    for (int j=0; j<AXI_BUS_DATA_BIT_WIDTH/8; j++) begin
                        row_i[row_index].memory[i][(j+1)*8-1 -: 8] = i+j;     
                    end
                end
                row_i_number_of_entries[row_index] = NUMBER_OF_WEIGHT_ARRAY_ENTRIES;
            end
        endfunction

        function automatic void read_input();
            string txt_file;
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(row_index = 0; row_index < NUMBER_OF_ROWS; row_index++) begin
                txt_file = $sformatf("%sinput_activation_%0d.txt",BASE_DIRECTORY, row_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open input image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // row_i[row_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    row_i[row_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                row_i_number_of_entries[row_index] = i;
                $display("row_%0d_number_of_entries: %0d", row_index, i);
                $fclose(fd1);
            end
        endfunction


        function automatic void initialize_constant_weights();
            for(int array_index = 0; array_index < 3; array_index++) begin
                for(int i = 0; i < NUMBER_OF_WEIGHT_ARRAY_ENTRIES; i++) begin
                    for (int j=0; j<WEIGHT_AXI_BUS_DATA_BIT_WIDTH/8; j++) begin
                        weights_array_i[array_index].memory[i][(j+1)*8-1 -: 8] = 1;     
                    end
                end
                weight_array_i_number_of_entries[array_index] = NUMBER_OF_WEIGHT_ARRAY_ENTRIES;
            end
        endfunction

        function automatic void read_weights(
            input int layer_index
            );
            string txt_file;
            int array_index;
            int fd1;
            int i = 0;
            int status;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(array_index = 0; array_index < 3; array_index++) begin
                txt_file = $sformatf("%slayer_%0d/weight_array_%0d.txt",BASE_DIRECTORY, layer_index, array_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open input image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // weights_array_i[array_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    weights_array_i[array_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                weight_array_i_number_of_entries[array_index] = i;
                $display("weight_array_%0d_number_of_entries: %0d", array_index, i);
                $fclose(fd1);
            end
        endfunction

        function automatic void read_ground_truth_outputs(
            input int layer_index
            );
            string txt_file;
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(row_index = 0; row_index < NUMBER_OF_OUTPUT_ROWS; row_index++) begin
                txt_file = $sformatf("%slayer_%0d/output_activation_%0d.txt",BASE_DIRECTORY, layer_index, row_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open output image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // ground_truth_output_row_i[row_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    ground_truth_output_row_i[row_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                output_row_i_number_of_entries[row_index] = i;
                $display("output_row_%0d_number_of_entries: %0d", row_index, i);
                $fclose(fd1);
            end
        endfunction

        function automatic void validate_outputs();
            string txt_file;
            string output_one_result, output_two_result;
            string output_result[NUMBER_OF_OUTPUT_ROWS];
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] ground_truth_value;
            string ground_truth_value_string;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] output_value;
            string output_value_string;

            // output_one_result = "matched";
            // for (int j=0; j<output_row_i_number_of_entries[0]; j++) begin
            //     ground_truth_value  = $unsigned(ground_truth_output_row_i[0].memory[j]);
            //     output_value        = $unsigned(output_row_i[0].memory[j]);
            //     // if(j==0 || j == output_row_i_number_of_entries[0]-1) begin
            //     //     $display("PRINTING_VALUE: output_row_0 value %x --- ground truth value %x at index: %d", output_value, ground_truth_value, j);
            //     // end
            //     if((ground_truth_value!==output_value)) begin
            //             $display("WARNING: output_row_0 value %x did not match ground truth value %x at index: %d", output_value, ground_truth_value, j);
            //             output_one_result = "mismatched";

            //             // ground_truth_value_string  = ground_truth_value.itoa();
            //             // output_value_string        = output_value.itoa();
            //         // for(int ch_ptr=0; ch_ptr<AXI_BUS_DATA_BIT_WIDTH/2; ch_ptr=ch_ptr+2) begin //assumes weight precision is 8 bits
            //         //     // str.atoi
            //         //     // $display("WARNING: output_row_0 value %x did not match ground truth value %x at index: %d", output_value[ch_ptr:ch_ptr+1], ground_truth_value[ch_ptr:ch_ptr+1], ch_ptr);
            //         //     $display("WARNING: index: %d", ch_ptr);
            //         // end
            //         // return;
            //     end
            // end

            // output_two_result = "matched";
            // for (int j=0; j<output_row_i_number_of_entries[1]; j++) begin
            //     ground_truth_value  = $unsigned(ground_truth_output_row_i[1].memory[j]);
            //     output_value        = $unsigned(output_row_i[1].memory[j]);
            //     // $display("output_row_0 value %x did not match ground truth value %x at index: %d", output_value, ground_truth_value, j);
            //     // if((ground_truth_value!==output_value) && ground_truth_value<=ACTIVATION_MAX_VALUE && ground_truth_value>=ACTIVATION_MIN_VALUE) begin
            //     // if(j==0 || j == output_row_i_number_of_entries[1]-1) begin
            //     //     $display("PRINTING_VALUE: output_row_1 value %x --- ground truth value %x at index: %d", output_value, ground_truth_value, j);
            //     // end
            //     if((ground_truth_value!==output_value)) begin
            //         $display("WARNING: output_row_1 value %x did not match ground truth value %x at index: %d", output_value, ground_truth_value, j);
            //         output_two_result = "mismatched";

            //         // ground_truth_value_string  = string'(ground_truth_value);
            //         // output_value_string        = string'(output_value);
            //         // // $display("WARNING: output_row_1 value string %p --- ground truth value string %p ", output_value_string, ground_truth_value_string);
            //         // for(int ch_ptr=0; ch_ptr<ground_truth_value_string.len(); ch_ptr=ch_ptr+1) begin //assumes weight precision is 8 bits
            //         //     // str.atoi
            //         //     if(output_value_string[ch_ptr+:1] !== ground_truth_value_string[ch_ptr+:1]) begin
                       
            //         //         $display("WARNING: output_row_1 value %p did not match ground truth value %p at index: %d", output_value_string[ch_ptr+:1], ground_truth_value_string[ch_ptr+:1], ch_ptr);
            //         //     end
            //         // end
            //     end
            // end
            // $display("Output row 0 : %s", output_one_result);
            // $display("Output row 1 : %s", output_two_result);

            $display("NUMBER_OF_OUTPUT_ROWS %0d", NUMBER_OF_OUTPUT_ROWS);
            $display("output_row_i_number_of_entries[0] %0d", output_row_i_number_of_entries[0]);
            $display("output_row_i_number_of_entries[1] %0d", output_row_i_number_of_entries[1]);
            $display("output_row_i_number_of_entries[2] %0d", output_row_i_number_of_entries[2]);

            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                output_result[i] = "matched";
                for (int j=0; j<output_row_i_number_of_entries[i]; j++) begin
                    ground_truth_value  = $unsigned(ground_truth_output_row_i[i].memory[j]);
                    output_value        = $unsigned(output_row_i[i].memory[j]);
                    if((ground_truth_value!==output_value)) begin
                        // $display("WARNING: output_row_%0d value %x did not match ground truth value %x at index: %d", i, output_value, ground_truth_value, j);
                        output_result[i] = "mismatched";
                    end
                end    
            end
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                $display("Output row %0d : %s", i, output_result[i]);
            end
        endfunction

     
        task automatic create_export_file(
            input string file_name
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("%s", txt_file);
            fd1 = $fopen(txt_file,"w");
            
            $fwrite(fd1,"/* \n\ *   Institute of Neuroinformatics - Sensors Group - UZH/ETHz \n\ *   Title: \n\ *   Date:   18.03.2022 \n\ *   Author: hasan \n\ *   Description: \n\ */ \n\ \n\ #ifndef SRC_TEST_NEURAL_NET_H_ \n\ #define SRC_TEST_NEURAL_NET_H_ \n\ \n\  #define LAYER_0_INPUT_COLS  %0d \n\ #define LAYER_0_INPUT_ROWS  %0d \n\ #define LAYER_0_INPUT_CH    %0d \n\ #define LAYER_0_KERNEL_K    %0d \n\ #define LAYER_0_OUTPUT_COLS %0d \n\ #define LAYER_0_OUTPUT_ROWS %0d \n\ #define LAYER_0_OUTPUT_CH   %0d \n\ ", NUMBER_OF_COLS, NUMBER_OF_ROWS, NUMBER_OF_CH, KERNEL_K, NUMBER_OF_OUTPUT_COLS, NUMBER_OF_OUTPUT_ROWS, NUMBER_OF_OUTPUT_CH);
            

            $fclose(fd1);
            return;
        endtask


           
    // parameter CONTROL_FLAGS_REGISTER                    = NUMBER_OF_REGISTERS-1;
    // parameter integer PRE_REGISTER_LIST   [4:0] = {NUMBER_OF_CONV_LAYER_COLS_REGISTER, CHANNELS_MINUS_8_REGISTER, KERNEL_STEPS_MINUS_1_REGISTER, CHANNEL_STEPS_REGISTER, NUMBER_OF_CHANNELS_REGISTER}; // These are configured only once per layer.
    // parameter integer INTRA_REGISTER_LIST [3:0] = {STREAM_1_PTR_REGISTER, STREAM_2_PTR_REGISTER, STREAM_3_PTR_REGISTER, STREAM_WRITER_REGISTER}; // These are configured per trigger. CONTROL_FLAGS_REGISTER is configured per trigger.


        task automatic export_register_map(
            input string file_name,
            input int layer_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t PRE_REGISTER_LIST[5] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", NUMBER_OF_CONV_LAYER_COLS_REGISTER, CHANNELS_MINUS_8_REGISTER, KERNEL_STEPS_MINUS_1_REGISTER, CHANNEL_STEPS_REGISTER, NUMBER_OF_CHANNELS_REGISTER);

$fwrite(fd1,"\n\
uint32_t PRE_REGISTER_LIST[4] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", STREAM_1_PTR_REGISTER, STREAM_2_PTR_REGISTER, STREAM_3_PTR_REGISTER, STREAM_WRITER_REGISTER);
            $fclose(fd1);
            return;
        endtask

        task automatic export_pre_registers(
            input string file_name,
            input int layer_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t number_of_pre_reg = %0d;\n\
uint32_t number_of_intra_reg = %0d;\n\
uint32_t layer_%0d_pre_reg[5] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", NUMBER_OF_PRE_REGISTERS, NUMBER_OF_INTRA_REGISTERS, layer_index, register_file[NUMBER_OF_CONV_LAYER_COLS_REGISTER], 
                        register_file[CHANNELS_MINUS_8_REGISTER], 
                        register_file[KERNEL_STEPS_MINUS_1_REGISTER], 
                        register_file[CHANNEL_STEPS_REGISTER], 
                        register_file[NUMBER_OF_CHANNELS_REGISTER]);
            $fclose(fd1);
            return;
        endtask

//         task automatic export_intra_registers(
//             input string file_name,
//             input int layer_index,
//             input int output_row_index,
//             ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
//             );
//             string txt_file;
//             int fd1;
//             txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
//             fd1 = $fopen(txt_file,"a"); 
//             $fwrite(fd1,"\n\
// uint32_t layer_%0d_row_%0d_intra_reg[4] = { \n\
// 	0x%x, \n\
//     0x%x, \n\
//     0x%x, \n\
//     0x%x, \n\
// }; \n\ ", layer_index, output_row_index,  
//                         register_file[STREAM_1_PTR_REGISTER], 
//                         register_file[STREAM_2_PTR_REGISTER], 
//                         register_file[STREAM_3_PTR_REGISTER], 
//                         register_file[STREAM_WRITER_REGISTER]);
//             $fclose(fd1);
//             return;
//         endtask

        task automatic start_intra_registers_array(
            input string file_name,
            input int layer_index,
            input int number_of_rows,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t layer_%0d_intra_reg[%0d] = { \n\ ", layer_index, NUMBER_OF_INTRA_REGISTERS*number_of_rows);
            $fclose(fd1);
            return;
        endtask

        task automatic append_intra_registers_array(
            input string file_name,
            input int layer_index,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\ ",    register_file[CONTROL_FLAGS_REGISTER], 
                    register_file[STREAM_1_PTR_REGISTER], 
                    register_file[STREAM_2_PTR_REGISTER], 
                    register_file[STREAM_3_PTR_REGISTER], 
                    register_file[STREAM_WRITER_REGISTER]);
            $fclose(fd1);
            return;
        endtask

        task automatic close_intra_registers_array(
            input string file_name,
            input int layer_index,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
}; \n\ ");
            $fclose(fd1);
            return;
        endtask

        task automatic export_register_file(
            input string file_name,
            input int layer_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t layer_%0d_reg_file[10] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
	0x%x  \n\
}; \n\ ", layer_index, register_file[0], register_file[1], register_file[2], register_file[3], register_file[4], 
                                                 register_file[5], register_file[6], register_file[7], register_file[8], register_file[9]);
            $fclose(fd1);
            return;
        endtask

        task automatic export_activations_and_weights(
                input string file_name
            );
            string txt_file;
            int fd1;
            int total_number_of_input_activations_entries = 0;
            int total_number_of_output_activations_entries = 0;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("exporting activations and weights");
            fd1 = $fopen(txt_file,"a"); 

            //----------------
            // write input activations
            //----------------
            for (int i=0; i<NUMBER_OF_ROWS; i++) begin
                total_number_of_input_activations_entries = total_number_of_input_activations_entries + this.row_i_number_of_entries[i]; 
            end

$fwrite(fd1,"\n\
uint64_t number_of_entries_per_row[LAYER_0_INPUT_ROWS] = { \n\ ");

            for (int i=0; i<NUMBER_OF_ROWS-1; i++) begin
                $fwrite(fd1,"	%0d, \n\ ", this.row_i_number_of_entries[i]);
            end
            $fwrite(fd1,"	%0d \n\ }; \n\ ", this.row_i_number_of_entries[NUMBER_OF_ROWS-1]);
            $fwrite(fd1,"uint64_t total_number_of_input_activations_entries = %0d; \n\ ", total_number_of_input_activations_entries);


            $fwrite(fd1,"uint64_t input_activations[%0d] = { \n\ ", total_number_of_input_activations_entries);
            for (int i=0; i<NUMBER_OF_ROWS; i++) begin
                if (i==NUMBER_OF_ROWS-1) begin
                    for (int j=0; j<this.row_i_number_of_entries[i]-1; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", this.row_i[i].memory[j]);
                    end
                end
                else begin
                    for (int j=0; j<this.row_i_number_of_entries[i]; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", this.row_i[i].memory[j]);
                    end
                end
            end
            $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.row_i[NUMBER_OF_ROWS-1].memory[this.row_i_number_of_entries[NUMBER_OF_ROWS-1]-1]);
                // $fwrite(fd1,"\n\ }; \n\ ");

            //----------------
            // write output ground truth activations
            //----------------
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                total_number_of_output_activations_entries = total_number_of_output_activations_entries + this.output_row_i_number_of_entries[i]; 
            end
            $fwrite(fd1,"uint64_t number_of_entries_per_output_row[LAYER_0_OUTPUT_ROWS] = { \n\ ");
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS-1; i++) begin
                $fwrite(fd1,"	%0d, \n\ ", this.output_row_i_number_of_entries[i]);
            end
            $fwrite(fd1,"	%0d \n\ }; \n\ ", this.output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS-1]);
            $fwrite(fd1,"uint64_t total_number_of_output_activations_entries = %0d; \n\ ", total_number_of_output_activations_entries);

            $fwrite(fd1,"uint64_t ground_truth_output_activations[%0d] = { \n\ ", total_number_of_output_activations_entries);
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                if (i==NUMBER_OF_OUTPUT_ROWS-1) begin
                    for (int j=0; j<this.output_row_i_number_of_entries[i]-1; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", this.ground_truth_output_row_i[i].memory[j]);
                    end
                end
                else begin
                    for (int j=0; j<this.output_row_i_number_of_entries[i]; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", this.ground_truth_output_row_i[i].memory[j]);
                    end
                end
            end
            $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.ground_truth_output_row_i[NUMBER_OF_OUTPUT_ROWS-1].memory[this.output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS-1]-1]);
            // $fwrite(fd1,"\n #endif /* SRC_TEST_NEURAL_NET_H_ */ \n\ ");

            //----------------
            // write layer weights
            //----------------
            $fwrite(fd1,"uint64_t number_of_entries_per_weight_array = %0d; \n\ ", this.weight_array_i_number_of_entries[0]);
            for (int i=0; i<3; i++) begin
                $fwrite(fd1,"uint64_t weight_array_%0d[%0d] = { \n\ ", i, this.weight_array_i_number_of_entries[i]);
                for (int j=0; j<this.weight_array_i_number_of_entries[i]-1; j++) begin
                    $fwrite(fd1,"	0x%x, \n\ ", this.weights_array_i[i].memory[j]);
                end
                $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.weights_array_i[i].memory[this.weight_array_i_number_of_entries[i]-1]);
            end
            // $fwrite(fd1,"\n #endif /* SRC_TEST_NEURAL_NET_H_ */ \n\ ");
            $fclose(fd1);
            return;
        endtask

        task automatic close_export_file(
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

    endclass

    class neural_network_layer #(
        parameter  LAYER_ID                             = 0,
        parameter  NUMBER_OF_WEIGHT_ARRAY_ENTRIES       = 64,
        parameter  NUMBER_OF_BIAS_ARRAY_ENTRIES         = 64,
        parameter  ARRAYS_SIZE                          = 1024,
        parameter  AXI_BUS_DATA_BIT_WIDTH               = 64,
        parameter  AXI_BUS_ADDRESS_WIDTH                = 17,
        parameter  WEIGHT_AXI_BUS_DATA_BIT_WIDTH        = 64,
        parameter  WEIGHT_AXI_BUS_ADDRESS_WIDTH         = 16,
        parameter  CONTROL_AXI_DATA_WIDTH               = 64,
        parameter  CONTROL_AXI_ADDR_WIDTH               = 64,
        parameter  STRIDED_CONV                         = 0,
        parameter  BIAS_ENABLE                          = 0,
        parameter  RELU_ENABLE                          = 1,
        parameter  COMPRESS_OUTPUT                      = 1,
        parameter  Q_SCALE                              = 4096,   
        parameter  KERNEL_STEPS                         = 64,
        parameter  CHANNEL_STEPS                        = 64,
        parameter  OUTPUT_SLICES                        = 64,
        parameter  SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS   = 64,
        parameter  INPUT_NUMBER_OF_COLS                 = 128,
        parameter  INPUT_NUMBER_OF_CH                   = 64,
        parameter  INPUT_NUMBER_OF_ROWS                 = 64,
        parameter  KERNEL_K                             = 3,
        parameter  NUMBER_OF_OUTPUT_COLS                = 128,
        parameter  NUMBER_OF_OUTPUT_CH                  = 64,
        parameter  NUMBER_OF_OUTPUT_ROWS                = 64,
        parameter  REGISTER_WIDTH                       = 32,
        parameter  NUMBER_OF_REGISTERS                  = 10,
        parameter  BASE_DIRECTORY                       = "",
        parameter  export_file_name                     = "",
        parameter  AXI_BYTE_ACCESS_BITS                 = 1024,
        parameter  OUTPUT_LINE_0_START_ADDRESS          = 1024,
        parameter  OUTPUT_LINE_1_START_ADDRESS          = 1024,
        parameter  OUTPUT_LINE_2_START_ADDRESS          = 1024
    );

        int row_i_number_of_entries [INPUT_NUMBER_OF_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) row_i [INPUT_NUMBER_OF_ROWS];
        int output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) ground_truth_output_row_i [NUMBER_OF_OUTPUT_ROWS];
        memory_class #(.WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(ARRAYS_SIZE)) output_row_i [NUMBER_OF_OUTPUT_ROWS];
        memory_class #(.WORD_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(NUMBER_OF_WEIGHT_ARRAY_ENTRIES)) weights_array_i [3];
        memory_class #(.WORD_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH), .MEMORY_DEPTH(NUMBER_OF_WEIGHT_ARRAY_ENTRIES)) bias_array;
        int weight_array_i_number_of_entries[3];
        int bias_array_number_of_entries;

        AXI_full_transfer #(
            .AXI_DATA_WIDTH(AXI_BUS_DATA_BIT_WIDTH),
            .AXI_ADDRESS_WIDTH(AXI_BUS_ADDRESS_WIDTH),
            .WORD_WIDTH(AXI_BUS_DATA_BIT_WIDTH),
            .DATA_SIZE(ARRAYS_SIZE)   // Describes how many words should be transferred
        ) axi_full_transfer;

        AXI_full_transfer #(
            .AXI_DATA_WIDTH   (WEIGHT_AXI_BUS_DATA_BIT_WIDTH),
            .AXI_ADDRESS_WIDTH(WEIGHT_AXI_BUS_ADDRESS_WIDTH),
            .WORD_WIDTH(WEIGHT_AXI_BUS_DATA_BIT_WIDTH),
            .DATA_SIZE(NUMBER_OF_WEIGHT_ARRAY_ENTRIES)   // Describes how many words should be transferred
        ) weight_axi_full_transfer;

        AXI_lite_stimulus #(
            .AXI_DATA_WIDTH(CONTROL_AXI_DATA_WIDTH), 
            .AXI_ADDRESS_WIDTH(CONTROL_AXI_ADDR_WIDTH)
        ) axi_lite_stimulus;

        function automatic void create();
            axi_lite_stimulus = new();
            axi_full_transfer = new();
            weight_axi_full_transfer = new();
            for(int row_index = 0; row_index < INPUT_NUMBER_OF_ROWS; row_index++) begin
                row_i[row_index] = new();
            end
            for(int row_index = 0; row_index < NUMBER_OF_OUTPUT_ROWS; row_index++) begin
                ground_truth_output_row_i[row_index] = new();
                output_row_i[row_index] = new();
            end
            for(int row_index = 0; row_index < 3; row_index++) begin
                weights_array_i[row_index] = new();
            end
            bias_array = new();
        endfunction

        function automatic void read_input();
            string txt_file;
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            $display("reading input.");
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(row_index = 0; row_index < INPUT_NUMBER_OF_ROWS; row_index++) begin
                txt_file = $sformatf("%sinput_activations/input_activation_%0d.txt",BASE_DIRECTORY, row_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open input image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // row_i[row_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    row_i[row_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                row_i_number_of_entries[row_index] = i;
                // $display("row_%0d_number_of_entries: %0d", row_index, i);
                $fclose(fd1);
            end
                $display("finished reading input.");
        endfunction

        function automatic void read_weights();
            string txt_file;
            int array_index;
            int fd1;
            int i = 0;
            int status;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(array_index = 0; array_index < 3; array_index++) begin
                txt_file = $sformatf("%slayer_%0d/weight_array_%0d.txt",BASE_DIRECTORY, LAYER_ID, array_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open input image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // weights_array_i[array_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    weights_array_i[array_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                weight_array_i_number_of_entries[array_index] = i;
                // $display("weight_array_%0d_number_of_entries: %0d", array_index, i);
                $fclose(fd1);
            end
            if(this.BIAS_ENABLE) begin
                txt_file = $sformatf("%slayer_%0d/bias_array.txt",BASE_DIRECTORY, LAYER_ID);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open bias array file!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    if(status==-1)
                        break;
                    bias_array.memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                bias_array_number_of_entries = i;
                $fclose(fd1);
            end
            
        endfunction

        function automatic void read_ground_truth_outputs();
            string txt_file;
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            if(BASE_DIRECTORY=="") begin
                $display("Empty text files directory name.");
                return;
            end
            for(row_index = 0; row_index < NUMBER_OF_OUTPUT_ROWS; row_index++) begin
                // txt_file = $sformatf("%slayer_%0d/output_activation_%0d.txt",BASE_DIRECTORY, LAYER_ID, row_index);
                txt_file = $sformatf("%slayer_%0d/compressed_output_activation_%0d.txt",BASE_DIRECTORY, LAYER_ID, row_index);
                // $display("txt_file: %s", txt_file);
                fd1 = $fopen(txt_file, "r");
                if(!fd1) begin
                    $display("Failed to open output image!");
                    return;
                end
                i = 0;
                while(1) begin
                    status = $fscanf(fd1,"%h",line);
                    // $display("%d", status);
                    // $display("%x", line);
                    if(status==-1)
                        break;
                    // ground_truth_output_row_i[row_index][i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    ground_truth_output_row_i[row_index].memory[i] = line[AXI_BUS_DATA_BIT_WIDTH-1:0];
                    i++;
                end
                output_row_i_number_of_entries[row_index] = i;
                // $display("output_row_%0d_number_of_entries: %0d", row_index, i);
                $fclose(fd1);
            end
        endfunction

        function automatic void validate_outputs();
            string txt_file;
            string output_one_result, output_two_result;
            string output_result[NUMBER_OF_OUTPUT_ROWS];
            int row_index;
            int i = 0;
            int status;
            int fd1;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] line;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] ground_truth_value;
            string ground_truth_value_string;
            logic[AXI_BUS_DATA_BIT_WIDTH-1:0] output_value;
            string output_value_string;

            $display("NUMBER_OF_OUTPUT_ROWS %0d", NUMBER_OF_OUTPUT_ROWS);
            $display("output_row_i_number_of_entries[0] %0d", output_row_i_number_of_entries[0]);
            $display("output_row_i_number_of_entries[1] %0d", output_row_i_number_of_entries[1]);
            $display("output_row_i_number_of_entries[2] %0d", output_row_i_number_of_entries[2]);

            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                output_result[i] = "matched";
                for (int j=0; j<output_row_i_number_of_entries[i]; j++) begin
                    ground_truth_value  = $unsigned(ground_truth_output_row_i[i].memory[j]);
                    output_value        = $unsigned(output_row_i[i].memory[j]);
                    if((ground_truth_value!==output_value)) begin
                        $display("WARNING: output_row_%0d value %x did not match ground truth value %x at index: %d", i, output_value, ground_truth_value, j);
                        output_result[i] = "mismatched";
                    end
                end    
            end
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                $display("Output row %0d : %s", i, output_result[i]);
            end
        endfunction

        task automatic execute(
            virtual s_axi_bus #(
                .C_S_AXI_ID_WIDTH(1),
                .C_S_AXI_DATA_WIDTH(this.AXI_BUS_DATA_BIT_WIDTH),
                .C_S_AXI_ADDR_WIDTH(this.AXI_BUS_ADDRESS_WIDTH)
            ) data_bus,
            virtual s_axi_bus #(
                .C_S_AXI_ID_WIDTH(1),
                .C_S_AXI_DATA_WIDTH(this.WEIGHT_AXI_BUS_DATA_BIT_WIDTH),
                .C_S_AXI_ADDR_WIDTH(this.WEIGHT_AXI_BUS_ADDRESS_WIDTH)
            ) weight_bus,
            virtual s_axi_lite_bus #(
                .C_S_AXI_DATA_WIDTH(this.CONTROL_AXI_DATA_WIDTH),
                .C_S_AXI_ADDR_WIDTH(this.CONTROL_AXI_ADDR_WIDTH)
            ) control_bus,

            // Call by reference enables the task to read and write the external signals at execution
            ref logic                           clk,
            ref logic                           next_command_interrupt,
            ref logic                           output_line_stored
            );

        // neural_network_layer layer;

        // logic next_command_interrupt;
        // logic output_line_stored;
        logic [REGISTER_WIDTH-1:0] output_line_i_end_address [NUMBER_OF_OUTPUT_ROWS];
        int address_offset;
        int input_line_address;
        int output_line_address,stream_writer_address, reg_file_stream_writer_address;
        int relative_row_0, relative_row_1, relative_row_2;
        int stream_read_0_address, stream_read_1_address, stream_read_2_address;
        int input_row_index;
        int previous_line_index;
        int next_line_index;
        int max_entries;
        int stream_read_0_enable, stream_read_1_enable, stream_read_2_enable;
        int unsigned output_line_i_length [NUMBER_OF_OUTPUT_ROWS];
        logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1];

        // $display("inside data_bus, data_bus.C_S_AXI_DATA_WIDTH=%0d, data_bus.C_S_AXI_ADDR_WIDTH=%0d", data_bus.C_S_AXI_DATA_WIDTH, data_bus.C_S_AXI_ADDR_WIDTH);
        // $display("inside weight_bus, weight_bus.C_S_AXI_DATA_WIDTH=%0d, weight_bus.C_S_AXI_ADDR_WIDTH=%0d", weight_bus.C_S_AXI_DATA_WIDTH, weight_bus.C_S_AXI_ADDR_WIDTH);
        // $display("inside control_bus, control_bus.C_S_AXI_DATA_WIDTH=%0d, control_bus.C_S_AXI_ADDR_WIDTH=%0d", control_bus.C_S_AXI_DATA_WIDTH, control_bus.C_S_AXI_ADDR_WIDTH);

        for(int i = 0; i < NUMBER_OF_REGISTERS; i++) begin
            register_file[i] = 32'h0000_0000;
        end

        // $display("inside execute");

        fork 
            // transfer weight data
            begin
                // Transfer weights 0
                this.weight_axi_full_transfer.write_data(
                    .data(this.weights_array_i[0]),
                    .transfer_size(this.weight_array_i_number_of_entries[0]),
                    .start_address(WEIGHT_LINE_BUFFER_0_START_ADDRESS),
                    .memory_bus(weight_bus)
                );
                @(posedge clk);
                // Transfer weights 1
                this.weight_axi_full_transfer.write_data(
                    .data(this.weights_array_i[1]),
                    .transfer_size(this.weight_array_i_number_of_entries[1]),
                    .start_address(WEIGHT_LINE_BUFFER_1_START_ADDRESS),
                    .memory_bus(weight_bus)
                );
                @(posedge clk);
                // Transfer weights 2
                this.weight_axi_full_transfer.write_data(
                    .data(this.weights_array_i[2]),
                    .transfer_size(this.weight_array_i_number_of_entries[2]),
                    .start_address(WEIGHT_LINE_BUFFER_2_START_ADDRESS),
                    .memory_bus(weight_bus)
                );
                @(posedge clk);
                // Transfer bias
                this.weight_axi_full_transfer.write_data(
                    .data(this.bias_array),
                    .transfer_size(this.bias_array_number_of_entries),
                    .start_address(BIAS_LINE_BUFFER_START_ADDRESS),
                    .memory_bus(weight_bus)
                );

            end

            begin
                input_row_index = 0;
                // line one 
                this.axi_full_transfer.write_data(
                    .data(this.row_i[input_row_index]),
                    .transfer_size(this.row_i_number_of_entries[input_row_index]),
                    .start_address(ACTIVATION_LINE_BUFFER_0_START_ADDRESS),
                    .memory_bus(data_bus)
                );
                input_row_index++;
                @(posedge clk);
                // line two 
                this.axi_full_transfer.write_data(
                    .data(this.row_i[input_row_index]),
                    .transfer_size(this.row_i_number_of_entries[input_row_index]),
                    .start_address(ACTIVATION_LINE_BUFFER_1_START_ADDRESS),
                    .memory_bus(data_bus)
                );
                input_row_index++;
            end
        join
        wait fork;

        @(posedge clk); 
        // pre-registers
        register_file[NUMBER_OF_CONV_LAYER_COLS_REGISTER][NUMBER_OF_CONV_LAYER_COLS_MSB:NUMBER_OF_CONV_LAYER_COLS_LSB]                      = this.INPUT_NUMBER_OF_COLS;
        register_file[EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_REGISTER][EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_MSB:EXPECTED_TOTAL_NUMBER_OF_OUTPUTS_LSB] = this.SINGLE_ROW_TOTAL_NUMBER_OF_OUTPUTS;
        register_file[NUMBER_OF_CHANNELS_REGISTER][NUMBER_OF_CHANNELS_MSB:NUMBER_OF_CHANNELS_LSB]                                           = this.INPUT_NUMBER_OF_CH;  
        register_file[CHANNELS_MINUS_8_REGISTER][CHANNELS_MINUS_8_MSB:CHANNELS_MINUS_8_LSB]                                                 = this.INPUT_NUMBER_OF_CH-8;  
        register_file[QUANTIZATION_SCALE_REGISTER][QUANTIZATION_SCALE_MSB:QUANTIZATION_SCALE_LSB]                                           = this.Q_SCALE;  
        register_file[KERNEL_STEPS_MINUS_1_REGISTER][KERNEL_STEPS_MINUS_1_MSB:KERNEL_STEPS_MINUS_1_LSB]                                     = this.KERNEL_STEPS-1;
        register_file[NUMBER_OF_OUTPUT_SLICING_STEPS_REGISTER][NUMBER_OF_OUTPUT_SLICING_STEPS_MSB:NUMBER_OF_OUTPUT_SLICING_STEPS_LSB]       = this.OUTPUT_SLICES; // TODO: calculate me properly
        register_file[CHANNEL_STEPS_REGISTER][CHANNEL_STEPS_MSB:CHANNEL_STEPS_LSB]                                                          = this.CHANNEL_STEPS;  
        register_file[BIAS_STEPS_REGISTER][BIAS_STEPS_MSB:BIAS_STEPS_LSB]                                                                   = this.KERNEL_STEPS*this.OUTPUT_SLICES;  
        register_file[CONTROL_FLAGS_REGISTER][STRIDED_CONV_BIT_INDEX]                                                                       = this.STRIDED_CONV;
        register_file[CONTROL_FLAGS_REGISTER][PW_CONV_BIT_INDEX]                                                                            = 0;
        register_file[CONTROL_FLAGS_REGISTER][ENABLE_ELEMENT_WISE_BUFFER_BIT_INDEX]                                                         = 0;
        register_file[CONTROL_FLAGS_REGISTER][ELEMENT_WISE_ADD_BIT_INDEX]                                                                   = 0;
        register_file[CONTROL_FLAGS_REGISTER][BIAS_ENABLE_BIT_INDEX]                                                                        = this.BIAS_ENABLE;
        register_file[CONTROL_FLAGS_REGISTER][RELU_ENABLE_BIT_INDEX]                                                                        = this.RELU_ENABLE;
        register_file[CONTROL_FLAGS_REGISTER][STREAM_MODE_BIT_INDEX]                                                                        = SPARSE_MODE;
        // register_file[CONTROL_FLAGS_REGISTER][STREAM_MODE_BIT_INDEX]                                                                        = DENSE_MODE;
        register_file[CONTROL_FLAGS_REGISTER][COMPRESS_OUTPUT_BIT_INDEX]                                                                    = this.COMPRESS_OUTPUT;

        
        @(posedge clk);
        foreach (PRE_REGISTER_LIST[i]) begin
            @(posedge clk); 
            // $display("i=%0d, PRE_REGISTER_LIST[i]=%0d, register_file[PRE_REGISTER_LIST[i]]=%0x", i, PRE_REGISTER_LIST[i], register_file[PRE_REGISTER_LIST[i]]);
            this.axi_lite_stimulus.write_AXI_lite_data(
                .data           (register_file[PRE_REGISTER_LIST[i]]),
                .address        (PRE_REGISTER_LIST[i]*REGISTER_WIDTH/8), // Byte address
                .AXI_ACLK       (clk),
                .AXI_AWADDR     (control_bus.S_AXI_AWADDR),
                .AXI_AWVALID    (control_bus.S_AXI_AWVALID),
                .AXI_AWREADY    (control_bus.S_AXI_AWREADY),
                .AXI_WDATA      (control_bus.S_AXI_WDATA),
                .AXI_WSTRB      (control_bus.S_AXI_WSTRB),
                .AXI_WVALID     (control_bus.S_AXI_WVALID),
                .AXI_WREADY     (control_bus.S_AXI_WREADY),
                .AXI_BRESP      (control_bus.S_AXI_BRESP),
                .AXI_BVALID     (control_bus.S_AXI_BVALID),
                .AXI_BREADY     (control_bus.S_AXI_BREADY)
            );    
        end

        export_layer_parameters(export_file_name);
        export_pre_registers(export_file_name, register_file);

        @(posedge clk); 
        relative_row_0 = 1;
        relative_row_1 = 2;
        relative_row_2 = 0;
        stream_read_0_address = 0;
        stream_read_1_address = 0;
        stream_read_2_address = 0;
        stream_read_0_enable = 1;
        stream_read_1_enable = 1;
        stream_read_2_enable = 0;
        // intra-registers
        register_file[CONTROL_FLAGS_REGISTER][STREAM_1_ENABLE_INDEX]                                                                        = stream_read_0_enable;
        register_file[STREAM_1_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_1_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_0; 
        register_file[STREAM_1_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_0_address; 

        register_file[CONTROL_FLAGS_REGISTER][STREAM_2_ENABLE_INDEX]                                                                        = stream_read_1_enable;
        register_file[STREAM_2_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_2_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_1; 
        register_file[STREAM_2_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_1_address; 

        register_file[CONTROL_FLAGS_REGISTER][STREAM_3_ENABLE_INDEX]                                                                        = stream_read_2_enable;
        register_file[STREAM_3_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
        register_file[STREAM_3_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_2; 
        register_file[STREAM_3_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_2_address; 
        register_file[STREAM_WRITER_REGISTER][STREAM_WRITER_ADDRESS_MSB:STREAM_WRITER_ADDRESS_LSB]                                          = OUTPUT_LINE_0_START_ADDRESS; 

        @(posedge clk);
        foreach (INTRA_REGISTER_LIST[i]) begin
            @(posedge clk); 
            // $display("i=%0d, INTRA_REGISTER_LIST[i]=%0d, register_file[INTRA_REGISTER_LIST[i]]=%0x", i, INTRA_REGISTER_LIST[i], register_file[INTRA_REGISTER_LIST[i]]);
            this.axi_lite_stimulus.write_AXI_lite_data(
                .data           (register_file[INTRA_REGISTER_LIST[i]]),
                .address        (INTRA_REGISTER_LIST[i]*REGISTER_WIDTH/8), // Byte address
                .AXI_ACLK       (clk),
                .AXI_AWADDR     (control_bus.S_AXI_AWADDR),
                .AXI_AWVALID    (control_bus.S_AXI_AWVALID),
                .AXI_AWREADY    (control_bus.S_AXI_AWREADY),
                .AXI_WDATA      (control_bus.S_AXI_WDATA),
                .AXI_WSTRB      (control_bus.S_AXI_WSTRB),
                .AXI_WVALID     (control_bus.S_AXI_WVALID),
                .AXI_WREADY     (control_bus.S_AXI_WREADY),
                .AXI_BRESP      (control_bus.S_AXI_BRESP),
                .AXI_BVALID     (control_bus.S_AXI_BVALID),
                .AXI_BREADY     (control_bus.S_AXI_BREADY)
            );    
        end

        start_intra_registers_array(export_file_name, this.NUMBER_OF_OUTPUT_ROWS, 0, register_file); // output_row_index = 0
        append_intra_registers_array(export_file_name, 0, register_file); // output_row_index = 0
        

        @(posedge clk); 
        // execution flag trigger
        register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX]  = 1;
        this.axi_lite_stimulus.write_AXI_lite_data(
            .data(register_file[CONTROL_FLAGS_REGISTER]),
            .address((CONTROL_FLAGS_REGISTER)*REGISTER_WIDTH/8), // Byte address
            .AXI_ACLK(clk),
            .AXI_AWADDR (control_bus.S_AXI_AWADDR),
            .AXI_AWVALID(control_bus.S_AXI_AWVALID),
            .AXI_AWREADY(control_bus.S_AXI_AWREADY),
            .AXI_WDATA  (control_bus.S_AXI_WDATA),
            .AXI_WSTRB  (control_bus.S_AXI_WSTRB),
            .AXI_WVALID (control_bus.S_AXI_WVALID),
            .AXI_WREADY (control_bus.S_AXI_WREADY),
            .AXI_BRESP  (control_bus.S_AXI_BRESP),
            .AXI_BVALID (control_bus.S_AXI_BVALID),
            .AXI_BREADY (control_bus.S_AXI_BREADY)
        );    

        @(posedge clk); 
        // start stream readers trigger
        register_file[CONTROL_FLAGS_REGISTER][START_STREAM_READERS_BIT_INDEX]  = 1;
        this.axi_lite_stimulus.write_AXI_lite_data(
            .data(register_file[CONTROL_FLAGS_REGISTER]),
            .address((CONTROL_FLAGS_REGISTER)*REGISTER_WIDTH/8), // Byte address
            .AXI_ACLK(clk),
            .AXI_AWADDR (control_bus.S_AXI_AWADDR),
            .AXI_AWVALID(control_bus.S_AXI_AWVALID),
            .AXI_AWREADY(control_bus.S_AXI_AWREADY),
            .AXI_WDATA  (control_bus.S_AXI_WDATA),
            .AXI_WSTRB  (control_bus.S_AXI_WSTRB),
            .AXI_WVALID (control_bus.S_AXI_WVALID),
            .AXI_WREADY (control_bus.S_AXI_WREADY),
            .AXI_BRESP  (control_bus.S_AXI_BRESP),
            .AXI_BVALID (control_bus.S_AXI_BVALID),
            .AXI_BREADY (control_bus.S_AXI_BREADY)
        );    

        // --------------------------------------
        // ------ Trigger Loop 
	    // --------------------------------------   
        // $display("inside NUMBER_OF_OUTPUT_ROWS=%0d", NUMBER_OF_OUTPUT_ROWS);
        for(int output_row_index = 1; output_row_index < this.NUMBER_OF_OUTPUT_ROWS+1; output_row_index++) begin
            
            // @(posedge clk);
            // $display("wait next_command_interrupt");
            wait (next_command_interrupt == 1'b1);
            // $display("wait next_command_interrupt");
            // @(posedge clk);
            // $display("wait output_line_stored");
            wait (output_line_stored == 1'b1);
            
            // $display("inside output_row_index=%0d", output_row_index);

            // $display("output_row_index=%0d", output_row_index);
            @(posedge clk);
            // read output_line_end_address
            this.axi_lite_stimulus.read_AXI_lite_data(
                .data(output_line_i_end_address[output_row_index-1]),
                .address(0), // Byte address
                .AXI_ACLK(clk),
                .AXI_ARADDR (control_bus.S_AXI_ARADDR),
                .AXI_ARVALID(control_bus.S_AXI_ARVALID),
                .AXI_ARREADY(control_bus.S_AXI_ARREADY),
                .AXI_RDATA  (control_bus.S_AXI_RDATA),
                .AXI_RRESP  (control_bus.S_AXI_RRESP),
                .AXI_RVALID (control_bus.S_AXI_RVALID),
                .AXI_RREADY (control_bus.S_AXI_RREADY)
            );

            @(posedge clk);
            // stream_writer_address = OUTPUT_LINE_0_START_ADDRESS; // only one output line buffer (minized implementation)
            // output_line_address = ACTIVATION_LINE_BUFFER_3_START_ADDRESS; // only one output line buffer (minized implementation)
            case ((output_row_index-1)%3) // 3 output activation line buffers
                0: stream_writer_address = OUTPUT_LINE_0_START_ADDRESS;
                1: stream_writer_address = OUTPUT_LINE_1_START_ADDRESS;
                2: stream_writer_address = OUTPUT_LINE_2_START_ADDRESS;
                default: stream_writer_address = OUTPUT_LINE_0_START_ADDRESS;
            endcase
            case ((output_row_index-1)%3) // 3 output activation line buffers
                0: output_line_address = ACTIVATION_LINE_BUFFER_3_START_ADDRESS;
                1: output_line_address = ACTIVATION_LINE_BUFFER_4_START_ADDRESS;
                2: output_line_address = ACTIVATION_LINE_BUFFER_5_START_ADDRESS;
                default: output_line_address = ACTIVATION_LINE_BUFFER_3_START_ADDRESS;
            endcase
            @(posedge clk);
            output_line_i_length[output_row_index-1] = output_line_i_end_address[output_row_index-1]-stream_writer_address; // ??
            // $display("output_row_index=%0d", output_row_index);
            // $display("output_line_i_length[output_row_index-1]=%0d", output_line_i_length[output_row_index-1]);
            // $display("output_line_i_end_address[output_row_index-1]=%0d", output_line_i_end_address[output_row_index-1]);
            // $display("stream_writer_address=%0d", stream_writer_address);
            @(posedge clk);
            // read computed output_line
            this.axi_full_transfer.read_data(
                .data(this.output_row_i[output_row_index-1]),
                .transfer_size(output_line_i_length[output_row_index-1]+1),
                .start_address(output_line_address),
                .memory_bus(data_bus)
            );

            if(output_row_index==this.NUMBER_OF_OUTPUT_ROWS) begin
                break;
            end

            @(posedge clk);
            // reg_file_stream_writer_address = OUTPUT_LINE_0_START_ADDRESS; // only one output line buffer (minized implementation)
            case (output_row_index%3) // 3 output activation line buffers
                0: reg_file_stream_writer_address = OUTPUT_LINE_0_START_ADDRESS;
                1: reg_file_stream_writer_address = OUTPUT_LINE_1_START_ADDRESS;
                2: reg_file_stream_writer_address = OUTPUT_LINE_2_START_ADDRESS;
                default: reg_file_stream_writer_address = OUTPUT_LINE_0_START_ADDRESS;
            endcase

            @(posedge clk);
            if (STRIDED_CONV==0) begin
                case (output_row_index%3) // 3 output activation line buffers
                    0: begin
                        relative_row_0 = 1;
                        relative_row_1 = 2;
                        relative_row_2 = 0;
                    end
                    1: begin
                        relative_row_0 = 0;
                        relative_row_1 = 1;
                        relative_row_2 = 2;
                    end
                    2: begin
                        relative_row_0 = 2;
                        relative_row_1 = 0;
                        relative_row_2 = 1;
                    end
                    default: begin
                        relative_row_0 = 0;
                        relative_row_1 = 1;
                        relative_row_2 = 2;
                    end
                endcase
            end
            else begin
                case (output_row_index%3) // 3 output activation line buffers
                    0: begin
                        relative_row_0 = 1;
                        relative_row_1 = 2;
                        relative_row_2 = 0;
                    end
                    1: begin
                        relative_row_0 = 2;
                        relative_row_1 = 0;
                        relative_row_2 = 1;
                    end
                    2: begin
                        relative_row_0 = 0;
                        relative_row_1 = 1;
                        relative_row_2 = 2;
                    end
                    default: begin
                        relative_row_0 = 0;
                        relative_row_1 = 1;
                        relative_row_2 = 2;
                    end
                endcase
            end 

            for (int lines_to_send = 0; lines_to_send<STRIDED_CONV+1; lines_to_send++)begin
            // for (int lines_to_send = 0; lines_to_send<1; lines_to_send++)begin
                @(posedge clk); 
                if (input_row_index%6 >= 3) begin
                    previous_line_index = input_row_index-3;
                    next_line_index = input_row_index+3;
                    // max_entries = max(this.row_i_number_of_entries[previous_line_index], this.row_i_number_of_entries[next_line_index]);
                    max_entries = 128;
                    

                    @(posedge clk);
                    address_offset = max_entries + (ACTIVATION_BUFFER_BANK_COUNT-max_entries%ACTIVATION_BUFFER_BANK_COUNT); 
                    // $display("address_offset=%0d", address_offset);
                    @(posedge clk);
                    address_offset = address_offset << AXI_BYTE_ACCESS_BITS;
                    // $display("address_offset=%0d", address_offset);
                end
                else begin
                    address_offset = 0;
                    max_entries = 0;
                    @(posedge clk);
                end
                
                @(posedge clk);
                case (input_row_index%3) // 3 activation line buffers
                    0: begin
                        if(max_entries==0)begin
                            stream_read_0_address = 0;
                        end
                        else begin
                            stream_read_0_address = max_entries/ACTIVATION_BUFFER_BANK_COUNT + 1;
                        end
                        input_line_address = ACTIVATION_LINE_BUFFER_0_START_ADDRESS;
                    end
                    1: begin
                        if(max_entries==0)begin
                            stream_read_1_address = 0;
                        end
                        else begin
                            stream_read_1_address = max_entries/ACTIVATION_BUFFER_BANK_COUNT + 1;
                        end
                        input_line_address = ACTIVATION_LINE_BUFFER_1_START_ADDRESS;
                    end
                    2: begin
                        if(max_entries==0)begin
                            stream_read_2_address = 0;
                        end
                        else begin
                            stream_read_2_address = max_entries/ACTIVATION_BUFFER_BANK_COUNT + 1;
                        end
                        input_line_address = ACTIVATION_LINE_BUFFER_2_START_ADDRESS;
                    end
                    default: begin
                        if(max_entries==0)begin
                            stream_read_0_address = 0;
                        end
                        else begin
                            stream_read_0_address = max_entries/ACTIVATION_BUFFER_BANK_COUNT + 1;
                        end
                        input_line_address = ACTIVATION_LINE_BUFFER_0_START_ADDRESS;
                    end
                endcase

                @(posedge clk);
                this.axi_full_transfer.write_data(
                    .data(this.row_i[input_row_index]),
                    .transfer_size(this.row_i_number_of_entries[input_row_index]),
                    .start_address(input_line_address + address_offset),
                    .memory_bus(data_bus)
                );
                input_row_index++;
            
            // $display("relative_row_0=%0d", relative_row_0);
            // $display("relative_row_1=%0d", relative_row_1);
            // $display("relative_row_2=%0d", relative_row_2);
            // $display("previous_line_index=%0d", previous_line_index);
            // $display("next_line_index=%0d", next_line_index);
            // $display("max_entries=%0d", max_entries);
            // $display("address_offset=%0d", address_offset);
            // $display("input_line_address=%0d", input_line_address);
            // $display("this.row_i_number_of_entries[input_row_index]=%0d", this.row_i_number_of_entries[input_row_index]);
            end

            // $display("-------------------");

            // last row padding
            if(output_row_index==this.NUMBER_OF_OUTPUT_ROWS-1)begin
                // $display("output_row_index=%0d", output_row_index);
                // $display("relative_row_0=%0d", relative_row_0);
                // $display("relative_row_1=%0d", relative_row_1);
                // $display("relative_row_2=%0d", relative_row_2);
                if(STRIDED_CONV==0) begin
                    if(relative_row_0==2) begin
                        stream_read_0_enable = 0;
                    end
                    else begin
                        if(relative_row_1==2) begin
                            stream_read_1_enable = 0;
                        end
                        else begin
                            stream_read_2_enable = 0;
                        end    
                    end
                end
                // if(STRIDED_CONV) begin
                //         if(relative_row_0==1) begin
                //         stream_read_0_enable = 0;
                //     end
                //     else begin
                //         if(relative_row_1==1) begin
                //             stream_read_1_enable = 0;
                //         end
                //         else begin
                //             stream_read_2_enable = 0;
                //         end    
                //     end
                // end
            end
            else begin
                stream_read_0_enable = 1;
                stream_read_1_enable = 1;
                stream_read_2_enable = 1;
            end

            @(posedge clk);
            register_file[CONTROL_FLAGS_REGISTER][STREAM_1_ENABLE_INDEX]                                                                        = stream_read_0_enable;
            register_file[STREAM_1_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
            register_file[STREAM_1_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_0; // relative row 
            register_file[STREAM_1_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_0_address; 

            register_file[CONTROL_FLAGS_REGISTER][STREAM_2_ENABLE_INDEX]                                                                        = stream_read_1_enable;
            register_file[STREAM_2_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
            register_file[STREAM_2_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_1; // relative row 
            register_file[STREAM_2_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_1_address; 

            register_file[CONTROL_FLAGS_REGISTER][STREAM_3_ENABLE_INDEX]                                                                        = stream_read_2_enable;
            register_file[STREAM_3_PTR_REGISTER][STREAM_PING_PONG_BIT_INDEX]                                                                    = 0; 
            register_file[STREAM_3_PTR_REGISTER][STREAM_RELATIVE_ROW_MSB:STREAM_RELATIVE_ROW_LSB]                                               = relative_row_2; // relative row
            register_file[STREAM_3_PTR_REGISTER][STREAM_START_ADDRESS_MSB:STREAM_START_ADDRESS_LSB]                                             = stream_read_2_address; 

            register_file[STREAM_WRITER_REGISTER][STREAM_WRITER_ADDRESS_MSB:STREAM_WRITER_ADDRESS_LSB]                                          = reg_file_stream_writer_address; 

            foreach (INTRA_REGISTER_LIST[i]) begin
                @(posedge clk); 
                // $display("i=%0d, INTRA_REGISTER_LIST[i]=%0d, register_file[INTRA_REGISTER_LIST[i]]=%0x", i, INTRA_REGISTER_LIST[i], register_file[INTRA_REGISTER_LIST[i]]);
                this.axi_lite_stimulus.write_AXI_lite_data(
                    .data           (register_file[INTRA_REGISTER_LIST[i]]),
                    .address        (INTRA_REGISTER_LIST[i]*REGISTER_WIDTH/8), // Byte address
                    .AXI_ACLK       (clk),
                    .AXI_AWADDR     (control_bus.S_AXI_AWADDR),
                    .AXI_AWVALID    (control_bus.S_AXI_AWVALID),
                    .AXI_AWREADY    (control_bus.S_AXI_AWREADY),
                    .AXI_WDATA      (control_bus.S_AXI_WDATA),
                    .AXI_WSTRB      (control_bus.S_AXI_WSTRB),
                    .AXI_WVALID     (control_bus.S_AXI_WVALID),
                    .AXI_WREADY     (control_bus.S_AXI_WREADY),
                    .AXI_BRESP      (control_bus.S_AXI_BRESP),
                    .AXI_BVALID     (control_bus.S_AXI_BVALID),
                    .AXI_BREADY     (control_bus.S_AXI_BREADY)
                );    
            end     

            // this.append_intra_registers_array(export_file_name, LAYER_ID, 0, register_file); 
            append_intra_registers_array(export_file_name, 0, register_file); 
            
            @(posedge clk); 
            // execution flag trigger
            register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX]  = ~ register_file[CONTROL_FLAGS_REGISTER][EXECUTION_FLAG_BIT_INDEX];
            this.axi_lite_stimulus.write_AXI_lite_data(
                .data(register_file[CONTROL_FLAGS_REGISTER]),
                .address((CONTROL_FLAGS_REGISTER)*REGISTER_WIDTH/8), // Byte address
                .AXI_ACLK(clk),
                .AXI_AWADDR  (control_bus.S_AXI_AWADDR),
                .AXI_AWVALID (control_bus.S_AXI_AWVALID),
                .AXI_AWREADY (control_bus.S_AXI_AWREADY),
                .AXI_WDATA   (control_bus.S_AXI_WDATA),
                .AXI_WSTRB   (control_bus.S_AXI_WSTRB),
                .AXI_WVALID  (control_bus.S_AXI_WVALID),
                .AXI_WREADY  (control_bus.S_AXI_WREADY),
                .AXI_BRESP   (control_bus.S_AXI_BRESP),
                .AXI_BVALID  (control_bus.S_AXI_BVALID),
                .AXI_BREADY  (control_bus.S_AXI_BREADY)
            );    

            @(posedge clk); 
            // start stream readers trigger
            register_file[CONTROL_FLAGS_REGISTER][START_STREAM_READERS_BIT_INDEX]  = ~ register_file[CONTROL_FLAGS_REGISTER][START_STREAM_READERS_BIT_INDEX];
            this.axi_lite_stimulus.write_AXI_lite_data(
                .data(register_file[CONTROL_FLAGS_REGISTER]),
                .address((CONTROL_FLAGS_REGISTER)*REGISTER_WIDTH/8), // Byte address
                .AXI_ACLK(clk),
                .AXI_AWADDR (control_bus.S_AXI_AWADDR),
                .AXI_AWVALID(control_bus.S_AXI_AWVALID),
                .AXI_AWREADY(control_bus.S_AXI_AWREADY),
                .AXI_WDATA  (control_bus.S_AXI_WDATA),
                .AXI_WSTRB  (control_bus.S_AXI_WSTRB),
                .AXI_WVALID (control_bus.S_AXI_WVALID),
                .AXI_WREADY (control_bus.S_AXI_WREADY),
                .AXI_BRESP  (control_bus.S_AXI_BRESP),
                .AXI_BVALID (control_bus.S_AXI_BVALID),
                .AXI_BREADY (control_bus.S_AXI_BREADY)
            );   

        end 
        
        @(posedge clk);
        close_intra_registers_array(export_file_name, 0, register_file); // output_row_index = 0
        // this.close_export_file(export_file_name);
        
        // @(posedge clk);
        // this.validate_outputs();

        endtask 

        task automatic export_register_map(
            input string file_name,
            input int layer_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t PRE_REGISTER_LIST[5] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", NUMBER_OF_CONV_LAYER_COLS_REGISTER, CHANNELS_MINUS_8_REGISTER, KERNEL_STEPS_MINUS_1_REGISTER, CHANNEL_STEPS_REGISTER, NUMBER_OF_CHANNELS_REGISTER);

$fwrite(fd1,"\n\
uint32_t PRE_REGISTER_LIST[4] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", STREAM_1_PTR_REGISTER, STREAM_2_PTR_REGISTER, STREAM_3_PTR_REGISTER, STREAM_WRITER_REGISTER);
            $fclose(fd1);
            return;
        endtask

        task automatic export_pre_registers(
            input string file_name,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t layer_%0d_pre_reg[5] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
}; \n\ ", LAYER_ID, register_file[NUMBER_OF_CONV_LAYER_COLS_REGISTER], 
                        register_file[CHANNELS_MINUS_8_REGISTER], 
                        register_file[KERNEL_STEPS_MINUS_1_REGISTER], 
                        register_file[CHANNEL_STEPS_REGISTER], 
                        register_file[NUMBER_OF_CHANNELS_REGISTER]);
            $fclose(fd1);
            return;
        endtask


        task automatic export_layer_parameters(
            input string file_name
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
#define LAYER_%0d_KERNEL_K    %0d \n\
#define LAYER_%0d_OUTPUT_COLS %0d \n\
#define LAYER_%0d_OUTPUT_ROWS %0d \n\
#define LAYER_%0d_OUTPUT_CH   %0d \n\ \n\ ", 
LAYER_ID, KERNEL_K,
LAYER_ID, NUMBER_OF_OUTPUT_COLS,
LAYER_ID, NUMBER_OF_OUTPUT_ROWS,
LAYER_ID, NUMBER_OF_OUTPUT_CH);
            $fclose(fd1);
            return;
        endtask

        task automatic start_intra_registers_array(
            input string file_name,
            input int number_of_rows,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t layer_%0d_intra_reg[%0d] = { \n\ ", LAYER_ID, NUMBER_OF_INTRA_REGISTERS*number_of_rows);
            $fclose(fd1);
            return;
        endtask

        task automatic append_intra_registers_array(
            input string file_name,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\ ",    register_file[CONTROL_FLAGS_REGISTER], 
                    register_file[STREAM_1_PTR_REGISTER], 
                    register_file[STREAM_2_PTR_REGISTER], 
                    register_file[STREAM_3_PTR_REGISTER], 
                    register_file[STREAM_WRITER_REGISTER]);
            $fclose(fd1);
            return;
        endtask

        task automatic close_intra_registers_array(
            input string file_name,
            input int output_row_index,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
}; \n\ ");
            $fclose(fd1);
            return;
        endtask

        task automatic export_register_file(
            input string file_name,
            ref logic [REGISTER_WIDTH-1:0] register_file [0:NUMBER_OF_REGISTERS-1]
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            fd1 = $fopen(txt_file,"a"); 
            $fwrite(fd1,"\n\
uint32_t layer_%0d_reg_file[10] = { \n\
	0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
    0x%x, \n\
	0x%x  \n\
}; \n\ ", LAYER_ID, register_file[0], register_file[1], register_file[2], register_file[3], register_file[4], 
                                                 register_file[5], register_file[6], register_file[7], register_file[8], register_file[9]);
            $fclose(fd1);
            return;
        endtask


        task automatic export_weights(
                input string file_name
            );
            string txt_file;
            int fd1;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("exporting weights");
            fd1 = $fopen(txt_file,"a"); 
            //----------------
            // write layer weights
            //----------------
            $fwrite(fd1,"uint64_t layer_%0d_number_of_entries_per_weight_array = %0d; \n\ ", LAYER_ID, this.weight_array_i_number_of_entries[0]);
            for (int i=0; i<3; i++) begin
                $fwrite(fd1,"uint64_t layer_%0d_weight_array_%0d[%0d] = { \n\ ", LAYER_ID, i, this.weight_array_i_number_of_entries[i]);
                for (int j=0; j<this.weight_array_i_number_of_entries[i]-1; j++) begin
                    $fwrite(fd1,"	0x%x, \n\ ", this.weights_array_i[i].memory[j]);
                end
                $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.weights_array_i[i].memory[this.weight_array_i_number_of_entries[i]-1]);
            end

            $fwrite(fd1,"uint64_t layer_%0d_number_of_entries_bias_array = %0d; \n\ ", LAYER_ID, this.bias_array_number_of_entries);
            $fwrite(fd1,"uint64_t layer_%0d_bias_array[%0d] = { \n\ ", LAYER_ID, this.bias_array_number_of_entries);
            for (int j=0; j<this.bias_array_number_of_entries-1; j++) begin
                $fwrite(fd1,"	0x%x, \n\ ", this.bias_array.memory[j]);
            end
            $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.bias_array.memory[this.bias_array_number_of_entries-1]);

            // $fwrite(fd1,"\n #endif /* SRC_TEST_NEURAL_NET_H_ */ \n\ ");
            $fclose(fd1);
            return;
        endtask

        task automatic export_activations(
                input string file_name
            );
            string txt_file;
            int fd1;
            int total_number_of_input_activations_entries = 0;
            int total_number_of_output_activations_entries = 0;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("exporting activations");
            fd1 = $fopen(txt_file,"a"); 

            //----------------
            // write input activations
            //----------------
            for (int i=0; i<INPUT_NUMBER_OF_ROWS; i++) begin
                total_number_of_input_activations_entries = total_number_of_input_activations_entries + row_i_number_of_entries[i]; 
            end

$fwrite(fd1,"\n\
uint64_t number_of_entries_per_row[LAYER_0_INPUT_ROWS] = { \n\ ");

            for (int i=0; i<INPUT_NUMBER_OF_ROWS-1; i++) begin
                $fwrite(fd1,"	%0d, \n\ ", row_i_number_of_entries[i]);
            end
            $fwrite(fd1,"	%0d \n\ }; \n\ ", row_i_number_of_entries[INPUT_NUMBER_OF_ROWS-1]);
            $fwrite(fd1,"uint64_t total_number_of_input_activations_entries = %0d; \n\ ", total_number_of_input_activations_entries);


            $fwrite(fd1,"uint64_t input_activations[%0d] = { \n\ ", total_number_of_input_activations_entries);
            for (int i=0; i<INPUT_NUMBER_OF_ROWS; i++) begin
                if (i==INPUT_NUMBER_OF_ROWS-1) begin
                    for (int j=0; j<row_i_number_of_entries[i]-1; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", row_i[i].memory[j]);
                    end
                end
                else begin
                    for (int j=0; j<row_i_number_of_entries[i]; j++) begin
                        $fwrite(fd1,"	0x%x, \n\ ", row_i[i].memory[j]);
                    end
                end
            end
            $fwrite(fd1,"	0x%x \n\ }; \n\ ", row_i[INPUT_NUMBER_OF_ROWS-1].memory[row_i_number_of_entries[INPUT_NUMBER_OF_ROWS-1]-1]);
                // $fwrite(fd1,"\n\ }; \n\ ");

            $fclose(fd1);
            return;
        endtask


        task automatic export_output_activations(
                input string file_name,
                input int export_values
            );
            string txt_file;
            int fd1;
            int total_number_of_output_activations_entries = 0;
            txt_file = $sformatf("%s%s.h",BASE_DIRECTORY, file_name);
            $display("exporting outupt activations");
            fd1 = $fopen(txt_file,"a"); 

            //----------------
            // write output ground truth activations
            //----------------
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                total_number_of_output_activations_entries = total_number_of_output_activations_entries + this.output_row_i_number_of_entries[i]; 
            end
            $fwrite(fd1,"uint64_t layer_%0d_number_of_entries_per_output_row[LAYER_%0d_OUTPUT_ROWS] = { \n\ ", LAYER_ID, LAYER_ID);
            for (int i=0; i<NUMBER_OF_OUTPUT_ROWS-1; i++) begin
                $fwrite(fd1,"	%0d, \n\ ", this.output_row_i_number_of_entries[i]);
            end
            $fwrite(fd1,"	%0d \n\ }; \n\ ", this.output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS-1]);
            $fwrite(fd1,"uint64_t layer_%0d_total_number_of_output_activations_entries = %0d; \n\ ", LAYER_ID, total_number_of_output_activations_entries);

            if(export_values==1)begin
                $fwrite(fd1,"uint64_t layer_%0d_ground_truth_output_activations[%0d] = { \n\ ", LAYER_ID, total_number_of_output_activations_entries);
                for (int i=0; i<NUMBER_OF_OUTPUT_ROWS; i++) begin
                    if (i==NUMBER_OF_OUTPUT_ROWS-1) begin
                        for (int j=0; j<this.output_row_i_number_of_entries[i]-1; j++) begin
                            $fwrite(fd1,"	0x%x, \n\ ", this.ground_truth_output_row_i[i].memory[j]);
                        end
                    end
                    else begin
                        for (int j=0; j<this.output_row_i_number_of_entries[i]; j++) begin
                            $fwrite(fd1,"	0x%x, \n\ ", this.ground_truth_output_row_i[i].memory[j]);
                        end
                    end
                end
                $fwrite(fd1,"	0x%x \n\ }; \n\ ", this.ground_truth_output_row_i[NUMBER_OF_OUTPUT_ROWS-1].memory[this.output_row_i_number_of_entries[NUMBER_OF_OUTPUT_ROWS-1]-1]);
            end

            $fclose(fd1);
            return;
        endtask



    endclass
    
endpackage
