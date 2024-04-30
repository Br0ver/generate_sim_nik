/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  axis fifo
*   Date:  05.11.2021
*   Author: ...
*   Description: adapted from EdgeDRNN code. This fifo uses a 'last' signal from the axis interface protocol. The last bit is concatenated to the data.  
*/

`timescale 1ns/1ps

module axis_fifo_v4 #(
      parameter AXIS_BUS_WIDTH = 64,
      parameter FIFO_DEPTH = 128
   )(
      input logic  m_axi_aclk,
      input logic  m_axi_aresetn,
   
      // S AXIS interface
      input logic  [AXIS_BUS_WIDTH-1:0] s_axis_tdata,
      input logic  s_axis_tvalid,
      output logic s_axis_tready,
      
      // M AXIS interface
      output logic  [AXIS_BUS_WIDTH-1:0] m_axis_tdata,
      output logic  m_axis_tvalid,
      input logic   m_axis_tready,

      output logic o_empty,
    output logic [$clog2(FIFO_DEPTH):0]   o_status_pointer

   );
   
   // Logics
   logic empty, full;
   logic re,we;
   logic [AXIS_BUS_WIDTH-1:0] fifo_dout;
   logic [AXIS_BUS_WIDTH-1:0] fifo_din;

   always_comb begin
        // m_axis_tvalid = !empty;
        s_axis_tready = !full;
        we = s_axis_tvalid & !full;
        re = m_axis_tready & !empty;
        //fifo_din[AXIS_BUS_WIDTH+1-1] = s_axis_tvalid;
        // fifo_din[AXIS_BUS_WIDTH] = s_axis_tlast;
        fifo_din[AXIS_BUS_WIDTH-1:0] = s_axis_tdata;
        // m_axis_tlast = fifo_dout[AXIS_BUS_WIDTH] & !empty;
        // m_axis_tlast = empty;
        m_axis_tdata = fifo_dout[AXIS_BUS_WIDTH-1:0];
   end
   
   //Pointers
   logic [$clog2(FIFO_DEPTH)-1:0] read_pointer;
   logic [$clog2(FIFO_DEPTH)-1:0] write_pointer;
   logic [$clog2(FIFO_DEPTH):0]   status_pointer;

   //Flags
   always_comb begin
      full  = (status_pointer == FIFO_DEPTH);
      empty = (status_pointer == 0);
   end
   
   //Memorys
   (* ram_style = "block" *) logic [AXIS_BUS_WIDTH-1:0] mem_data [FIFO_DEPTH-1:0];
   
    //Write 
    always_ff @ (posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            write_pointer <= '0;
        end 
        else begin
            if (we) begin
                mem_data[write_pointer] <= fifo_din;
                write_pointer           <= write_pointer + 1;
            end
        end
    end
   
   //Read 
    always_ff @ (posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            read_pointer <= '0;
            fifo_dout    <= '0;
            m_axis_tvalid<=0;
        end 
        else begin 
            if (re) begin // && !empty
                read_pointer    <= read_pointer + 1;
            end
            if (m_axis_tready) begin // && !empty
                fifo_dout       <= mem_data[read_pointer];
                m_axis_tvalid <= !empty;
            end
            // else begin
            //     m_axis_tvalid <= 0;
            //     // fifo_dout <= '0;
            // end
        end
    end

    //Status
    always_ff @ (posedge m_axi_aclk) begin
        if (!m_axi_aresetn) begin
            status_pointer <= '0;
        end 
        else begin 
            if (we && !re && !full) begin   //Only write
                status_pointer <= status_pointer + 1;
            end 
            else begin 
                if (!we && re && !empty) begin  //Only read
                    status_pointer <= status_pointer - 1;
                end
            end
        end
    end

endmodule


// /*  
// *   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
// *   Title:  axis fifo
// *   Date:  27.11.2021
// *   Author: ...
// *   Description: adapted from EdgeDRNN code. This is a modified version of the code. It doesn't use the "last signal". 
// *                   Also this connects the output "m_axis_tdata" and "m_axis_tvalid" using combinational logic. 
// */

// `timescale 1ns/1ps

// `define DEBUG 

// module axis_fifo_v4 #(
//       parameter AXIS_BUS_WIDTH = 64,
//       parameter FIFO_DEPTH = 128
//    )(
//         input logic  m_axi_aclk,
//         input logic  m_axi_aresetn,
    
