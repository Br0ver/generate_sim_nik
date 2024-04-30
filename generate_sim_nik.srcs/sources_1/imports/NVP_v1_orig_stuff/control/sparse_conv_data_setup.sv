/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: SPARSE conv3x3 convolution data setup. 
*   Date:   10.02.2022
*   Author: hasan
*   Description: 
*/


`timescale 1ns / 1ps

// import NVP_v1_constants::*;

module sparse_conv_data_setup #(   
    parameter int ACTIVATION_BIT_WIDTH      = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int CHANNEL_VALUE_BIT_WIDTH   = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int COLUMN_VALUE_BIT_WIDTH    = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ROW_VALUE_BIT_WIDTH       = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,
    parameter int COMBINED_DATA_FIFO_DEPTH  = NVP_v1_constants::COMBINED_DATA_FIFO_DEPTH,
    parameter int PE_DATA_FIFO_DEPTH        = NVP_v1_constants::PE_DATA_FIFO_DEPTH,
    parameter int PW_DATA_FIFO_DEPTH        = NVP_v1_constants::PW_DATA_FIFO_DEPTH,
    parameter int NUMBER_OF_READ_STREAMS    = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int NUMBER_OF_PE_ARRAYS       = NVP_v1_constants::NUMBER_OF_PE_ARRAYS,
    parameter int REGISTER_WIDTH            = NVP_v1_constants::REGISTER_WIDTH,
    parameter int NUMBER_OF_REGISTERS       = NVP_v1_constants::NUMBER_OF_REGISTERS,
    parameter int WEIGHT_LINE_BUFFER_DEPTH       = NVP_v1_constants::WEIGHT_LINE_BUFFER_DEPTH,
    parameter int COMBINED_DATA_BIT_WIDTH   = NVP_v1_constants::COMBINED_DATA_BIT_WIDTH,
    parameter int VALID_MSB                 = NVP_v1_constants::VALID_MSB,
    parameter int LAST_COLUMN_MSB           = NVP_v1_constants::LAST_COLUMN_MSB,
    parameter int RELATIVE_ROW_MSB          = NVP_v1_constants::RELATIVE_ROW_MSB,
    parameter int CHANNEL_MSB               = NVP_v1_constants::CHANNEL_MSB,
    parameter int TOGGLED_COLUMN_MSB        = NVP_v1_constants::TOGGLED_COLUMN_MSB,
    parameter int ACTIVATION_DATA_MSB       = NVP_v1_constants::ACTIVATION_DATA_MSB,
    parameter int SPARSE_MODE               = NVP_v1_constants::SPARSE_MODE,
    parameter int DENSE_MODE                = NVP_v1_constants::DENSE_MODE,
    parameter int SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS,
    parameter int SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS  = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS,
    localparam int KERNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_KERNEL_STEPS),
    localparam int CHANNEL_STEPS_COUNTER_BIT_WIDTH       = $clog2(SUPPORTED_MAX_NUMBER_OF_CHANNEL_STEPS)
)(
    input logic                         clk,
    input logic                         resetn,
    input logic                         i_combined_fifo_write_valid_condition,
    output logic                        o_combined_fifo_write_ready,
    input logic                         i_push_sync_word,
    register_file_if                    latched_reg_file,
    decoded_data_if                     decoded_data,
    compute_core_data_if                compute_data
);


    // --------------------------------------
    // ------ Buffer the combined words if at least one is valid. The combined data is then read and the valid words are buffered one by one.
	// --------------------------------------
    // --------------------------------------
    // ------ Combine decoded words into a single data word if at least one is valid. 
    // The combined data is then read and the valid words are buffered one by one.
	// --------------------------------------
    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0]      combined_data_word_comb;
    logic [COMBINED_DATA_BIT_WIDTH-1:0]                             separate_data_word_comb [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS-1:0]                              combined_valid_comb;
    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0] combined_fifo_write_data;
    logic combined_fifo_write_valid;
    logic combined_fifo_write_ready;
    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0] combined_fifo_read_data;
    logic combined_fifo_read_valid;
    logic combined_fifo_read_ready;
    logic combined_fifo_empty;
    logic [$clog2(COMBINED_DATA_FIFO_DEPTH):0]   combined_fifo_status_pointer;
    always_comb begin
        // The combination order is {data, toggled_column, channel, row, valid} // Need to respect the order everywhere. (used in weight_memory_address_generation and compute_unit)
        for (int i=NUMBER_OF_READ_STREAMS-1; i>=0; i--) begin
            // combined_data_word_comb[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH] = {decoded_data.data[i], decoded_data.toggled_column[i], decoded_data.channel[i], decoded_data.valid[i]}; 
            
            separate_data_word_comb[i][VALID_MSB]                                      = decoded_data.valid[i]; 
            separate_data_word_comb[i][LAST_COLUMN_MSB]                                = decoded_data.last_column[i]; 
            separate_data_word_comb[i][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = decoded_data.relative_row[i]; 
            separate_data_word_comb[i][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = decoded_data.channel[i]; 
            separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = decoded_data.toggled_column[i]; 
            separate_data_word_comb[i][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = decoded_data.data[i]; 

            combined_data_word_comb[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH] = separate_data_word_comb[i];
        end

        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            combined_valid_comb[i] = (i_combined_fifo_write_valid_condition==1)? decoded_data.valid[i] : '0;
        end
    end
    // logic [COLUMN_VALUE_BIT_WIDTH-1:0] decoded_word_toggled_column_ff [NUMBER_OF_READ_STREAMS][2]; // 2 delay cycles
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  decoded_word_toggled_column_latched_for_sync [NUMBER_OF_READ_STREAMS]; 
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  decoded_word_toggled_column_ff [NUMBER_OF_READ_STREAMS]; 
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  decoded_word_toggled_column_ff_ff [NUMBER_OF_READ_STREAMS]; 
    logic [NUMBER_OF_READ_STREAMS-1:0]  decoded_word_last_column_ff, decoded_word_last_column_ff_ff;
    logic [ROW_VALUE_BIT_WIDTH-1:0]     decoded_word_relative_row_ff   [NUMBER_OF_READ_STREAMS];
    logic [ROW_VALUE_BIT_WIDTH-1:0]     decoded_word_relative_row_ff_ff   [NUMBER_OF_READ_STREAMS];
    always_ff @(posedge clk) begin 
        if(resetn==0)begin
            decoded_word_toggled_column_ff <= '{default:0};
        end
        else begin
            for(int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
                if(combined_fifo_write_ready)begin
                    decoded_word_toggled_column_ff[i] <= decoded_data.toggled_column[i];
                    decoded_word_toggled_column_ff_ff[i] <= decoded_word_toggled_column_ff[i];

                    decoded_word_relative_row_ff[i] <= decoded_data.relative_row[i];
                    decoded_word_relative_row_ff_ff[i] <= decoded_word_relative_row_ff[i];

                    decoded_word_last_column_ff[i] <= decoded_data.last_column[i];
                    decoded_word_last_column_ff_ff[i] <= decoded_word_last_column_ff[i];
                end
            end
        end
    end

    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0]      local_sync_combined_data_word_comb;
    logic [COMBINED_DATA_BIT_WIDTH-1:0]                             local_sync_separate_data_word_comb [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0]      push_sync_combined_data_word_comb;
    logic [COMBINED_DATA_BIT_WIDTH-1:0]                             push_sync_separate_data_word_comb [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS-1:0] local_sync_word; // when an entire pixel is zero valued. // TODO: fixme check me
    always_comb begin
        for (int i=NUMBER_OF_READ_STREAMS-1; i>=0; i--) begin            
            if(local_sync_word[i]==1) begin
                local_sync_separate_data_word_comb[i][VALID_MSB]                                      = 1; //TODO: fixme:: probably should be valid!!
                local_sync_separate_data_word_comb[i][LAST_COLUMN_MSB]                                = decoded_word_last_column_ff_ff[i]; 
                local_sync_separate_data_word_comb[i][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = 0; 
                local_sync_separate_data_word_comb[i][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = 0; 
                // local_sync_separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = decoded_data.toggled_column[i]-1; 
                local_sync_separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = decoded_word_toggled_column_latched_for_sync[i]-1; 
                // local_sync_separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = decoded_word_toggled_column_ff[i]; 
                local_sync_separate_data_word_comb[i][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = 0; 
            end 
            else begin
                // local_sync_separate_data_word_comb[i][VALID_MSB]                                      = decoded_data.valid[i]; 
                // local_sync_separate_data_word_comb[i][LAST_COLUMN_MSB]                                = decoded_data.last_column[i]; 
                // local_sync_separate_data_word_comb[i][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = decoded_data.relative_row[i]; 
                // local_sync_separate_data_word_comb[i][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = decoded_data.channel[i]; 
                // local_sync_separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = decoded_data.toggled_column[i]; 
                // local_sync_separate_data_word_comb[i][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = decoded_data.data[i]; 
                local_sync_separate_data_word_comb[i][VALID_MSB]                                      = 0;
                local_sync_separate_data_word_comb[i][LAST_COLUMN_MSB]                                = 0;
                local_sync_separate_data_word_comb[i][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = 0;
                local_sync_separate_data_word_comb[i][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = 0;
                local_sync_separate_data_word_comb[i][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = 0;
                local_sync_separate_data_word_comb[i][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = 0;
            end
        end
        for (int i=NUMBER_OF_READ_STREAMS-1; i>=0; i--) begin  
            local_sync_combined_data_word_comb[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH] = local_sync_separate_data_word_comb[i];
        end

        push_sync_separate_data_word_comb[0][VALID_MSB]                                      = 1; 
        push_sync_separate_data_word_comb[0][LAST_COLUMN_MSB]                                = 0; 
        push_sync_separate_data_word_comb[0][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = 0; 
        push_sync_separate_data_word_comb[0][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = 0; 
        push_sync_separate_data_word_comb[0][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = 0; 
        push_sync_separate_data_word_comb[0][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = 0; 
        push_sync_separate_data_word_comb[1][VALID_MSB]                                      = 0; 
        push_sync_separate_data_word_comb[1][LAST_COLUMN_MSB]                                = 0; 
        push_sync_separate_data_word_comb[1][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = 0; 
        push_sync_separate_data_word_comb[1][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = 0; 
        push_sync_separate_data_word_comb[1][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = 0; 
        push_sync_separate_data_word_comb[1][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = 0; 
        push_sync_separate_data_word_comb[2][VALID_MSB]                                      = 0; 
        push_sync_separate_data_word_comb[2][LAST_COLUMN_MSB]                                = 0; 
        push_sync_separate_data_word_comb[2][RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH]        = 0; 
        push_sync_separate_data_word_comb[2][CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH]         = 0; 
        push_sync_separate_data_word_comb[2][TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH]   = 0; 
        push_sync_separate_data_word_comb[2][ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH]    = 0; 
        for (int i=NUMBER_OF_READ_STREAMS-1; i>=0; i--) begin  
            push_sync_combined_data_word_comb[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH] = push_sync_separate_data_word_comb[i];
        end

    end
    // logic [NUMBER_OF_READ_STREAMS-1:0] local_sync_word; // when an entire pixel is zero valued. // TODO: fixme check me
    logic [NUMBER_OF_READ_STREAMS-1:0] valid_value_in_pixel_flag;
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            local_sync_word <= 0;
            valid_value_in_pixel_flag <= 0;
            decoded_word_toggled_column_latched_for_sync <= '{default:0};
        end else begin
            for(int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
                if(combined_fifo_write_ready==1)begin
                    if(decoded_data.valid[i]) begin
                        valid_value_in_pixel_flag[i] <= 1;
                        local_sync_word[i] <= 0;
                    end
                    else begin
                        if(decoded_word_toggled_column_ff[i]!=decoded_data.toggled_column[i]) begin
                        // if(decoded_word_toggled_column_ff[i][1]!=decoded_word_toggled_column_ff[i][0]) begin
                            if(valid_value_in_pixel_flag[i]==0) begin
                                // local_sync_word[i] <= (local_sync_word[i]==1)? 0 : 1;
                                local_sync_word[i] <= 1;
                                decoded_word_toggled_column_latched_for_sync[i] <= decoded_data.toggled_column[i];
                            end
                            else begin
                                valid_value_in_pixel_flag[i] <= 0;
                            end
                        end
                        else begin
                            local_sync_word[i] <= 0;
                        end 
                    end
                end
            end
        end
    end
    logic push_sync_word; // when the control_execution_fsm goes to IDLE (after all stream decoders finish the last column). This is used to push out the last result(s).
    // always_comb push_sync_word = i_push_sync_word || (|local_sync_word);
    // always_comb push_sync_word = i_push_sync_word;
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            push_sync_word <= 0;
        end else begin
            if(i_push_sync_word==1) begin
                push_sync_word <= 1;
            end
            else begin
                push_sync_word <= (combined_fifo_write_ready)? 0 : push_sync_word;
            end
        end
    end
    always_comb begin
        
        if(push_sync_word==1 && combined_fifo_write_ready) begin
            combined_fifo_write_data  = push_sync_combined_data_word_comb; // this means only one valid word. 
            combined_fifo_write_valid = 1;
            o_combined_fifo_write_ready = 0;
        end
        else begin
            if((|local_sync_word)==1 && combined_fifo_write_ready) begin
                combined_fifo_write_data  = local_sync_combined_data_word_comb;
                combined_fifo_write_valid = 1;
                o_combined_fifo_write_ready = 0;
            end
            else begin  
                combined_fifo_write_data  = combined_data_word_comb;
                combined_fifo_write_valid = |combined_valid_comb;
                o_combined_fifo_write_ready = combined_fifo_write_ready;
            end
        end
    end
    axis_fifo_v2 #(
        .AXIS_BUS_WIDTH (NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH),
        .FIFO_DEPTH     (COMBINED_DATA_FIFO_DEPTH) 
    ) combined_data_fifo (
        .m_axi_aclk         (clk),
        .m_axi_aresetn      (resetn),
        .s_axis_tdata       (combined_fifo_write_data),
        .s_axis_tvalid      (combined_fifo_write_valid),
        .s_axis_tready      (combined_fifo_write_ready),
        .m_axis_tdata       (combined_fifo_read_data),
        .m_axis_tvalid      (combined_fifo_read_valid),
        .m_axis_tready      (combined_fifo_read_ready),
        .o_empty            (combined_fifo_empty),
        .o_status_pointer   (combined_fifo_status_pointer)
    );
    
    // --------------------------------------
    // ------ Valid words fifo 
	// --------------------------------------
    logic [COMBINED_DATA_BIT_WIDTH-1:0] valid_fifo_write_data;
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]   valid_fifo_write_weight_address;
    logic valid_fifo_write_valid;
    logic valid_fifo_write_ready;
    logic [COMBINED_DATA_BIT_WIDTH-1:0] valid_fifo_read_data;
    logic [$clog2(WEIGHT_LINE_BUFFER_DEPTH)-1:0]   valid_fifo_read_weight_address;
    logic valid_fifo_read_valid;
    logic valid_fifo_read_ready;
    logic valid_fifo_empty;
    axis_fifo_v2 #(
        .AXIS_BUS_WIDTH (COMBINED_DATA_BIT_WIDTH + $clog2(WEIGHT_LINE_BUFFER_DEPTH)),
        .FIFO_DEPTH     (PE_DATA_FIFO_DEPTH) 
    ) valid_data_fifo (
        .m_axi_aclk     (clk),
        .m_axi_aresetn  (resetn),
        .s_axis_tdata   ({valid_fifo_write_data, valid_fifo_write_weight_address}),
        .s_axis_tvalid  (valid_fifo_write_valid),
        .s_axis_tready  (valid_fifo_write_ready),
        .m_axis_tdata   ({valid_fifo_read_data, valid_fifo_read_weight_address}),
        .m_axis_tvalid  (valid_fifo_read_valid),
        .m_axis_tready  (valid_fifo_read_ready),
        .o_empty        (valid_fifo_empty)
    );

    // --------------------------------------
    // ------ Extracting the valid data words one by one.  (from combined words)
	// --------------------------------------
    logic [NUMBER_OF_READ_STREAMS-1:0]                          combined_fifo_read_data_valid_signals;
    logic [$clog2(NUMBER_OF_READ_STREAMS)-1:0]                  combined_fifo_number_of_valid_signals;
    logic [COMBINED_DATA_BIT_WIDTH-1:0]                         combined_fifo_read_data_separate_words [NUMBER_OF_READ_STREAMS];
    logic [NUMBER_OF_READ_STREAMS-1:0]                          combined_fifo_read_data_valid_signals_ff;
    logic [$clog2(NUMBER_OF_READ_STREAMS)-1:0]                  combined_fifo_number_of_valid_signals_ff;
    logic [COMBINED_DATA_BIT_WIDTH-1:0]                         combined_fifo_read_data_separate_words_ff [NUMBER_OF_READ_STREAMS];
    logic                                                       combined_data_valid_data_interface_ready_fifo_read;
    logic [NUMBER_OF_READ_STREAMS*COMBINED_DATA_BIT_WIDTH-1:0]  combined_fifo_read_data_ff;
    logic combined_fifo_read_valid_ff;

    // always_comb combined_fifo_read_ready = combined_data_valid_data_interface_ready_fifo_read && valid_fifo_write_ready; // first: scheduling of valid words logic. second: valid words buffer not full.
    logic read_next_combined_fifo_output_flag;
    always_comb combined_fifo_read_ready = read_next_combined_fifo_output_flag && valid_fifo_write_ready; // first: scheduling of valid words logic. second: valid words buffer not full.
    enum logic[1:0] {CHECK, BUFFER_FIRST, BUFFER_SECOND, BUFFER_THIRD} gathering_valid_data_fsm;
    always_ff @(posedge clk) begin
        if (resetn==0) begin
            combined_fifo_read_data_ff <= '0;
        end else begin
            // if(gathering_valid_data_fsm==CHECK) begin
            // if(read_next_combined_fifo_output_flag==1 && valid_fifo_write_ready==1) begin
            if(combined_fifo_read_ready==1) begin
                combined_fifo_read_data_ff <= combined_fifo_read_data;
                combined_fifo_read_valid_ff <= combined_fifo_read_valid;
            end
            else begin
                combined_fifo_read_data_ff <= combined_fifo_read_data_ff;
                combined_fifo_read_valid_ff <= combined_fifo_read_valid_ff;
            end
        end
    end
    always_comb begin 
        for (int i=0; i<NUMBER_OF_READ_STREAMS; i++) begin
            combined_fifo_read_data_separate_words[i] = combined_fifo_read_data[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            combined_fifo_read_data_valid_signals[i] = combined_fifo_read_data_separate_words[i][VALID_MSB];
            // valid_fifo_write_valid = combined_fifo_read_valid;

            combined_fifo_read_data_separate_words_ff[i] = combined_fifo_read_data_ff[(i+1)*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            combined_fifo_read_data_valid_signals_ff[i] = combined_fifo_read_data_separate_words_ff[i][VALID_MSB];
        end

        // combined_fifo_number_of_valid_signals = combined_fifo_read_data_valid_signals[0] + combined_fifo_read_data_valid_signals[1] + combined_fifo_read_data_valid_signals[2];
    end
    always_ff @(posedge clk) begin // TODO:: bad coding. fixme 
        if (resetn==0) begin
            gathering_valid_data_fsm                            <= CHECK;
            read_next_combined_fifo_output_flag <= 1;
        end else begin
            case (gathering_valid_data_fsm)
                CHECK: begin 
                    
                    if (combined_fifo_read_valid==1 && read_next_combined_fifo_output_flag==1 && valid_fifo_write_ready==1) begin
                        case (combined_fifo_read_data_valid_signals)
                            3'b001: begin
                                gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b011: begin
                                gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                read_next_combined_fifo_output_flag <= 0;
                            end
                            3'b101: begin
                                gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                read_next_combined_fifo_output_flag <= 0;
                            end
                            3'b111: begin
                                gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                read_next_combined_fifo_output_flag <= 0;
                            end
                            3'b010: begin
                                gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b110: begin
                                gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                read_next_combined_fifo_output_flag <= 0;
                            end
                            3'b100: begin
                                gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b000: begin
                                gathering_valid_data_fsm    <= CHECK; 
                            end 
                            default: begin
                                gathering_valid_data_fsm    <= CHECK; 
                            end
                        endcase
                    end
                    else begin
                        gathering_valid_data_fsm     <= CHECK; 
                        read_next_combined_fifo_output_flag <= 1;
                    end
                end
                BUFFER_FIRST: begin 
                    if (valid_fifo_write_ready==1) begin
                        case (combined_fifo_read_data_valid_signals_ff[2:1])
                            3'b01: begin
                                gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b11: begin
                                gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                read_next_combined_fifo_output_flag <= 0;
                            end
                            3'b10: begin
                                gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b00: begin
                                if (combined_fifo_read_valid==1) begin
                                    case (combined_fifo_read_data_valid_signals)
                                        3'b001: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b011: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b101: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b111: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b010: begin
                                            gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b110: begin
                                            gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b100: begin
                                            gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b000: begin
                                            gathering_valid_data_fsm    <= CHECK; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end 
                                    endcase
                                end
                            end 
                        endcase
                    end
                end
                BUFFER_SECOND: begin
                    if (valid_fifo_write_ready==1) begin
                        case (combined_fifo_read_data_valid_signals_ff[2])
                            3'b1: begin
                                gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                read_next_combined_fifo_output_flag <= 1;
                            end
                            3'b0: begin
                                if (combined_fifo_read_valid==1) begin
                                    case (combined_fifo_read_data_valid_signals)
                                        3'b001: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b011: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b101: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b111: begin
                                            gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b010: begin
                                            gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b110: begin
                                            gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                            read_next_combined_fifo_output_flag <= 0;
                                        end
                                        3'b100: begin
                                            gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end
                                        3'b000: begin
                                            gathering_valid_data_fsm    <= CHECK; 
                                            read_next_combined_fifo_output_flag <= 1;
                                        end 
                                    endcase
                                end
                            end 
                        endcase
                    end
                end
                BUFFER_THIRD: begin
                    if (valid_fifo_write_ready==1) begin
                        if (combined_fifo_read_valid==1) begin
                            case (combined_fifo_read_data_valid_signals)
                                3'b001: begin
                                    gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                    read_next_combined_fifo_output_flag <= 1;
                                end
                                3'b011: begin
                                    gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                    read_next_combined_fifo_output_flag <= 0;
                                end
                                3'b101: begin
                                    gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                    read_next_combined_fifo_output_flag <= 0;
                                end
                                3'b111: begin
                                    gathering_valid_data_fsm    <= BUFFER_FIRST; 
                                    read_next_combined_fifo_output_flag <= 0;
                                end
                                3'b010: begin
                                    gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                    read_next_combined_fifo_output_flag <= 1;
                                end
                                3'b110: begin
                                    gathering_valid_data_fsm    <= BUFFER_SECOND; 
                                    read_next_combined_fifo_output_flag <= 0;
                                end
                                3'b100: begin
                                    gathering_valid_data_fsm    <= BUFFER_THIRD; 
                                    read_next_combined_fifo_output_flag <= 1;
                                end
                                3'b000: begin
                                    gathering_valid_data_fsm    <= CHECK; 
                                    read_next_combined_fifo_output_flag <= 1;
                                end
                                default: begin
                                    gathering_valid_data_fsm    <= CHECK; 
                                end 
                            endcase
                        end
                    end
                end
            endcase
        end
    end
    // set some valid_fifo signals
    always_comb begin
        // set valid_fifo fifo_write data
        case (gathering_valid_data_fsm) 
            CHECK: begin
                valid_fifo_write_data = combined_fifo_read_data_ff[COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            end
            BUFFER_FIRST: begin
                valid_fifo_write_data = combined_fifo_read_data_ff[COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            end
            BUFFER_SECOND: begin
                valid_fifo_write_data = combined_fifo_read_data_ff[2*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            end
            BUFFER_THIRD: begin
                valid_fifo_write_data = combined_fifo_read_data_ff[3*COMBINED_DATA_BIT_WIDTH-1 -: COMBINED_DATA_BIT_WIDTH];
            end
        endcase

        // set valid_fifo fifo_write valid
        // valid_fifo_write_valid = (gathering_valid_data_fsm==CHECK)? 0 : 1;
        valid_fifo_write_valid = combined_fifo_read_valid_ff;

        // set valid_fifo fifo_read ready
        valid_fifo_read_ready = compute_data.sparse_ready; 
    end

     // set compute_data sparse signals 
    always_comb begin
        compute_data.sparse_data                    = valid_fifo_read_data;
        compute_data.sparse_buffered_weight_address = valid_fifo_read_weight_address;
        compute_data.sparse_data_valid              = valid_fifo_read_valid;
    end

    // --------------------------------------
    // DEBUG 
	// --------------------------------------
    logic [ACTIVATION_BIT_WIDTH-1:0]    dissected_write_valid_data;           
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  dissected_write_valid_toggled_column;
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0] dissected_write_valid_channel; 
    logic [ROW_VALUE_BIT_WIDTH-1:0]     dissected_write_valid_row; 
    logic                               dissected_write_valid_last_column;
    logic                               dissected_write_valid_valid;          
    logic [ACTIVATION_BIT_WIDTH-1:0]    dissected_read_valid_data;           
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]  dissected_read_valid_toggled_column;
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0] dissected_read_valid_channel; 
    logic [ROW_VALUE_BIT_WIDTH-1:0]     dissected_read_valid_row; 
    logic                               dissected_read_valid_last_column;
    logic                               dissected_read_valid_valid;  
    // {data, toggled_column, channel, row, valid}
    always_comb begin
        dissected_write_valid_data              = valid_fifo_write_data[ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH];
        dissected_write_valid_toggled_column    = valid_fifo_write_data[TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH];    
        dissected_write_valid_channel           = valid_fifo_write_data[CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH];  
        dissected_write_valid_row               = valid_fifo_write_data[RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH];  
        dissected_write_valid_last_column       = valid_fifo_write_data[LAST_COLUMN_MSB];  
        dissected_write_valid_valid             = valid_fifo_write_data[VALID_MSB];  

        dissected_read_valid_data              = valid_fifo_read_data[ACTIVATION_DATA_MSB -: ACTIVATION_BIT_WIDTH];
        dissected_read_valid_toggled_column    = valid_fifo_read_data[TOGGLED_COLUMN_MSB -: COLUMN_VALUE_BIT_WIDTH];    
        dissected_read_valid_channel           = valid_fifo_read_data[CHANNEL_MSB -: CHANNEL_VALUE_BIT_WIDTH];  
        dissected_read_valid_row               = valid_fifo_read_data[RELATIVE_ROW_MSB -: ROW_VALUE_BIT_WIDTH];  
        dissected_read_valid_last_column       = valid_fifo_read_data[LAST_COLUMN_MSB];  
        dissected_read_valid_valid             = valid_fifo_read_data[VALID_MSB];  
    end 
	// --------------------------------------
	// --------------------------------------
    logic [KERNEL_STEPS_COUNTER_BIT_WIDTH+1-1:0] kernel_steps;
    logic [CHANNEL_STEPS_COUNTER_BIT_WIDTH+1-1:0] channel_steps;
    always_comb kernel_steps                    = latched_reg_file.kernel_steps_minus_1[KERNEL_STEPS_COUNTER_BIT_WIDTH-1:0] + 1; 
    always_comb channel_steps                   = latched_reg_file.channel_steps; 
    always_comb valid_fifo_write_weight_address = (unsigned'(dissected_write_valid_channel)*unsigned'(kernel_steps)) + (unsigned'(dissected_write_valid_row)*unsigned'(kernel_steps)*unsigned'(latched_reg_file.number_of_channels));
    // always_comb valid_fifo_write_weight_address = (unsigned'(dissected_write_valid_channel)*unsigned'(channel_steps)) + (unsigned'(dissected_write_valid_row)*unsigned'(kernel_steps)*unsigned'(latched_reg_file.number_of_channels));
    


endmodule