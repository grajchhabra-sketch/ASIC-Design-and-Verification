      class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual axi_if vif;

    uvm_analysis_port #(axi_transaction) mon2scb;
    uvm_analysis_port #(axi_transaction) mon2cov;

    function new(string name = "axi_monitor", uvm_component parent);
        super.new(name, parent);

        mon2scb = new("mon2scb", this);
        mon2cov = new("mon2cov", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Virtual Interface Not Found")
    endfunction

    task run_phase(uvm_phase phase);

        axi_transaction tx;

        wait(vif.reset == 0);

        forever begin

            @(posedge vif.clk);

            if(vif.awvalid || vif.arvalid) begin

                tx = axi_transaction::type_id::create("tx");

                tx.awvalid = vif.awvalid;
                tx.awaddr  = vif.awaddr;

                tx.wvalid  = vif.wvalid;
                tx.wdata   = vif.wdata;

                tx.arvalid = vif.arvalid;
                tx.araddr  = vif.araddr;

                tx.bready  = vif.bready;
                tx.rready  = vif.rready;

                mon2scb.write(tx);
                mon2cov.write(tx);

            end

        end

    endtask

endclass
      
