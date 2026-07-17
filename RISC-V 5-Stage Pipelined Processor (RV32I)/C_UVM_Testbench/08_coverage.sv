class riscv_coverage extends uvm_subscriber #(riscv_seq_item);

    `uvm_component_utils(riscv_coverage)

    riscv_seq_item tx;

    covergroup riscv_cg;
        option.per_instance = 1;

        cp_opcode : coverpoint tx.instruction[6:0] {
            bins r_type   = {7'b0110011};
            bins i_type   = {7'b0010011};
            bins load     = {7'b0000011};
            bins store    = {7'b0100011};
            bins branch   = {7'b1100011};
            bins jal      = {7'b1101111};
            bins jalr     = {7'b1100111};
            bins lui      = {7'b0110111};
            bins auipc    = {7'b0010111};
        }

        cp_stall : coverpoint tx.stall {
            bins stalled     = {1};
            bins not_stalled = {0};
        }

        cp_flush : coverpoint tx.flush {
            bins flushed     = {1};
            bins not_flushed = {0};
        }

        cp_branch_taken : coverpoint tx.branch_taken {
            bins taken     = {1};
            bins not_taken = {0};
        }

        cp_jump : coverpoint tx.jump {
            bins jumped     = {1};
            bins not_jumped = {0};
        }

        cp_wb_we : coverpoint tx.wb_reg_write {
            bins write     = {1};
            bins not_write = {0};
        }

        cross cp_opcode, cp_stall;
        cross cp_opcode, cp_flush;
        cross cp_branch_taken, cp_flush;

    endgroup

    function new(string name="riscv_coverage",uvm_component parent);
        super.new(name,parent);
        riscv_cg = new();
    endfunction

    function void write(riscv_seq_item t);
        tx = t;
        riscv_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COVERAGE",
        $sformatf("\nFunctional Coverage = %.2f %%",riscv_cg.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_opcode        : %.2f",riscv_cg.cp_opcode.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_stall         : %.2f",riscv_cg.cp_stall.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_flush         : %.2f",riscv_cg.cp_flush.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_branch_taken  : %.2f",riscv_cg.cp_branch_taken.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_jump          : %.2f",riscv_cg.cp_jump.get_coverage()),
        UVM_NONE)

        `uvm_info("COVERAGE",
        $sformatf("cp_wb_we         : %.2f",riscv_cg.cp_wb_we.get_coverage()),
        UVM_NONE)
    endfunction

endclass
