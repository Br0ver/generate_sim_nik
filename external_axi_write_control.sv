/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Activation Buffer External Write Control
*   Date:   13.01.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module external_axi_write_control #(   
    parameter int REGISTER_WIDTH                        = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS                   = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int ACTIVATION_BANK_BIT_WIDTH           = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_LINE_BUFFER_DEPTH               = NVP_v1_constants::ACTIVATION_LINE_BUFFER_DEPTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT          = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int NUMBER_OF_ACTIVATION_LINE_BUFFERS     = NVP_v1_constants::NUMBER_OF_ACTIVATION_LINE_BUFFERS,
    localparam LINE_BUFFER_SELECTION_BIT_WIDTH          = $clog2(NUMBER_OF_ACTIVATION_LINE_BUFFERS)
)(
    input logic                                 clk,
    input logic                                 resetn,
    s_axis_lite_bus.slave                       i_data_bus,
    register_file_if.activation_buffer          reg_file,
    activation_buffer_control_if.control    activation_buffer_ctrl,
    axis_to_weight_memory_if.control            axis_to_weight_memory
);

    logic[ACTIVATION_BUFFER_BANK_COUNT-1:0]         ready [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic                                           ready_selected;
    logic[ACTIVATION_BUFFER_BANK_COUNT-1:0]         write_enable_ff;
    logic[$clog2(ACTIVATION_BUFFER_BANK_COUNT)-1:0] bank_pointer;


    logic                                           write_port_enable;
    logic[ACTIVATION_BANK_BIT_WIDTH-1:0]          data_in; //TODO:: might need to pipeline the input to reduce fanout.
    // logic[ACTIVATION_BUFFER_BANK_COUNT-1:0]         write_enable [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[0:ACTIVATION_BUFFER_BANK_COUNT-1]         write_enable [NUMBER_OF_ACTIVATION_LINE_BUFFERS];
    logic[$clog2(ACTIVATION_LINE_BUFFER_DEPTH)-1:0]      address_in_bus;
   
    
    logic [ACTIVATION_BANK_BIT_WIDTH-1 : 0] weight_memory_data;
    logic weight_memory_valid;
    logic weight_memory_last;
    logic weight_memory_ready;

    // --------------------------------------
    // ------ Signal Definitions
	// --------------------------------------
    // data bus signals (some weird simulation bug)
    logic  data_bus_valid;
    logic  data_bus_ready;
    logic  data_bus_last;
    always_comb data_bus_valid           = i_data_bus.S_AXIS_TVALID;
    always_comb data_bus_last            = i_data_bus.S_AXIS_TLAST;
    always_comb i_data_bus.S_AXIS_TREADY = data_bus_ready;
    // Write logic signals
    logic [LINE_BUFFER_SELECTION_BIT_WIDTH-1:0] line_buffer_write_ptr;
    // logic register_file_latched_flag;
    logic i_stream_1_write_ptr_increment, i_stream_2_write_ptr_increment, i_stream_3_write_ptr_increment;

    // --------------------------------------
    // ------ Write Logic 
	// --------------------------------------
    // selects which write stream is active (including weight memory stream) using "i_data_bus.S_AXI_TID"
    always_comb begin
        ready     = '{default:'{default:1}}; //TODO:: check if needed. 
        data_in   = i_data_bus.S_AXIS_TDATA;
        if(i_data_bus.S_AXI_TID==0) begin
            line_buffer_write_ptr           = 0;
            write_port_enable               = 0;
            write_enable  = '{default:'{default:0}};            
            weight_memory_data            = i_data_bus.S_AXIS_TDATA;
            weight_memory_valid           = data_bus_valid;
            weight_memory_last            = data_bus_last;
            data_bus_ready                = weight_memory_ready;
        end
        else begin
            // if(i_data_bus.S_AXI_TID==1) // TODO:: change to case statement
            //     line_buffer_write_ptr = i_stream_1_write_ptr;
            // if(i_data_bus.S_AXI_TID==2)
            //     line_buffer_write_ptr = i_stream_2_write_ptr;
            // if(i_data_bus.S_AXI_TID==3)
            //     line_buffer_write_ptr = i_stream_3_write_ptr;
            case (i_data_bus.S_AXI_TID) 
                1: begin
                    line_buffer_write_ptr = reg_file.stream_1_ptr[LINE_BUFFER_SELECTION_BIT_WIDTH-1:0];
                    write_port_enable     = 1;
                end
                2: begin
                    line_buffer_write_ptr = reg_file.stream_2_ptr[LINE_BUFFER_SELECTION_BIT_WIDTH-1:0];
                    write_port_enable     = 1;
                end
                3: begin
                    line_buffer_write_ptr = reg_file.stream_3_ptr[LINE_BUFFER_SELECTION_BIT_WIDTH-1:0];
                    write_port_enable     = 1;
                end
                default: begin
                    line_buffer_write_ptr = 0;
                    write_port_enable     = 0;
                end
            endcase
             
            weight_memory_data  = '0;
            weight_memory_valid = '0;
            weight_memory_last  = '0;
            // map to line buffer
            write_enable = '{default:'{default:0}};

            for (int i=0; i<ACTIVATION_BUFFER_BANK_COUNT; i++) begin
                write_enable[line_buffer_write_ptr][i] = write_enable_ff[i] && data_bus_valid && ready[line_buffer_write_ptr][i];
            end
            // connect selected line buffer's ready signal to the axis bus
            ready_selected = &ready[line_buffer_write_ptr];
            data_bus_ready  = ready_selected; 
        end 
    end

    // updates write address, enable and bank pointer   
    always_ff @(posedge clk) begin
        if (resetn == 0 ) begin // TODO:: check local reset. || reg_file.local_resetn==0
            write_enable_ff    <= 1;
            address_in_bus     <= '0; 
            bank_pointer       <= '0;
        end else begin
            // if(reg_file.execution_flag == 1) begin // MSB of last register starts execution.  
                    if (data_bus_valid==1 && data_bus_ready==1) begin
                        if(data_bus_last==1) begin
                            address_in_bus  <= 0;
                            bank_pointer    <= 0;
                            write_enable_ff <= 1; //TODO:: check me
                        end
                        else begin
                            if(bank_pointer==ACTIVATION_BUFFER_BANK_COUNT-1) begin        //TODO:: add serial and parallel modes
                                address_in_bus  <= address_in_bus + 1;
                                bank_pointer    <= 0;
                                write_enable_ff <= 1;
                            end
                            else begin
                                bank_pointer <= bank_pointer + 1;

                                // rotate write enable
                                write_enable_ff[0] <= write_enable_ff[ACTIVATION_BUFFER_BANK_COUNT-1];
                                for (int i=1; i<ACTIVATION_BUFFER_BANK_COUNT; i++) begin
                                    write_enable_ff[i] <= write_enable_ff[i-1];
                                end
                            end
                        end
                    end
            // end
        end
    end

    // assign interface signals
    always_comb begin
        // activation_buffer_ctrl.ready           = ready;
        // activation_buffer_ctrl.ready_selected  = ready_selected;        
        // activation_buffer_ctrl.write_port_wen_ff = write_enable_ff;        
        // activation_buffer_ctrl.bank_pointer    = bank_pointer;        
        activation_buffer_ctrl.write_port_data_in              = data_in;
        activation_buffer_ctrl.write_port_wen         = write_enable;        
        activation_buffer_ctrl.write_port_addr       = address_in_bus;  
        // for (int i=1; i<NUMBER_OF_ACTIVATION_LINE_BUFFERS; i++) begin
        //     activation_buffer_ctrl.write_port_addr[i]       = address_in_bus;  
        // end
        activation_buffer_ctrl.write_port_enable    = write_port_enable;  

        axis_to_weight_memory.data     = weight_memory_data;
        axis_to_weight_memory.valid    = weight_memory_valid;
        axis_to_weight_memory.last     = weight_memory_last;
        weight_memory_ready            = axis_to_weight_memory.ready;    
    end
endmodule
