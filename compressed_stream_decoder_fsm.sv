/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Compressed Stream Decoder FSM
*   Date:   15.11.2021
*   Author: hasan
*   Description: This module reads compressed data from the input buffer, decodes it and forwards data to the compute units. 
*/

// TODO:: add context switch to enable depth-first execution 
// TODO:: make sure 'i_decoded_word_ready' control works correctly.

`timescale 1ns / 1ps


module compressed_stream_decoder_fsm #(   
    parameter int ACTIVATION_BIT_WIDTH          = NVP_v1_constants::ACTIVATION_BIT_WIDTH,
    parameter int ACTIVATION_BANK_BIT_WIDTH   = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    parameter int ACTIVATION_BUFFER_BANK_COUNT  = NVP_v1_constants::ACTIVATION_BUFFER_BANK_COUNT,
    parameter int CHANNEL_VALUE_BIT_WIDTH       = NVP_v1_constants::CHANNEL_VALUE_BIT_WIDTH,
    parameter int COLUMN_VALUE_BIT_WIDTH        = NVP_v1_constants::COLUMN_VALUE_BIT_WIDTH,
    parameter int ROW_VALUE_BIT_WIDTH           = NVP_v1_constants::ROW_VALUE_BIT_WIDTH,
    parameter int SUPPORTED_MAX_NUMBER_OF_COLUMNS         = NVP_v1_constants::SUPPORTED_MAX_NUMBER_OF_COLUMNS
)(
    input logic                                                                 clk,
    input logic                                                                 resetn,
    input logic                                                                 i_global_synchronization_resume,
    input logic [CHANNEL_VALUE_BIT_WIDTH-1:0]                                   i_reg_file_number_of_channels_minus_8,
    input logic [$clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS)-1:0]                   i_reg_file_number_of_conv_layer_columns,
    input logic                                                                 i_reg_file_start_stream_readers,
    input logic [ROW_VALUE_BIT_WIDTH-1:0]                                       i_reg_file_stream_ptr_relative_row,
    input  logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0]   i_stream_read_data,
    input  logic                                                                i_stream_read_valid,
    output logic                                                                o_stream_read_ready,
    output logic [ACTIVATION_BIT_WIDTH-1:0]                                     o_decoded_data_word,
    output logic [COLUMN_VALUE_BIT_WIDTH-1:0]                                   o_decoded_word_toggled_column,
    output logic [CHANNEL_VALUE_BIT_WIDTH-1:0]                                  o_decoded_word_channel,
    output logic [ROW_VALUE_BIT_WIDTH-1:0]                                      o_decoded_word_relative_row,
    output logic                                                                o_decoded_word_valid,
    input  logic                                                                i_decoded_word_ready,
    output logic                                                                o_ctrl_last_column
);

    logic stream_read_ready; 
    always_comb o_stream_read_ready = stream_read_ready;

    logic [ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT-1:0] stream_read_data_shift_reg;
    logic [ACTIVATION_BIT_WIDTH-1:0]   sliding_window;
    logic [ACTIVATION_BIT_WIDTH-1:0]   sparsity_map_word;
    logic [23:0]                       relative_channel_code;
    logic [2:0]                        channel_code_ptr;
    logic [2:0]                        channel_code;
    logic [23:0]                       channel_code_remainder;

    logic [$clog2((ACTIVATION_BANK_BIT_WIDTH*ACTIVATION_BUFFER_BANK_COUNT)/ACTIVATION_BIT_WIDTH)-1:0] decode_steps_counter;
    logic [CHANNEL_VALUE_BIT_WIDTH-1:0]                             decoded_word_channel_ff;
    logic [COLUMN_VALUE_BIT_WIDTH-1:0]                              decoded_word_toggled_column_ff;
    logic [$clog2(SUPPORTED_MAX_NUMBER_OF_COLUMNS)-1:0]                       column_counter_ff;
    enum logic[2:0] {IDLE, SM, SM_READY, WORD, WORD_READY}                     stream_read_fsm_ff;

    // Synchronization of parallel stream decoders. the global resume comes from the decoders wrapper. 
    // The decoders wait till they are all aligned (decoding the same column).
    logic local_synchronization_hold, local_synchronization_resume;
    always_comb local_synchronization_resume = !local_synchronization_hold || i_global_synchronization_resume;

    logic ctrl_last_column;
    always_comb ctrl_last_column            = (column_counter_ff==i_reg_file_number_of_conv_layer_columns-1)? 1 : 0;
    always_comb o_ctrl_last_column          = ctrl_last_column; 

    // When reg_file.start_stream_readers is high (only for one cycle), "start_stream_readers_flag" is asserted. 
    // This starts the decoder whenever the incoming streamed value is valid. 
    logic start_stream_readers_flag;
    always_ff @(posedge clk) begin 
        if(resetn==0)begin
            start_stream_readers_flag       <= 0;
        end
        else begin
            if (stream_read_fsm_ff==IDLE) begin
                if(i_reg_file_start_stream_readers==1) begin
                    start_stream_readers_flag   <= 1; // assert start flag    
                end
            end
            else begin
                start_stream_readers_flag   <= 0; // de-assert start flag
            end
        end
    end
    
    // FSM logic
    always_ff @(posedge clk) begin
        if(resetn==0) begin
            stream_read_data_shift_reg      <= '0;
            stream_read_ready               <= 1;
            stream_read_fsm_ff              <= IDLE;
            decode_steps_counter            <= '0;
            channel_code_ptr                <= '0;
            decoded_word_toggled_column_ff  <= '0;
            decoded_word_channel_ff         <= '0;
            sparsity_map_word               <= '0;
            column_counter_ff               <= 0;

            local_synchronization_hold      <= 0;
        end
        else begin
            if (i_decoded_word_ready==1 && local_synchronization_resume==1) begin
                unique case (stream_read_fsm_ff)
                    IDLE: begin
                        

                        // Reset everything //TODO:: use reg_file.local_resetn
                        decode_steps_counter            <= '0;
                        channel_code_ptr                <= '0;
                        decoded_word_toggled_column_ff  <= '0;
                        decoded_word_channel_ff         <= '0;
                        column_counter_ff               <= 0;
                        local_synchronization_hold      <= 0;
                        
                        if (i_stream_read_valid==1 && start_stream_readers_flag==1) begin 
                            stream_read_data_shift_reg  <= i_stream_read_data; // store read data into shift register
                            sparsity_map_word           <= i_stream_read_data[$left(stream_read_data_shift_reg) -:ACTIVATION_BIT_WIDTH];
                            stream_read_fsm_ff          <= SM;       
                            stream_read_ready           <= 0;
                        end 
                        else begin
                            stream_read_data_shift_reg      <= '0;
                            stream_read_fsm_ff              <= IDLE;
                            sparsity_map_word               <= '0;
                            stream_read_ready               <= 1;
                        end

                    end
                    SM: begin
                        stream_read_data_shift_reg   <= stream_read_data_shift_reg << 8;
                        local_synchronization_hold <= 0;

                        if(relative_channel_code == 0 && sparsity_map_word[$left(sparsity_map_word)]==0) begin 
                            if(decode_steps_counter == '1) begin
                                stream_read_ready  <= 1;
                                stream_read_fsm_ff   <= SM_READY;
                                decode_steps_counter <= 0; 
                            end
                            else begin
                                // stream_read_data_shift_reg   <= stream_read_data_shift_reg << 8;
                                if (decoded_word_channel_ff == i_reg_file_number_of_channels_minus_8) begin
                                    decoded_word_channel_ff        <= 0;
                                    decoded_word_toggled_column_ff <= decoded_word_toggled_column_ff + 1;
                                    local_synchronization_hold <= 1;
                                    if (ctrl_last_column == 1) begin 
                                        column_counter_ff <= 0;
                                        stream_read_fsm_ff <= IDLE;
                                    end 
                                    else begin
                                        column_counter_ff <= column_counter_ff + 1;
                                    end
                                end
                                else begin
                                    decoded_word_channel_ff     <= decoded_word_channel_ff + 8;
                                end
                                // stream_read_fsm_ff   <= SM;
                                decode_steps_counter <= decode_steps_counter + 1;
                                sparsity_map_word    <= stream_read_data_shift_reg[$left(stream_read_data_shift_reg)-ACTIVATION_BIT_WIDTH -: ACTIVATION_BIT_WIDTH];
                            end
                        end
                        else begin
                            if(decode_steps_counter == '1) begin
                                stream_read_ready  <= 1;
                                stream_read_fsm_ff   <= WORD_READY;
                                decode_steps_counter <= 0; 
                            end  
                            else begin
                                stream_read_fsm_ff   <= WORD;
                                decode_steps_counter <= decode_steps_counter + 1; 
                            end
                        end
                        
                    end
                    SM_READY: begin
                        // decode_steps_counter <= decode_steps_counter + 1; 
                        local_synchronization_hold <= 0;

                        if (i_stream_read_valid==1) begin 
                            stream_read_data_shift_reg  <= i_stream_read_data; // store read data into shift register
                            sparsity_map_word           <= i_stream_read_data[$left(i_stream_read_data) -:ACTIVATION_BIT_WIDTH];
                            stream_read_fsm_ff          <= SM;       
                            stream_read_ready          <= 0;
                            if (decoded_word_channel_ff == i_reg_file_number_of_channels_minus_8) begin
                                decoded_word_channel_ff        <= 0;
                                decoded_word_toggled_column_ff <= decoded_word_toggled_column_ff + 1;
                                local_synchronization_hold <= 1;
                                if (ctrl_last_column == 1) begin
                                    column_counter_ff <= 0;
                                    stream_read_fsm_ff <= IDLE; 
                                end 
                                else begin
                                    column_counter_ff <= column_counter_ff + 1;
                                end
                            end
                            else begin
                                decoded_word_channel_ff     <= decoded_word_channel_ff + 8;
                            end
                        end 
                    end
                    WORD: begin
                        decode_steps_counter         <= decode_steps_counter + 1; 
                        stream_read_data_shift_reg   <= stream_read_data_shift_reg << 8;
                        local_synchronization_hold <= 0;

                        if(channel_code_remainder == 0) begin 
                            // go to either sm or sm_ready
                            if(decode_steps_counter == '1) begin
                                stream_read_ready  <= 1;
                                stream_read_fsm_ff <= SM_READY;
                            end
                            else begin
                                stream_read_fsm_ff      <= SM;
                                sparsity_map_word       <= stream_read_data_shift_reg[$left(stream_read_data_shift_reg)-ACTIVATION_BIT_WIDTH -: ACTIVATION_BIT_WIDTH];
                                if (decoded_word_channel_ff == i_reg_file_number_of_channels_minus_8) begin
                                    decoded_word_channel_ff        <= 0;
                                    decoded_word_toggled_column_ff <= decoded_word_toggled_column_ff + 1;
                                    local_synchronization_hold <= 1;
                                    if (ctrl_last_column == 1) begin
                                        column_counter_ff <= 0;
                                        stream_read_fsm_ff <= IDLE; 
                                    end 
                                    else begin
                                        column_counter_ff <= column_counter_ff + 1;
                                    end
                                end
                                else begin
                                    decoded_word_channel_ff     <= decoded_word_channel_ff + 8;
                                end
                            end
                            channel_code_ptr <= 0;
                        end
                        else begin
                            // go to either word or word_ready
                            if(decode_steps_counter == '1) begin
                                stream_read_ready  <= 1;
                                stream_read_fsm_ff <= WORD_READY;
                            end
                            else begin
                                stream_read_fsm_ff <= WORD;
                            end
                            channel_code_ptr <= channel_code_ptr + 1;
                        end
                    end
                    WORD_READY: begin
                        if (i_stream_read_valid==1) begin 
                            stream_read_data_shift_reg  <= i_stream_read_data; // store read data into shift register
                            stream_read_fsm_ff          <= WORD;       
                            stream_read_ready         <= 0;
                        end 
                    end
                    default: stream_read_fsm_ff <= IDLE;
                endcase            
            end
        end                                                                                                                                  
    end
    
    always_comb begin
        o_decoded_word_toggled_column = decoded_word_toggled_column_ff;
        o_decoded_data_word           = sliding_window; 
        o_decoded_word_channel        = decoded_word_channel_ff + channel_code;
        o_decoded_word_relative_row   = i_reg_file_stream_ptr_relative_row;

        if (stream_read_fsm_ff == WORD) begin 
            o_decoded_word_valid   = 1;
        end
        else begin
            o_decoded_word_valid   = 0;
        end
    end

          
    always_comb sliding_window = stream_read_data_shift_reg[$left(stream_read_data_shift_reg) -: ACTIVATION_BIT_WIDTH]; // read most significant byte 
    always_comb begin 
        case (channel_code_ptr)  
            0 : begin 
                channel_code = relative_channel_code[23:21]; 
                channel_code_remainder = relative_channel_code[20:0]; 
            end
            1 : begin
                channel_code = relative_channel_code[20:18]; 
                channel_code_remainder = relative_channel_code[17:0];
            end
            2 : begin
                channel_code = relative_channel_code[17:15]; 
                channel_code_remainder = relative_channel_code[14:0];
            end
            3 : begin 
                channel_code = relative_channel_code[14:12]; 
                channel_code_remainder = relative_channel_code[11:0];
            end
            4 : begin 
                channel_code = relative_channel_code[11:9]; 
                channel_code_remainder = relative_channel_code[8:0];
            end
            5 : begin
                channel_code = relative_channel_code[8:6];  
                channel_code_remainder = relative_channel_code[5:0];
            end
            6 : begin
                channel_code = relative_channel_code[5:3];  
                channel_code_remainder = relative_channel_code[2:0];
            end
            7 : begin
                channel_code = relative_channel_code[2:0];  
                channel_code_remainder = '0;
            end
        endcase  
    end  
    
    // This LUT holds the relative channel value to be added to the current channel value to calculate the decoded word's channel. 
    // This can be replaced with some logic to calculate the channel from the sparsity map.  
    always_comb begin
        case (sparsity_map_word)
            0 : relative_channel_code =  24'b000000000000000000000000;
            1 : relative_channel_code =  24'b111000000000000000000000;
            2 : relative_channel_code =  24'b110000000000000000000000;
            3 : relative_channel_code =  24'b110111000000000000000000;
            4 : relative_channel_code =  24'b101000000000000000000000;
            5 : relative_channel_code =  24'b101111000000000000000000;
            6 : relative_channel_code =  24'b101110000000000000000000;
            7 : relative_channel_code =  24'b101110111000000000000000;
            8 : relative_channel_code =  24'b100000000000000000000000;
            9 : relative_channel_code =  24'b100111000000000000000000;
            10 : relative_channel_code =  24'b100110000000000000000000;
            11 : relative_channel_code =  24'b100110111000000000000000;
            12 : relative_channel_code =  24'b100101000000000000000000;
            13 : relative_channel_code =  24'b100101111000000000000000;
            14 : relative_channel_code =  24'b100101110000000000000000;
            15 : relative_channel_code =  24'b100101110111000000000000;
            16 : relative_channel_code =  24'b011000000000000000000000;
            17 : relative_channel_code =  24'b011111000000000000000000;
            18 : relative_channel_code =  24'b011110000000000000000000;
            19 : relative_channel_code =  24'b011110111000000000000000;
            20 : relative_channel_code =  24'b011101000000000000000000;
            21 : relative_channel_code =  24'b011101111000000000000000;
            22 : relative_channel_code =  24'b011101110000000000000000;
            23 : relative_channel_code =  24'b011101110111000000000000;
            24 : relative_channel_code =  24'b011100000000000000000000;
            25 : relative_channel_code =  24'b011100111000000000000000;
            26 : relative_channel_code =  24'b011100110000000000000000;
            27 : relative_channel_code =  24'b011100110111000000000000;
            28 : relative_channel_code =  24'b011100101000000000000000;
            29 : relative_channel_code =  24'b011100101111000000000000;
            30 : relative_channel_code =  24'b011100101110000000000000;
            31 : relative_channel_code =  24'b011100101110111000000000;
            32 : relative_channel_code =  24'b010000000000000000000000;
            33 : relative_channel_code =  24'b010111000000000000000000;
            34 : relative_channel_code =  24'b010110000000000000000000;
            35 : relative_channel_code =  24'b010110111000000000000000;
            36 : relative_channel_code =  24'b010101000000000000000000;
            37 : relative_channel_code =  24'b010101111000000000000000;
            38 : relative_channel_code =  24'b010101110000000000000000;
            39 : relative_channel_code =  24'b010101110111000000000000;
            40 : relative_channel_code =  24'b010100000000000000000000;
            41 : relative_channel_code =  24'b010100111000000000000000;
            42 : relative_channel_code =  24'b010100110000000000000000;
            43 : relative_channel_code =  24'b010100110111000000000000;
            44 : relative_channel_code =  24'b010100101000000000000000;
            45 : relative_channel_code =  24'b010100101111000000000000;
            46 : relative_channel_code =  24'b010100101110000000000000;
            47 : relative_channel_code =  24'b010100101110111000000000;
            48 : relative_channel_code =  24'b010011000000000000000000;
            49 : relative_channel_code =  24'b010011111000000000000000;
            50 : relative_channel_code =  24'b010011110000000000000000;
            51 : relative_channel_code =  24'b010011110111000000000000;
            52 : relative_channel_code =  24'b010011101000000000000000;
            53 : relative_channel_code =  24'b010011101111000000000000;
            54 : relative_channel_code =  24'b010011101110000000000000;
            55 : relative_channel_code =  24'b010011101110111000000000;
            56 : relative_channel_code =  24'b010011100000000000000000;
            57 : relative_channel_code =  24'b010011100111000000000000;
            58 : relative_channel_code =  24'b010011100110000000000000;
            59 : relative_channel_code =  24'b010011100110111000000000;
            60 : relative_channel_code =  24'b010011100101000000000000;
            61 : relative_channel_code =  24'b010011100101111000000000;
            62 : relative_channel_code =  24'b010011100101110000000000;
            63 : relative_channel_code =  24'b010011100101110111000000;
            64 : relative_channel_code =  24'b001000000000000000000000;
            65 : relative_channel_code =  24'b001111000000000000000000;
            66 : relative_channel_code =  24'b001110000000000000000000;
            67 : relative_channel_code =  24'b001110111000000000000000;
            68 : relative_channel_code =  24'b001101000000000000000000;
            69 : relative_channel_code =  24'b001101111000000000000000;
            70 : relative_channel_code =  24'b001101110000000000000000;
            71 : relative_channel_code =  24'b001101110111000000000000;
            72 : relative_channel_code =  24'b001100000000000000000000;
            73 : relative_channel_code =  24'b001100111000000000000000;
            74 : relative_channel_code =  24'b001100110000000000000000;
            75 : relative_channel_code =  24'b001100110111000000000000;
            76 : relative_channel_code =  24'b001100101000000000000000;
            77 : relative_channel_code =  24'b001100101111000000000000;
            78 : relative_channel_code =  24'b001100101110000000000000;
            79 : relative_channel_code =  24'b001100101110111000000000;
            80 : relative_channel_code =  24'b001011000000000000000000;
            81 : relative_channel_code =  24'b001011111000000000000000;
            82 : relative_channel_code =  24'b001011110000000000000000;
            83 : relative_channel_code =  24'b001011110111000000000000;
            84 : relative_channel_code =  24'b001011101000000000000000;
            85 : relative_channel_code =  24'b001011101111000000000000;
            86 : relative_channel_code =  24'b001011101110000000000000;
            87 : relative_channel_code =  24'b001011101110111000000000;
            88 : relative_channel_code =  24'b001011100000000000000000;
            89 : relative_channel_code =  24'b001011100111000000000000;
            90 : relative_channel_code =  24'b001011100110000000000000;
            91 : relative_channel_code =  24'b001011100110111000000000;
            92 : relative_channel_code =  24'b001011100101000000000000;
            93 : relative_channel_code =  24'b001011100101111000000000;
            94 : relative_channel_code =  24'b001011100101110000000000;
            95 : relative_channel_code =  24'b001011100101110111000000;
            96 : relative_channel_code =  24'b001010000000000000000000;
            97 : relative_channel_code =  24'b001010111000000000000000;
            98 : relative_channel_code =  24'b001010110000000000000000;
            99 : relative_channel_code =  24'b001010110111000000000000;
            100 : relative_channel_code =  24'b001010101000000000000000;
            101 : relative_channel_code =  24'b001010101111000000000000;
            102 : relative_channel_code =  24'b001010101110000000000000;
            103 : relative_channel_code =  24'b001010101110111000000000;
            104 : relative_channel_code =  24'b001010100000000000000000;
            105 : relative_channel_code =  24'b001010100111000000000000;
            106 : relative_channel_code =  24'b001010100110000000000000;
            107 : relative_channel_code =  24'b001010100110111000000000;
            108 : relative_channel_code =  24'b001010100101000000000000;
            109 : relative_channel_code =  24'b001010100101111000000000;
            110 : relative_channel_code =  24'b001010100101110000000000;
            111 : relative_channel_code =  24'b001010100101110111000000;
            112 : relative_channel_code =  24'b001010011000000000000000;
            113 : relative_channel_code =  24'b001010011111000000000000;
            114 : relative_channel_code =  24'b001010011110000000000000;
            115 : relative_channel_code =  24'b001010011110111000000000;
            116 : relative_channel_code =  24'b001010011101000000000000;
            117 : relative_channel_code =  24'b001010011101111000000000;
            118 : relative_channel_code =  24'b001010011101110000000000;
            119 : relative_channel_code =  24'b001010011101110111000000;
            120 : relative_channel_code =  24'b001010011100000000000000;
            121 : relative_channel_code =  24'b001010011100111000000000;
            122 : relative_channel_code =  24'b001010011100110000000000;
            123 : relative_channel_code =  24'b001010011100110111000000;
            124 : relative_channel_code =  24'b001010011100101000000000;
            125 : relative_channel_code =  24'b001010011100101111000000;
            126 : relative_channel_code =  24'b001010011100101110000000;
            127 : relative_channel_code =  24'b001010011100101110111000;
            128 : relative_channel_code =  24'b000000000000000000000000;
            129 : relative_channel_code =  24'b000111000000000000000000;
            130 : relative_channel_code =  24'b000110000000000000000000;
            131 : relative_channel_code =  24'b000110111000000000000000;
            132 : relative_channel_code =  24'b000101000000000000000000;
            133 : relative_channel_code =  24'b000101111000000000000000;
            134 : relative_channel_code =  24'b000101110000000000000000;
            135 : relative_channel_code =  24'b000101110111000000000000;
            136 : relative_channel_code =  24'b000100000000000000000000;
            137 : relative_channel_code =  24'b000100111000000000000000;
            138 : relative_channel_code =  24'b000100110000000000000000;
            139 : relative_channel_code =  24'b000100110111000000000000;
            140 : relative_channel_code =  24'b000100101000000000000000;
            141 : relative_channel_code =  24'b000100101111000000000000;
            142 : relative_channel_code =  24'b000100101110000000000000;
            143 : relative_channel_code =  24'b000100101110111000000000;
            144 : relative_channel_code =  24'b000011000000000000000000;
            145 : relative_channel_code =  24'b000011111000000000000000;
            146 : relative_channel_code =  24'b000011110000000000000000;
            147 : relative_channel_code =  24'b000011110111000000000000;
            148 : relative_channel_code =  24'b000011101000000000000000;
            149 : relative_channel_code =  24'b000011101111000000000000;
            150 : relative_channel_code =  24'b000011101110000000000000;
            151 : relative_channel_code =  24'b000011101110111000000000;
            152 : relative_channel_code =  24'b000011100000000000000000;
            153 : relative_channel_code =  24'b000011100111000000000000;
            154 : relative_channel_code =  24'b000011100110000000000000;
            155 : relative_channel_code =  24'b000011100110111000000000;
            156 : relative_channel_code =  24'b000011100101000000000000;
            157 : relative_channel_code =  24'b000011100101111000000000;
            158 : relative_channel_code =  24'b000011100101110000000000;
            159 : relative_channel_code =  24'b000011100101110111000000;
            160 : relative_channel_code =  24'b000010000000000000000000;
            161 : relative_channel_code =  24'b000010111000000000000000;
            162 : relative_channel_code =  24'b000010110000000000000000;
            163 : relative_channel_code =  24'b000010110111000000000000;
            164 : relative_channel_code =  24'b000010101000000000000000;
            165 : relative_channel_code =  24'b000010101111000000000000;
            166 : relative_channel_code =  24'b000010101110000000000000;
            167 : relative_channel_code =  24'b000010101110111000000000;
            168 : relative_channel_code =  24'b000010100000000000000000;
            169 : relative_channel_code =  24'b000010100111000000000000;
            170 : relative_channel_code =  24'b000010100110000000000000;
            171 : relative_channel_code =  24'b000010100110111000000000;
            172 : relative_channel_code =  24'b000010100101000000000000;
            173 : relative_channel_code =  24'b000010100101111000000000;
            174 : relative_channel_code =  24'b000010100101110000000000;
            175 : relative_channel_code =  24'b000010100101110111000000;
            176 : relative_channel_code =  24'b000010011000000000000000;
            177 : relative_channel_code =  24'b000010011111000000000000;
            178 : relative_channel_code =  24'b000010011110000000000000;
            179 : relative_channel_code =  24'b000010011110111000000000;
            180 : relative_channel_code =  24'b000010011101000000000000;
            181 : relative_channel_code =  24'b000010011101111000000000;
            182 : relative_channel_code =  24'b000010011101110000000000;
            183 : relative_channel_code =  24'b000010011101110111000000;
            184 : relative_channel_code =  24'b000010011100000000000000;
            185 : relative_channel_code =  24'b000010011100111000000000;
            186 : relative_channel_code =  24'b000010011100110000000000;
            187 : relative_channel_code =  24'b000010011100110111000000;
            188 : relative_channel_code =  24'b000010011100101000000000;
            189 : relative_channel_code =  24'b000010011100101111000000;
            190 : relative_channel_code =  24'b000010011100101110000000;
            191 : relative_channel_code =  24'b000010011100101110111000;
            192 : relative_channel_code =  24'b000001000000000000000000;
            193 : relative_channel_code =  24'b000001111000000000000000;
            194 : relative_channel_code =  24'b000001110000000000000000;
            195 : relative_channel_code =  24'b000001110111000000000000;
            196 : relative_channel_code =  24'b000001101000000000000000;
            197 : relative_channel_code =  24'b000001101111000000000000;
            198 : relative_channel_code =  24'b000001101110000000000000;
            199 : relative_channel_code =  24'b000001101110111000000000;
            200 : relative_channel_code =  24'b000001100000000000000000;
            201 : relative_channel_code =  24'b000001100111000000000000;
            202 : relative_channel_code =  24'b000001100110000000000000;
            203 : relative_channel_code =  24'b000001100110111000000000;
            204 : relative_channel_code =  24'b000001100101000000000000;
            205 : relative_channel_code =  24'b000001100101111000000000;
            206 : relative_channel_code =  24'b000001100101110000000000;
            207 : relative_channel_code =  24'b000001100101110111000000;
            208 : relative_channel_code =  24'b000001011000000000000000;
            209 : relative_channel_code =  24'b000001011111000000000000;
            210 : relative_channel_code =  24'b000001011110000000000000;
            211 : relative_channel_code =  24'b000001011110111000000000;
            212 : relative_channel_code =  24'b000001011101000000000000;
            213 : relative_channel_code =  24'b000001011101111000000000;
            214 : relative_channel_code =  24'b000001011101110000000000;
            215 : relative_channel_code =  24'b000001011101110111000000;
            216 : relative_channel_code =  24'b000001011100000000000000;
            217 : relative_channel_code =  24'b000001011100111000000000;
            218 : relative_channel_code =  24'b000001011100110000000000;
            219 : relative_channel_code =  24'b000001011100110111000000;
            220 : relative_channel_code =  24'b000001011100101000000000;
            221 : relative_channel_code =  24'b000001011100101111000000;
            222 : relative_channel_code =  24'b000001011100101110000000;
            223 : relative_channel_code =  24'b000001011100101110111000;
            224 : relative_channel_code =  24'b000001010000000000000000;
            225 : relative_channel_code =  24'b000001010111000000000000;
            226 : relative_channel_code =  24'b000001010110000000000000;
            227 : relative_channel_code =  24'b000001010110111000000000;
            228 : relative_channel_code =  24'b000001010101000000000000;
            229 : relative_channel_code =  24'b000001010101111000000000;
            230 : relative_channel_code =  24'b000001010101110000000000;
            231 : relative_channel_code =  24'b000001010101110111000000;
            232 : relative_channel_code =  24'b000001010100000000000000;
            233 : relative_channel_code =  24'b000001010100111000000000;
            234 : relative_channel_code =  24'b000001010100110000000000;
            235 : relative_channel_code =  24'b000001010100110111000000;
            236 : relative_channel_code =  24'b000001010100101000000000;
            237 : relative_channel_code =  24'b000001010100101111000000;
            238 : relative_channel_code =  24'b000001010100101110000000;
            239 : relative_channel_code =  24'b000001010100101110111000;
            240 : relative_channel_code =  24'b000001010011000000000000;
            241 : relative_channel_code =  24'b000001010011111000000000;
            242 : relative_channel_code =  24'b000001010011110000000000;
            243 : relative_channel_code =  24'b000001010011110111000000;
            244 : relative_channel_code =  24'b000001010011101000000000;
            245 : relative_channel_code =  24'b000001010011101111000000;
            246 : relative_channel_code =  24'b000001010011101110000000;
            247 : relative_channel_code =  24'b000001010011101110111000;
            248 : relative_channel_code =  24'b000001010011100000000000;
            249 : relative_channel_code =  24'b000001010011100111000000;
            250 : relative_channel_code =  24'b000001010011100110000000;
            251 : relative_channel_code =  24'b000001010011100110111000;
            252 : relative_channel_code =  24'b000001010011100101000000;
            253 : relative_channel_code =  24'b000001010011100101111000;
            254 : relative_channel_code =  24'b000001010011100101110000;
            255 : relative_channel_code =  24'b000001010011100101110111;
        endcase
    end
endmodule
