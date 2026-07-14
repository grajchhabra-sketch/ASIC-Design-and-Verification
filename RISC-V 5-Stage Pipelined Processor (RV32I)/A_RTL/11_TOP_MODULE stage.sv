
module riscv_top(
    input clk,
    input reset
);

    wire [31:0] pc_curr;
    wire [31:0] pc_nxt;
    wire [31:0] if_instruction;

    wire [31:0] ifid_pc;
    wire [31:0] ifid_instr;

    wire [6:0] id_opcode;
    wire [4:0] id_rd, id_rs1, id_rs2;
    wire [2:0] id_funct3;
    wire [6:0] id_funct7;
    wire [31:0] id_rdata1, id_rdata2;
    wire [31:0] id_imm;
    wire id_reg_write, id_alu_src, id_mem_read, id_mem_write,
         id_mem_to_reg, id_branch, id_jump;
    wire [1:0] id_alu_op;

    wire hazard_stall, pc_write, if_id_write;
    wire branch_taken;
    wire ctrl_flush;
    wire idex_flush;

    wire [31:0] ex_pc;
    wire [31:0] ex_rdata1, ex_rdata2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [2:0]  ex_funct3;
    wire [6:0]  ex_funct7;
    wire ex_reg_write, ex_alu_src, ex_mem_read, ex_mem_write,
         ex_mem_to_reg, ex_branch, ex_jump;
    wire [1:0] ex_alu_op;

    wire [1:0]  fwd_a, fwd_b;
    wire [31:0] operand_a;
    wire [31:0] operand_b_raw;
    wire [31:0] operand_b;
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire [31:0] pc_plus4_ex;

    wire [31:0] mem_alu_result, mem_rdata2;
    wire [4:0]  mem_rd;
    wire [2:0]  mem_funct3;
    wire [31:0] mem_pc_plus4;
    wire        mem_branch_taken_q;
    wire [31:0] mem_branch_target_q;
    wire        mem_reg_write, mem_mem_read, mem_mem_write,
                mem_mem_to_reg, mem_jump;

    wire [31:0] dmem_read_data;

    wire [31:0] wb_mem_data, wb_alu_result, wb_pc_plus4;
    wire [4:0]  wb_rd;
    wire        wb_reg_write, wb_mem_to_reg, wb_jump;

    wire [31:0] write_back_data;

    pc PC_REG (
        .clk     (clk),
        .reset   (reset),
        .stall   (hazard_stall),
        .pc_next (pc_nxt),
        .pc      (pc_curr)
    );

    pc_next PC_NEXT (
        .pc            (pc_curr),
        .branch_target (branch_target),
        .jump_target   (jump_target),
        .branch_taken  (branch_taken),
        .jump          (ex_jump),
        .pc_next       (pc_nxt)
    );

    inst_mem IMEM (
        .pc          (pc_curr),
        .instruction (if_instruction)
    );

    if_id IF_ID (
        .clk             (clk),
        .reset           (reset),
        .stall           (hazard_stall),
        .flush           (ctrl_flush),
        .pc_in           (pc_curr),
        .instruction_in  (if_instruction),
        .pc_out          (ifid_pc),
        .instruction_out (ifid_instr)
    );

    decoder DECODER (
        .instruction (ifid_instr),
        .opcode      (id_opcode),
        .rd          (id_rd),
        .funct3      (id_funct3),
        .rs1         (id_rs1),
        .rs2         (id_rs2),
        .funct7      (id_funct7)
    );

    register_file REG_FILE (
        .clk        (clk),
        .rs1        (id_rs1),
        .rs2        (id_rs2),
        .reg_write  (wb_reg_write),
        .rd         (wb_rd),
        .write_data (write_back_data),
        .read_data1 (id_rdata1),
        .read_data2 (id_rdata2)
    );

    immediate_generator IMM_GEN (
        .instruction (ifid_instr),
        .imm_out     (id_imm)
    );

    
    control_unit CTRL (
        .opcode     (id_opcode),
        .rd         (id_rd),
        .rs1        (id_rs1),
        .imm11_0    (ifid_instr[31:20]),
        .reg_write  (id_reg_write),
        .alu_src    (id_alu_src),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .branch     (id_branch),
        .jump       (id_jump),
        .alu_op     (id_alu_op)
    );

    hazard_detection_unit HAZARD (
        .id_ex_mem_read (ex_mem_read),
        .id_ex_rd       (ex_rd),
        .if_id_rs1      (id_rs1),
        .if_id_rs2      (id_rs2),
        .stall          (hazard_stall),
        .pc_write       (pc_write),
        .if_id_write    (if_id_write)
    );

    flush_unit FLUSH (
        .branch_taken (branch_taken),
        .jump         (ex_jump),
        .flush        (ctrl_flush)
    );

    assign idex_flush = hazard_stall | ctrl_flush;

    id_ex ID_EX (
        .clk            (clk),
        .reset          (reset),
        .flush          (idex_flush),

        .pc_in          (ifid_pc),

        .read_data1_in  (id_rdata1),
        .read_data2_in  (id_rdata2),
        .imm_in         (id_imm),

        .rs1_in         (id_rs1),
        .rs2_in         (id_rs2),
        .rd_in          (id_rd),

        .funct3_in      (id_funct3),
        .funct7_in      (id_funct7),

        .reg_write_in   (id_reg_write),
        .alu_src_in     (id_alu_src),
        .mem_read_in    (id_mem_read),
        .mem_write_in   (id_mem_write),
        .mem_to_reg_in  (id_mem_to_reg),
        .branch_in      (id_branch),
        .jump_in        (id_jump),
        .alu_op_in      (id_alu_op),

        .pc_out         (ex_pc),

        .read_data1_out (ex_rdata1),
        .read_data2_out (ex_rdata2),
        .imm_out        (ex_imm),

        .rs1_out        (ex_rs1),
        .rs2_out        (ex_rs2),
        .rd_out         (ex_rd),

        .funct3_out     (ex_funct3),
        .funct7_out     (ex_funct7),

        .reg_write_out  (ex_reg_write),
        .alu_src_out    (ex_alu_src),
        .mem_read_out   (ex_mem_read),
        .mem_write_out  (ex_mem_write),
        .mem_to_reg_out (ex_mem_to_reg),
        .branch_out     (ex_branch),
        .jump_out       (ex_jump),
        .alu_op_out     (ex_alu_op)
    );

    forwarding_unit FWD_UNIT (
        .id_ex_rs1        (ex_rs1),
        .id_ex_rs2        (ex_rs2),
        .ex_mem_rd        (mem_rd),
        .ex_mem_reg_write (mem_reg_write),
        .mem_wb_rd        (wb_rd),
        .mem_wb_reg_write (wb_reg_write),
        .forward_a        (fwd_a),
        .forward_b        (fwd_b)
    );

    forward_mux_a FWD_MUX_A (
        .read_data1  (ex_rdata1),
        .ex_mem_data (mem_alu_result),
        .mem_wb_data (write_back_data),
        .forward_a   (fwd_a),
        .operand_a   (operand_a)
    );

    forward_mux_b FWD_MUX_B (
        .read_data2  (ex_rdata2),
        .ex_mem_data (mem_alu_result),
        .mem_wb_data (write_back_data),
        .forward_b   (fwd_b),
        .operand_b   (operand_b_raw)
    );

    alu_src_mux ALU_SRC_MUX (
        .rs2_data  (operand_b_raw),
        .imm_data  (ex_imm),
        .alu_src   (ex_alu_src),
        .operand_b (operand_b)
    );

    alu_control ALU_CTRL (
        .alu_op   (ex_alu_op),
        .funct3   (ex_funct3),
        .funct7   (ex_funct7),
        .alu_src  (ex_alu_src),
        .alu_ctrl (alu_ctrl)
    );

    alu ALU (
        .operand_a (operand_a),
        .operand_b (operand_b),
        .alu_ctrl  (alu_ctrl),
        .result    (alu_result),
        .zero      (alu_zero)
    );

    branch_logic BRANCH_LOGIC (
        .branch       (ex_branch),
        .funct3       (ex_funct3),
        .rs1_data     (operand_a),
        .rs2_data     (operand_b_raw),
        .branch_taken (branch_taken)
    );

    branch_target_adder BR_TARGET (
        .pc            (ex_pc),
        .imm           (ex_imm),
        .branch_target (branch_target)
    );

    assign pc_plus4_ex = ex_pc + 32'd4;

    assign jump_target = (ex_jump && ex_alu_src) ? alu_result : branch_target;

    ex_mem EX_MEM (
        .clk               (clk),
        .reset             (reset),
        .flush             (ctrl_flush),
        .alu_result_in     (alu_result),
        .read_data2_in     (operand_b_raw),

        .rd_in             (ex_rd),

        .funct3_in         (ex_funct3),

        .pc_plus4_in       (pc_plus4_ex),

        .branch_taken_in   (branch_taken),
        .branch_target_in  (branch_target),

        .reg_write_in      (ex_reg_write),
        .mem_read_in       (ex_mem_read),
        .mem_write_in      (ex_mem_write),
        .mem_to_reg_in     (ex_mem_to_reg),
        .jump_in           (ex_jump),

        .alu_result_out    (mem_alu_result),
        .read_data2_out    (mem_rdata2),

        .rd_out            (mem_rd),

        .funct3_out        (mem_funct3),

        .pc_plus4_out      (mem_pc_plus4),

        .branch_taken_out  (mem_branch_taken_q),
        .branch_target_out (mem_branch_target_q),

        .reg_write_out     (mem_reg_write),
        .mem_read_out      (mem_mem_read),
        .mem_write_out     (mem_mem_write),
        .mem_to_reg_out    (mem_mem_to_reg),
        .jump_out          (mem_jump)
    );

    data_memory DMEM (
        .clk        (clk),
        .mem_read   (mem_mem_read),
        .mem_write  (mem_mem_write),
        .funct3     (mem_funct3),
        .address    (mem_alu_result),
        .write_data (mem_rdata2),
        .read_data  (dmem_read_data)
    );

    mem_wb MEM_WB (
        .clk             (clk),
        .reset           (reset),

        .memory_data_in  (dmem_read_data),
        .alu_result_in   (mem_alu_result),
        .pc_plus4_in     (mem_pc_plus4),
        .rd_in           (mem_rd),

        .reg_write_in    (mem_reg_write),
        .mem_to_reg_in   (mem_mem_to_reg),
        .jump_in         (mem_jump),

        .memory_data_out (wb_mem_data),
        .alu_result_out  (wb_alu_result),
        .pc_plus4_out    (wb_pc_plus4),
        .rd_out          (wb_rd),

        .reg_write_out   (wb_reg_write),
        .mem_to_reg_out  (wb_mem_to_reg),
        .jump_out        (wb_jump)
    );

    wb_mux WB_MUX (
        .alu_result      (wb_alu_result),
        .memory_data     (wb_mem_data),
        .pc_plus4        (wb_pc_plus4),
        .mem_to_reg      (wb_mem_to_reg),
        .jump            (wb_jump),
        .write_back_data (write_back_data)
    );
  
endmodule

