    class axi_env extends uvm_env;

    `uvm_component_utils(axi_env)

    axi_agent      agent;
    axi_scoreboard scb;
    axi_coverage   cov;

    function new(string name = "axi_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = axi_agent::type_id::create("agent", this);
        scb   = axi_scoreboard::type_id::create("scb", this);
        cov   = axi_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        agent.monitor.mon2scb.connect(scb.mon2scb);
        agent.monitor.mon2cov.connect(cov.analysis_export);
    endfunction

endclass
