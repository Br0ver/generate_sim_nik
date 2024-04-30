/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title: Compressed Stream Decoder Wrapper
*   Date:   14.01.2022
*   Author: hasan
*   Description: Wraps the instantiation of the compressed stream decoders and some control logic
*/

`timescale 1ns / 1ps

module compressed_stream_decoder_wrapper #(   
    parameter int NUMBER_OF_READ_STREAMS = NVP_v1_constants::NUMBER_OF_READ_STREAMS,
    parameter int REGISTER_WIDTH         = NVP_v1_constants::REGISTER_WIDTH
)(
    input logic                                 clk,
    input logic                                 resetn,
    register_file_if  latched_reg_file,
    streamed_data_if             streamed_data,
    decoded_data_if              decoded_data,
    control_and_stream_decoder_if       stream_decoder_ctrl
);
    // last column logic -> goes to execution control logic
    logic [NUMBER_OF_READ_STREAMS-1:0] ctrl_last_column;
    logic last_column_flag_and, last_column_flag_nor;
    always_comb begin
        last_column_flag_and = ~(latched_reg_file.stream_1_enable^ctrl_last_column[0]) && ~(latched_reg_file.stream_2_enable^ctrl_last_column[1]) && ~(latched_reg_file.stream_3_enable^ctrl_last_column[2]);
        last_column_flag_nor = ~|ctrl_last_column;
    end

    always_comb stream_decoder_ctrl.last_column_flag_and = last_column_flag_and; 
    always_comb stream_decoder_ctrl.last_column_flag_nor = last_column_flag_nor;

    always_comb decoded_data.last_column = ctrl_last_column;

    // always_comb stream_decoder_ctrl.last_column_flag_and = &ctrl_last_column; 
    // always_comb stream_decoder_ctrl.last_column_flag_nor = ~|ctrl_last_column;


    // stream decoders synchronization logic
    logic global_synchronization_resume;
    logic decoders_aligned;
    logic [NUMBER_OF_READ_STREAMS-1:0] stream_readers_enable;
    logic condition_0_1, condition_0_2, condition_1_2, sync_condition;
    always_comb begin //TODO:: bad coding
        stream_readers_enable = {latched_reg_file.stream_1_enable, latched_reg_file.stream_2_enable, latched_reg_file.stream_3_enable};
        condition_0_1 = (decoded_data.toggled_column[0]==decoded_data.toggled_column[1])? 1 : 0;
        condition_0_2 = (decoded_data.toggled_column[0]==decoded_data.toggled_column[2])? 1 : 0;
        condition_1_2 = (decoded_data.toggled_column[1]==decoded_data.toggled_column[2])? 1 : 0;

        case (stream_readers_enable)
        3'b011: begin
            sync_condition = condition_1_2;
        end 
        3'b101: begin
            sync_condition = condition_0_2;
        end
        3'b110: begin
            sync_condition = condition_0_1;
        end
        3'b111: begin
            sync_condition = condition_0_1 && condition_0_2 && condition_1_2;
        end
        default: begin
            sync_condition = 0;
        end
        endcase

        if(sync_condition) begin
            decoders_aligned = 1;
        end
        else begin
            decoders_aligned = 0;
        end
    end
    
    always_comb begin
        global_synchronization_resume = (decoders_aligned==1)? 1 : 0;
    end

    logic [REGISTER_WIDTH-1:0] stream_ptrs [NUMBER_OF_READ_STREAMS];
    always_comb stream_ptrs[0] = latched_reg_file.stream_1_ptr;
    always_comb stream_ptrs[1] = latched_reg_file.stream_2_ptr;
    always_comb stream_ptrs[2] = latched_reg_file.stream_3_ptr;

    // generate stream decoders
    generate
        for (genvar i=0; i < NUMBER_OF_READ_STREAMS; i++) begin
            compressed_stream_decoder compressed_stream_decoder_unit_i (
                .clk                                    (clk),
                .resetn                                 (resetn),
                .i_global_synchronization_resume        (global_synchronization_resume),
                .i_reg_file_number_of_channels_minus_8  (latched_reg_file.channels_minus_8),
                .i_reg_file_number_of_conv_layer_columns(latched_reg_file.number_of_conv_layer_columns),
                .i_reg_file_start_stream_readers        (latched_reg_file.start_stream_readers),
                .i_reg_file_stream_ptr                  (stream_ptrs[i]),
                .i_stream_read_data                     (streamed_data.data[i]),
                .i_stream_read_valid                    (streamed_data.valid[i]),
                .o_stream_read_ready                    (streamed_data.ready_from_stream_decoders[i]),
                .o_decoded_data_word                    (decoded_data.data[i]),
                .o_decoded_word_toggled_column          (decoded_data.toggled_column[i]),
                .o_decoded_word_channel                 (decoded_data.channel[i]),
                .o_decoded_word_relative_row            (decoded_data.relative_row[i]),
                .o_decoded_word_valid                   (decoded_data.valid[i]),
                .i_decoded_word_ready                   (decoded_data.ready[i]),
                .o_ctrl_last_column                     (ctrl_last_column[i]) 
            );
        end
    endgenerate
    
endmodule



