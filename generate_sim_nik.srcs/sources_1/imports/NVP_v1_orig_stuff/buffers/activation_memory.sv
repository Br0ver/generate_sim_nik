/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation memory
*   Date:   19.01.2021
*   Author: hasan
*   Description:  
*/

`timescale 1ns / 1ps

module activation_memory #(
    parameter  int NUMBER_OF_ACTIVATION_LINE_BUFFERS    = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    parameter  int ACTIVATION_LINE_BUFFER_DEPTH         = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH,
    parameter  int ACTIVATION_BANK_BIT_WIDTH            = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter  int ACTIVATION_BUFFER_BANK_COUNT         = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,

    localparam int ACTIVATION_BANK_DEPTH                = ACTIVATION_LINE_BUFFER_DEPTH
)(
    input logic                             clk,
    activation_buffer_control_if activation_buffer_ctrl
);

    generate 
        for (genvar i=0; i < NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
            banked_line_buffer #(   
                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
            )activation_line_buffer_i(
                .clk                    (clk),    
                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[i]),                
                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[i]),                
                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[i]),                
                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[i]),                    
                .i_read_port_en         ('{default:1}),            
                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[i]),                
                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[i])                       
            );
        end
    endgenerate


//              (* ram_style = "block" *)
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_i(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[0]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[0]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[0]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[0]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[0]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[0])                       
//            );
//              (* ram_style = "block" *)
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_ii(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[1]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[1]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[1]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[1]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[1]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[1])                       
//            );
//              (* ram_style = "block" *)
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_iii(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[2]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[2]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[2]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[2]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[2]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[2])                       
//            );
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_iv(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[3]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[3]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[3]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[3]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[3]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[3])                       
//            );
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_v(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[4]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[4]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[4]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[4]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[4]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[4])                       
//            );
//            banked_line_buffer #(   
//                .BANK_BIT_WIDTH    (ACTIVATION_BANK_BIT_WIDTH),
//                .BANK_COUNT        (ACTIVATION_BUFFER_BANK_COUNT),
//                .BANK_DEPTH        (ACTIVATION_BANK_DEPTH)
//            )activation_line_buffer_vi(
//                .clk                    (clk),    
//                .i_write_port_en        (activation_buffer_ctrl.write_port_enable[5]),                
//                .i_write_port_wen       (activation_buffer_ctrl.write_port_wen[5]),                
//                .i_write_port_addr      (activation_buffer_ctrl.write_port_addr[5]),                
//                .i_write_port_data_in   (activation_buffer_ctrl.write_port_data_in[5]),                    
//                .i_read_port_en         ('{default:1}),            
//                .i_read_port_addr       (activation_buffer_ctrl.read_port_addr[5]),                
//                .o_read_port_data_out   (activation_buffer_ctrl.read_port_data_out[5])                       
//            );
endmodule