/*  
*   Institute of Neuroinformatics - Sensors Group - UZH/ETHz 
*   Title:  Compression Routing Mesh
*   Date:  11.02.2022
*   Author: hasan
*   Description: 
*/

`timescale 1ns / 1ps

module sm_compression_routing_mesh #(
    parameter int DATA_BIT_WIDTH                = 4,
    localparam int INPUT_ARRAY_WIDTH            = DATA_BIT_WIDTH, 
    localparam int OUTPUT_ARRAY_WIDTH            = DATA_BIT_WIDTH+1, // the output array includes the Sparsity Map (SM)
    localparam int DATA_AND_STATUS_BIT_WIDTH    = DATA_BIT_WIDTH+1 // one extra bit for status 
)(
    input  logic                                    clk,
    input  logic                                    resetn,
    input  logic                                    i_clear_compression_stage,
    input  logic                                    i_commit_stage_ready,
    input  logic                                    i_sm_valid, 
    input  logic [DATA_BIT_WIDTH-1:0]               i_sm,
    input  logic [DATA_BIT_WIDTH-1:0]               i_input_array [INPUT_ARRAY_WIDTH], 
    output logic [DATA_AND_STATUS_BIT_WIDTH-1:0]    o_output_array [OUTPUT_ARRAY_WIDTH], 
    output logic                                    o_clear_commit_stage
);

    localparam int NUMBER_OF_LEVELS = INPUT_ARRAY_WIDTH;
    localparam int NUMBER_OF_ROUTERS = INPUT_ARRAY_WIDTH;
    logic [DATA_AND_STATUS_BIT_WIDTH-1:0]    input_data_and_status_array [INPUT_ARRAY_WIDTH]; // concatenate status bit with every data word.
    logic [DATA_BIT_WIDTH-1:0] sm_ff [NUMBER_OF_LEVELS+1];
    logic                      sm_valid_ff [NUMBER_OF_LEVELS+1];
    logic                      clear_compression_stage_ff [NUMBER_OF_LEVELS];
    // always_comb sm = i_sm;
    always_ff @(posedge clk) begin
        if(resetn==0)begin
            sm_ff <= '{default:0};
            sm_valid_ff <= '{default:0};
            clear_compression_stage_ff <= '{default:0};
        end
        else begin
            if(i_commit_stage_ready) begin
                sm_ff[0] <= i_sm;
                sm_valid_ff[0] <= i_sm_valid;
                for (int i=1; i<NUMBER_OF_LEVELS+1; i++) begin
                    sm_ff[i] <= sm_ff[i-1];
                    sm_valid_ff[i] <= sm_valid_ff[i-1];                
                end

                clear_compression_stage_ff[0] <= i_clear_compression_stage;
                for (int i=1; i<NUMBER_OF_LEVELS; i++) begin
                    clear_compression_stage_ff[i] <= clear_compression_stage_ff[i-1];
                end
            end
        end
    end

    always_comb o_clear_commit_stage = clear_compression_stage_ff[NUMBER_OF_LEVELS-1];

    // delay_unit #(
    //     .DATA_WIDTH    (0), 
    //     .DELAY_CYCLES  ($clog2(NUMBER_OF_LEVELS+1))
    // ) delay_2 (
    //     .clk                    (clk),
    //     .resetn                 (resetn),
    //     .i_input_data           (),
    //     .i_input_data_valid     (i_clear_compression_stage),
    //     .o_output_data          (),
    //     .o_output_data_valid    (o_clear_commit_stage)
    // );

    always_comb begin
        for (int i = 0; i < INPUT_ARRAY_WIDTH; i++) begin 
            if(i_sm_valid==1) begin
                input_data_and_status_array[i] = {i_input_array[i], i_sm[i]}; 
            end
            else begin
                input_data_and_status_array[i] = 0;
            end
        end
    end


    logic [DATA_AND_STATUS_BIT_WIDTH-1:0] routing_mesh [NUMBER_OF_LEVELS+1][NUMBER_OF_ROUTERS+1];
    logic [NUMBER_OF_ROUTERS+2-1:0] routing_mesh_status_array [NUMBER_OF_LEVELS+1];

    generate // TODO:: fixme: might generate latches
    for (genvar i=0; i<NUMBER_OF_LEVELS+1; i++) begin 
        if(i==0) begin
            always_comb begin

                for (int j = 0; j < INPUT_ARRAY_WIDTH+1; j++) begin
                    if(j==0) begin
                        routing_mesh[0][j] = '{default:0};
                    end
                    else begin
                        routing_mesh[0][j] = input_data_and_status_array[j-1];
                    end
                end

                for (int j=0; j< NUMBER_OF_ROUTERS+2; j++) begin
                    if(j==NUMBER_OF_ROUTERS+1) begin
                        routing_mesh_status_array[0][NUMBER_OF_ROUTERS+1] = 1;
                    end
                    else begin
                        routing_mesh_status_array[0][j] = routing_mesh[0][j][0];
                    end
                end
            end
        end
        else begin
            for (genvar j=0; j<NUMBER_OF_ROUTERS+2; j++) begin 
                if(j==0) begin
                    always_comb begin
                        routing_mesh[i][j] = '{default:0};
                        
                        routing_mesh_status_array[i][j] = routing_mesh[i][j][0];
                    end
                end
                else begin
                    if(j == NUMBER_OF_ROUTERS+1) begin
                        always_comb routing_mesh_status_array[i][NUMBER_OF_ROUTERS+1] = 1;
                    end
                    else begin
                        always_comb routing_mesh_status_array[i][j] = routing_mesh[i][j][0];

                        // if(i!=0) begin 
                            sm_compression_router #(
                                .DATA_BIT_WIDTH    (DATA_BIT_WIDTH),
                                .WEST_STATUS_ARRAY_BIT_WIDTH  (NUMBER_OF_ROUTERS+1-j)
                            ) router (
                                .clk                        (clk),                              
                                .resetn                     (resetn), 
                                .i_enable                   (i_commit_stage_ready),                    
                                .i_west_status_array        (routing_mesh_status_array[i-1][NUMBER_OF_ROUTERS+1 : j+1]),
                                .i_north_data               (routing_mesh[i-1][j][DATA_AND_STATUS_BIT_WIDTH-1:1]),
                                .i_north_data_valid         (routing_mesh[i-1][j][0]),
                                .i_north_east_data          (routing_mesh[i-1][j-1][DATA_AND_STATUS_BIT_WIDTH-1:1]),
                                .i_north_east_valid         (routing_mesh[i-1][j-1][0]),
                                .o_data                     (routing_mesh[i][j][DATA_AND_STATUS_BIT_WIDTH-1:1]),
                                .o_data_valid               (routing_mesh[i][j][0])
                            );
                    end
                end
            end
        end
    end
    endgenerate

    always_comb begin
        for (int i = 0; i < INPUT_ARRAY_WIDTH; i++) begin
            o_output_array[i] = routing_mesh [NUMBER_OF_LEVELS][i+1];
        end
        o_output_array[OUTPUT_ARRAY_WIDTH-1] = {sm_ff[NUMBER_OF_LEVELS-1], sm_valid_ff[NUMBER_OF_LEVELS-1]};        
    end


endmodule   