/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  axis memory
*   Date:  06.11.2021
*   Author: ...
*   Description: adapted from EdgeDRNN code. 
*/

`timescale 1ns/1ps

module axis_memory# (
      parameter AXIS_BUS_BIT_WIDTH = 64,
      parameter MEMORY_DEPTH = 128
   )(
      input logic  m_axi_aclk,
      input logic  m_axi_aresetn,
   
      // S AXIS interface
      input logic  [AXIS_BUS_BIT_WIDTH-1:0] s_axis_tdata,
      input logic  s_axis_tvalid,
      input logic  s_axis_tlast,
      output logic s_axis_tready,
      
      // M AXIS interface
      output logic  [AXIS_BUS_BIT_WIDTH-1:0] m_axis_tdata,
      output logic  m_axis_tvalid,
      output logic  m_axis_tlast,
      input logic   m_axis_tready,

      output logic read_flag
   );
   

    // localparam MEMORY_ADDRESS_BIT_WIDTH = $clog2(MEMORY_DEPTH);

    // Logics
    logic empty, full;
    logic m_axis_tvalid_ff;
    // logic re,we;
    // logic [AXIS_BUS_BIT_WIDTH:0] fifo_dout;
    // logic [AXIS_BUS_BIT_WIDTH:0] fifo_din;
    
    //Pointers
    logic [$clog2(MEMORY_DEPTH)-1:0] read_pointer;
    logic [$clog2(MEMORY_DEPTH)-1:0] write_pointer;
    logic [$clog2(MEMORY_DEPTH):0]   status_pointer;
   
    //Memory signals and instantiation
    // logic                                    cs;
    // logic                                    wr_en;
    // logic                                    rd_en;
    // logic unsigned [MEMORY_ADDRESS_BIT_WIDTH-1:0] addr_wr;
    // logic unsigned [MEMORY_ADDRESS_BIT_WIDTH-1:0] addr_rd;
    // logic signed   [AXIS_BUS_BIT_WIDTH:0]    din;
    // logic signed   [AXIS_BUS_BIT_WIDTH:0]    dout;

    logic                            ena;
    logic                            enb;
    logic                            wea;
    logic [$clog2(MEMORY_DEPTH)-1:0] addra;
    logic [$clog2(MEMORY_DEPTH)-1:0] addrb;
    logic [AXIS_BUS_BIT_WIDTH:0]     dia;
    logic [AXIS_BUS_BIT_WIDTH:0]     dob;

    bram_sdp #(
        .BRAM_DATA_BIT_WIDTH (AXIS_BUS_BIT_WIDTH+1),
        .BRAM_DEPTH          (MEMORY_DEPTH)
    ) mem_data (
        .clk     (m_axi_aclk),
        .*
    );

   //Flags 
    always_comb begin
        full  = (status_pointer == MEMORY_DEPTH);
        empty = (status_pointer == 0);
    end

    always_comb begin
        // BRAM signals
        ena                         = s_axis_tvalid; 
        wea                         = s_axis_tvalid & !full;
        addra                       = write_pointer;
        dia[AXIS_BUS_BIT_WIDTH]     = s_axis_tlast;
        dia[AXIS_BUS_BIT_WIDTH-1:0] = s_axis_tdata;
        enb                         = m_axis_tready & !empty;
        addrb                       = read_pointer;

        // axis signals
        m_axis_tlast                = dob[AXIS_BUS_BIT_WIDTH] & !empty;
        m_axis_tdata                = dob[AXIS_BUS_BIT_WIDTH-1:0];
        m_axis_tvalid               = m_axis_tvalid_ff;   
        s_axis_tready               = !full;
    end
   
    //Write pointer
    always_ff @ (posedge m_axi_aclk) begin
        if (m_axi_aresetn == 0) begin
            write_pointer <= '0;
        end 
        else begin
            if (ena) begin
                write_pointer   <= write_pointer + 1;
            end
        end
    end

    //Read pointer
    always_ff @ (posedge m_axi_aclk) begin
        if (m_axi_aresetn == 0) begin
            read_pointer <= '0;
            m_axis_tvalid_ff <= 0;
        end 
        else begin 
            if (enb) begin // && !empty
                read_pointer    <= read_pointer + 1; 
                m_axis_tvalid_ff <= 1;
            end
            else 
                m_axis_tvalid_ff <= 0;
        end
    end

    //Status pointer
    always_ff @ (posedge m_axi_aclk) begin
        if (m_axi_aresetn == 0) begin
            status_pointer <= '0;
        end 
        else begin 
            if (ena && !enb && !full) begin   //Only write
                status_pointer <= status_pointer + 1;
            end 
            else begin 
                if (!ena && enb && !empty) begin  //Only read
                    status_pointer <= status_pointer - 1;
                end
            end
        end
    end

    always_comb read_flag = enb;

endmodule