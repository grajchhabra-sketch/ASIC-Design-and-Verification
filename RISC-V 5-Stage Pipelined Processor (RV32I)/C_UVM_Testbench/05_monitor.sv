class riscv_monitor extends uvm_monitor;

    `uvm_component_utils(riscv_monitor)

    virtual riscv_if vif;

    uvm_analysis_port #(riscv_seq_item) mon_ap;

    function new(string name = "riscv_monitor", uvm_component parent);
        super.new(name,parent);
        mon_ap = new("mon_ap",this);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if(!uvm_config_db #(virtual riscv_if)::get(this,"","vif",vif))
            `uvm_fatal("MONITOR","Virtual Interface Not Found")

    endfunction

    task run_phase(uvm_phase phase);

        riscv_seq_item tr;

        wait(vif.reset==0);

        forever begin

            @(posedge vif.clk);
            #1;

            tr = riscv_seq_item::type_id::create("tr");

            tr.pc              = vif.pc_curr;
            tr.instruction     = vif.if_instruction;

            tr.wb_pc_plus4     = vif.wb_pc_plus4;
            tr.wb_rd           = vif.wb_rd;
            tr.wb_reg_write    = vif.wb_reg_write;
            tr.write_back_data = vif.write_back_data;

            tr.branch_taken    = vif.branch_taken;
            tr.jump            = vif.ex_jump;
            tr.stall           = vif.hazard_stall;
            tr.flush           = vif.ctrl_flush;

            mon_ap.write(tr);

        end

    endtask

endclass