//         // S AXIS interface
//         input logic  [AXIS_BUS_WIDTH-1:0] s_axis_tdata,
//         input logic  s_axis_tvalid,
//         output logic s_axis_tready,

//         // M AXIS interface
//         output logic  [AXIS_BUS_WIDTH-1:0] m_axis_tdata,
//         output logic  m_axis_tvalid,
//         input logic   m_axis_tready,

//         // extra outputs
//         output logic o_empty,
//         output logic [$clog2(FIFO_DEPTH):0]   o_status_pointer
//    );
    
//    // Logics
//    logic empty, full;
//    logic re,we;
//    logic [AXIS_BUS_WIDTH-1:0] fifo_dout;
//    logic [AXIS_BUS_WIDTH-1:0] fifo_din;

//    logic m_axis_tvalid_comb, m_axis_tvalid_ff;

//    always_comb begin
//         s_axis_tready = !full;
//         we = s_axis_tvalid && !full;
//         // re = m_axis_tready & m_axis_tvalid;
//         re = m_axis_tready && !empty;
//         m_axis_tvalid_comb = !empty;
//         fifo_din[AXIS_BUS_WIDTH-1:0] = s_axis_tdata;
//         m_axis_tdata = fifo_dout[AXIS_BUS_WIDTH-1:0];
//    end

//     // always_comb m_axis_tvalid = m_axis_tvalid_ff && m_axis_tvalid_comb; // fixme. 
//     always_comb m_axis_tvalid = m_axis_tvalid_ff; // fixme. 

// //    always_ff @(posedge m_axi_aclk) begin
// //        if (m_axi_aresetn==0) begin
// //            m_axis_tvalid <= 0;
// //        end else begin
// //            m_axis_tvalid <= m_axis_tvalid_comb;
// //        end
// //    end
   
//    //Pointers
//    logic [$clog2(FIFO_DEPTH)-1:0] read_pointer;
//    logic [$clog2(FIFO_DEPTH)-1:0] write_pointer;
//    logic [$clog2(FIFO_DEPTH):0]   status_pointer;

//    //Flags
//    always_comb begin
//       full  = (status_pointer == FIFO_DEPTH);
//       empty = (status_pointer == 0);
//    end
   
//    //Memorys
//    (* ram_style = "block" *) logic [AXIS_BUS_WIDTH-1:0] mem_data [FIFO_DEPTH-1:0];

//     //Write 
//     always_ff @ (posedge m_axi_aclk) begin
//         if (!m_axi_aresetn) begin
//             write_pointer <= '0;
//             // `ifdef DEBUG
//             //     for (int i=0; i<FIFO_DEPTH; i++) begin
//             //         mem_data[i] <= '0;
//             //     end
//             // `endif
//         end 
//         else begin
//             if (we) begin
//                 mem_data[write_pointer] <= fifo_din;
//                 write_pointer           <= write_pointer + 1;
//             end
//         end
//     end
   
//    //Read 
//     always_ff @ (posedge m_axi_aclk) begin
//         if (!m_axi_aresetn) begin
//             read_pointer <= '0;
//             // fifo_dout    <= '0;
//             // m_axis_tvalid_ff <= 0;
//         end 
//         else begin 
//             if (re) begin // && !empty
//                 read_pointer    <= read_pointer + 1;
//                 // fifo_dout        <= (empty)? '0 : mem_data[read_pointer];
//                 // m_axis_tvalid_ff <= m_axis_tvalid_comb;
//             end
//         end
//     end

//     //Status
//     always_ff @ (posedge m_axi_aclk) begin
//         if (!m_axi_aresetn) begin
//             status_pointer <= '0;
//         end 
//         else begin 
//             if (we && !re && !full) begin   //Only write
//                 status_pointer <= status_pointer + 1;
//             end 
//             else begin 
//                 if (!we && re && !empty) begin  //Only read
//                     status_pointer <= status_pointer - 1;
//                 end
//             end
//         end
//     end

//     always_comb o_empty             = empty;            // TODO:: fixme: check if needed 
//     always_comb o_status_pointer    = status_pointer;   // TODO:: fixme: check if needed

//     always_comb begin
//         fifo_dout        = (empty)? '0 : mem_data[read_pointer];
//         m_axis_tvalid_ff = m_axis_tvalid_comb;
//     end

// endmodule