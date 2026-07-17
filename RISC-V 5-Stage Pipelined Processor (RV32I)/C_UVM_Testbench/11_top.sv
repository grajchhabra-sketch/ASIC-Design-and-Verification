module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    riscv_if vif();

    riscv_top dut(
        .clk(vif.clk),
        .reset(vif.reset)
    );

    assign vif.pc_curr         = dut.pc_curr;
    assign vif.if_instruction  = dut.if_instruction;

    assign vif.wb_pc_plus4     = dut.wb_pc_plus4;
    assign vif.wb_rd           = dut.wb_rd;
    assign vif.wb_reg_write    = dut.wb_reg_write;
    assign vif.write_back_data = dut.write_back_data;

    assign vif.branch_taken    = dut.branch_taken;
    assign vif.ex_jump         = dut.ex_jump;
    assign vif.hazard_stall    = dut.hazard_stall;
    assign vif.ctrl_flush      = dut.ctrl_flush;

    initial begin
        vif.clk = 0;
        forever #5 vif.clk = ~vif.clk;
    end

    initial begin

        uvm_config_db #(virtual riscv_if)::set(null,"*","vif",vif);

        run_test("riscv_test");

    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,tb_top);
    end

endmodule
