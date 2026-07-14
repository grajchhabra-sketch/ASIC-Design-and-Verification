module id_ex(
    input clk,
    input reset,
    input flush,

    // PC
    input  [31:0] pc_in,

    // Data signals
    input  [31:0] read_data1_in,
    input  [31:0] read_data2_in,
    input  [31:0] imm_in,

    // Register addresses
    input  [4:0]  rs1_in,
    input  [4:0]  rs2_in,
    input  [4:0]  rd_in,

    // Instruction fields
    input  [2:0]  funct3_in,
    input  [6:0]  funct7_in,

    // Control signals
    input         reg_write_in,
    input         alu_src_in,
    input         mem_read_in,
    input         mem_write_in,
    input         mem_to_reg_in,
    input         branch_in,
    input         jump_in,
    input  [1:0]  alu_op_in,

    // PC output
    output reg [31:0] pc_out,

    // Data outputs
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] imm_out,

    // Register address outputs
    output reg [4:0]  rs1_out,
    output reg [4:0]  rs2_out,
    output reg [4:0]  rd_out,

    // Instruction field outputs
    output reg [2:0]  funct3_out,
    output reg [6:0]  funct7_out,

    // Control signal outputs
    output reg        reg_write_out,
    output reg        alu_src_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        mem_to_reg_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg [1:0]  alu_op_out
);

    always @(posedge clk or posedge reset) begin

        if (reset || flush) begin

            // PC
            pc_out          <= 32'b0;

            // Data
            read_data1_out  <= 32'b0;
            read_data2_out  <= 32'b0;
            imm_out         <= 32'b0;

            // Register addresses
            rs1_out         <= 5'b0;
            rs2_out         <= 5'b0;
            rd_out          <= 5'b0;

            // Instruction fields
            funct3_out      <= 3'b0;
            funct7_out      <= 7'b0;

            // Control signals — all zeroed = NOP behaviour
            reg_write_out   <= 1'b0;
            alu_src_out     <= 1'b0;
            mem_read_out    <= 1'b0;
            mem_write_out   <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            branch_out      <= 1'b0;
            jump_out        <= 1'b0;
            alu_op_out      <= 2'b00;

        end

        else begin

            // PC
            pc_out          <= pc_in;

            // Data
            read_data1_out  <= read_data1_in;
            read_data2_out  <= read_data2_in;
            imm_out         <= imm_in;

            // Register addresses
            rs1_out         <= rs1_in;
            rs2_out         <= rs2_in;
            rd_out          <= rd_in;

            // Instruction fields
            funct3_out      <= funct3_in;
            funct7_out      <= funct7_in;

            // Control signals
            reg_write_out   <= reg_write_in;
            alu_src_out     <= alu_src_in;
            mem_read_out    <= mem_read_in;
            mem_write_out   <= mem_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            branch_out      <= branch_in;
            jump_out        <= jump_in;
            alu_op_out      <= alu_op_in;

        end
    end
  
  property p_idex_flush_zero_ctrl;
  @(posedge clk)
    (reset || flush) |=> (reg_write_out == 0 && mem_read_out == 0 &&
                          mem_write_out == 0 && branch_out == 0 && jump_out == 0);
endproperty
assert property(p_idex_flush_zero_ctrl)
  else $error("ID/EX did not clear control signals on flush/reset");

endmodule
