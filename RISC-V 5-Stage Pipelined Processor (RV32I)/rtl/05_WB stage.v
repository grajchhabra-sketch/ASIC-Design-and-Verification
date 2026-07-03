module wb_mux(

    input  [31:0] alu_result,
    input  [31:0] memory_data,
    input  [31:0] pc_plus4,      

    input         mem_to_reg,
    input         jump,

    output [31:0] write_back_data

);

    assign write_back_data = jump    ? pc_plus4    :   mem_to_reg ? memory_data : alu_result;

endmodule
