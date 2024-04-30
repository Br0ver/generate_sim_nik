/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Commit stage. 
*   Date:  11.02.2022
*   Author: hasan
*   Description: This module collects 8 data words at a time, then pushing them into the "ACTIVATION_BANK_BIT_WIDTH" wide array, to be written into the memory.
*/

`timescale 1ns / 1ps


module commit_stage #(
    parameter int DATA_BIT_WIDTH                = 8,
    parameter int ACTIVATION_BANK_BIT_WIDTH   = NVP_v1_constants::ACTIVATION_BANK_BIT_WIDTH,
    localparam int DATA_AND_SM_ARRAY_WIDTH      = DATA_BIT_WIDTH+1,
    localparam int NUMBER_OF_DATA_BIT_WORDS_PER_COMMIT  =  ACTIVATION_BANK_BIT_WIDTH/DATA_BIT_WIDTH
)(
    input  logic                                                clk,
    input  logic                                                resetn,
    input  logic                                                i_clear_commit_stage,
    input  logic                                                i_valid,
    output logic                                                o_ready,
    input  logic [$clog2(DATA_AND_SM_ARRAY_WIDTH)-1:0]          i_input_array_pop_count, 
    input  logic [DATA_AND_SM_ARRAY_WIDTH*DATA_BIT_WIDTH-1:0]   i_input_array, // including sm
    output logic [ACTIVATION_BANK_BIT_WIDTH-1:0]                o_output_array,
    output logic                                                o_output_valid,
    output logic                                                o_output_last
);


//TODO:: change comparisons to $unsigned

    logic [DATA_BIT_WIDTH-1:0] zeros;
    always_comb zeros = '{default:0};

    // staged array
    // logic [(2*DATA_BIT_WIDTH+1)*DATA_BIT_WIDTH-1:0] staged_array; 
    logic [ACTIVATION_BANK_BIT_WIDTH+DATA_AND_SM_ARRAY_WIDTH*DATA_BIT_WIDTH-1:0] staged_array; 
    logic [$clog2(DATA_AND_SM_ARRAY_WIDTH)-1:0] staged_pop_count; 
    logic                                       staged_clear_commit_stage;
    logic [$clog2(NUMBER_OF_DATA_BIT_WORDS_PER_COMMIT):0] number_of_available_data_cells;
    logic commit_partial_output;


    enum logic {STAGE, SHIFT} commit_fsm;
    always_ff @(posedge clk) begin  
        if(resetn==0) begin
            commit_fsm          <= STAGE;
            staged_array        <= '{default:0};
            staged_pop_count    <= '{default:0};
            // number_of_available_data_cells <= DATA_BIT_WIDTH;
            number_of_available_data_cells <= NUMBER_OF_DATA_BIT_WORDS_PER_COMMIT;
            commit_partial_output <= 0;
            o_ready             <= 1;
            o_output_last   <= 0;
            staged_clear_commit_stage <= 0;
        end
        else begin
            case(commit_fsm)
                STAGE: begin
                    commit_partial_output <= 0;
                    if(staged_clear_commit_stage==1) begin
                        staged_clear_commit_stage <= 0;
                        o_output_last   <= 0;
                    end
                    if (i_valid) begin
                        staged_array[DATA_AND_SM_ARRAY_WIDTH*DATA_BIT_WIDTH-1:0]   <= i_input_array[DATA_AND_SM_ARRAY_WIDTH*DATA_BIT_WIDTH-1:0];
                        staged_pop_count           <= i_input_array_pop_count;
                        staged_clear_commit_stage  <= i_clear_commit_stage; 
                        o_ready                                     <= 0;
                        commit_fsm                                  <= SHIFT;
                        // o_output_last   <= (i_clear_commit_stage==1 && i_input_array_pop_count<number_of_available_data_cells)? 1 : 0;
                    end
                end
                SHIFT: begin
                    if(staged_pop_count <= number_of_available_data_cells) begin
                        if(staged_clear_commit_stage==1) begin // shift all and commit last pixel value.  
                            commit_partial_output   <= 1;
                            o_ready                 <= 1;
                            commit_fsm              <= STAGE;
                            // number_of_available_data_cells <= DATA_BIT_WIDTH;
                            number_of_available_data_cells <= NUMBER_OF_DATA_BIT_WORDS_PER_COMMIT;
                            o_output_last   <= 1;
                            // o_output_last   <= 0;
                            case (number_of_available_data_cells) //TODO:: fixme: some cases are not handled. 
                            0: staged_array <=  staged_array;
                            1: staged_array <= {staged_array[$left(staged_array)-1:0], zeros};
                            2: staged_array <= {staged_array[$left(staged_array)-2:0], zeros,zeros};
                            3: staged_array <= {staged_array[$left(staged_array)-3:0], zeros,zeros,zeros};
                            4: staged_array <= {staged_array[$left(staged_array)-4:0], zeros,zeros,zeros,zeros};
                            5: staged_array <= {staged_array[$left(staged_array)-5:0], zeros,zeros,zeros,zeros,zeros};
                            6: staged_array <= {staged_array[$left(staged_array)-6:0], zeros,zeros,zeros,zeros,zeros,zeros};
                            7: staged_array <= {staged_array[$left(staged_array)-7:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                            8: staged_array <= {staged_array[$left(staged_array)-8:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                            9: staged_array <= {staged_array[$left(staged_array)-9:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            10: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            11: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            12: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            13: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            14: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            15: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            16: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            default: staged_array <= staged_array;
                            endcase
                        end
                        else begin

                            commit_partial_output   <= 0;
                            o_ready                 <= 1;
                            commit_fsm              <= STAGE;
                            number_of_available_data_cells <= number_of_available_data_cells - staged_pop_count;
                            case (staged_pop_count) // TODO:: bad coding
                                0: staged_array <=  staged_array;
                                1: staged_array <= {staged_array[$left(staged_array)-1:0], zeros};
                                2: staged_array <= {staged_array[$left(staged_array)-2:0], zeros,zeros};
                                3: staged_array <= {staged_array[$left(staged_array)-3:0], zeros,zeros,zeros};
                                4: staged_array <= {staged_array[$left(staged_array)-4:0], zeros,zeros,zeros,zeros};
                                5: staged_array <= {staged_array[$left(staged_array)-5:0], zeros,zeros,zeros,zeros,zeros};
                                6: staged_array <= {staged_array[$left(staged_array)-6:0], zeros,zeros,zeros,zeros,zeros,zeros};
                                7: staged_array <= {staged_array[$left(staged_array)-7:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                                8: staged_array <= {staged_array[$left(staged_array)-8:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                                9: staged_array <= {staged_array[$left(staged_array)-9:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                10: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                11: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                12: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                13: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                14: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                15: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                16: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                                default: staged_array <= staged_array;
                            endcase
                        end
                    end
                    else begin
                        commit_partial_output   <= 1;                        
                        // number_of_available_data_cells <= DATA_BIT_WIDTH;
                        number_of_available_data_cells <= NUMBER_OF_DATA_BIT_WORDS_PER_COMMIT;
                        staged_pop_count <=  staged_pop_count - number_of_available_data_cells;

                        case (number_of_available_data_cells) //TODO:: fixme: some cases are not handled. 
                            0: staged_array <=  staged_array;
                            1: staged_array <= {staged_array[$left(staged_array)-1:0], zeros};
                            2: staged_array <= {staged_array[$left(staged_array)-2:0], zeros,zeros};
                            3: staged_array <= {staged_array[$left(staged_array)-3:0], zeros,zeros,zeros};
                            4: staged_array <= {staged_array[$left(staged_array)-4:0], zeros,zeros,zeros,zeros};
                            5: staged_array <= {staged_array[$left(staged_array)-5:0], zeros,zeros,zeros,zeros,zeros};
                            6: staged_array <= {staged_array[$left(staged_array)-6:0], zeros,zeros,zeros,zeros,zeros,zeros};
                            7: staged_array <= {staged_array[$left(staged_array)-7:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                            8: staged_array <= {staged_array[$left(staged_array)-8:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros};
                            9: staged_array <= {staged_array[$left(staged_array)-9:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            10: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            11: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            12: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            13: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            14: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            15: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            16: staged_array <= {staged_array[$left(staged_array)-10:0], zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros,zeros}; 
                            default: staged_array <= staged_array;
                        endcase
                    end
                end
            endcase
        end
    end

    always_comb o_output_array = staged_array[$left(staged_array) -: ACTIVATION_BANK_BIT_WIDTH];
    always_comb o_output_valid = commit_partial_output;
    


endmodule   