interface riscv_if;

    logic clk;
    logic reset;

    logic [31:0] pc_curr;
    logic [31:0] if_instruction;

    logic [31:0] wb_pc_plus4;
    logic [4:0]  wb_rd;
    logic        wb_reg_write;
    logic [31:0] write_back_data;

    logic        branch_taken;
    logic        ex_jump;
    logic        hazard_stall;
    logic        ctrl_flush;

endinterface
