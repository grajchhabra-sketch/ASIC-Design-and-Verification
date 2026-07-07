
class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    virtual axi_if vif;

    function new(string name = "axi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Virtual Interface Not Found")
    endfunction

    task run_phase(uvm_phase phase);

        axi_transaction tx;

        wait(vif.reset == 0);

        forever begin

            seq_item_port.get_next_item(tx);

            @(posedge vif.clk);

            vif.awaddr  <= tx.awaddr;
            vif.awvalid <= tx.awvalid;

            vif.wdata   <= tx.wdata;
            vif.wvalid  <= tx.wvalid;

            vif.araddr  <= tx.araddr;
            vif.arvalid <= tx.arvalid;

            vif.bready  <= tx.bready;
            vif.rready  <= tx.rready;

            @(posedge vif.clk);

            vif.awvalid <= 0;
            vif.wvalid  <= 0;
            vif.arvalid <= 0;

            seq_item_port.item_done();

        end

    endtask

endclass
      
