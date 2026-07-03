module ex_mem(

    input clk,
    input reset,
    input flush,

    // Data signals
    input  [31:0] alu_result_in,
    input  [31:0] read_data2_in,

    // Destination register
    input  [4:0]  rd_in,

    // Instruction field — needed by data_memory
    input  [2:0]  funct3_in,

    // PC+4 for JAL/JALR writeback
    input  [31:0] pc_plus4_in,

    // Branch signals
    input         branch_taken_in,
    input  [31:0] branch_target_in,

    // Control signals
    input         reg_write_in,
    input         mem_read_in,
    input         mem_write_in,
    input         mem_to_reg_in,
    input         jump_in,

    // Outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] read_data2_out,

    output reg [4:0]  rd_out,

    output reg [2:0]  funct3_out,

    output reg [31:0] pc_plus4_out,

    output reg        branch_taken_out,
    output reg [31:0] branch_target_out,

    output reg        reg_write_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        jump_out

);

    always @(posedge clk or posedge reset) begin

        if (reset || flush) begin

            alu_result_out    <= 32'b0;
            read_data2_out    <= 32'b0;
            rd_out            <= 5'b0;
            funct3_out        <= 3'b0;
            pc_plus4_out      <= 32'b0;
            branch_taken_out  <= 1'b0;
            branch_target_out <= 32'b0;
            reg_write_out     <= 1'b0;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            mem_to_reg_out    <= 1'b0;
            jump_out          <= 1'b0;

        end else begin

            alu_result_out    <= alu_result_in;
            read_data2_out    <= read_data2_in;
            rd_out            <= rd_in;
            funct3_out        <= funct3_in;
            pc_plus4_out      <= pc_plus4_in;
            branch_taken_out  <= branch_taken_in;
            branch_target_out <= branch_target_in;
            reg_write_out     <= reg_write_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
            jump_out          <= jump_in;

        end
    end

endmodule
