class riscv_test extends uvm_test;

    `uvm_component_utils(riscv_test)

    riscv_env env;
    riscv_sequence seq;

    function new(string name="riscv_test", uvm_component parent);
        super.new(name,parent);
    endfunction

    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        env = riscv_env::type_id::create("env",this);

    endfunction

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        seq = riscv_sequence::type_id::create("seq");

        seq.start(env.agent.sequencer);

        #1000;

        phase.drop_objection(this);

    endtask

endclass
