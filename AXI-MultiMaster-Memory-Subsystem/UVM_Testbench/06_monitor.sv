
class axi_monitor extends uvm_monitor;

  `uvm_component_utils(axi_monitor)

  virtual axi_if vif;

  uvm_analysis_port #(axi_txn) mon_ap;

  function new(string name,
               uvm_component parent);

    super.new(name,parent);

    mon_ap = new("mon_ap",this);

  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(!uvm_config_db #(virtual axi_if)::get(
          this,
          "",
          "vif",
          vif))
      `uvm_fatal("MON","NO VIF")

    `uvm_info("MON",
              "Virtual Interface Connected",
              UVM_NONE)

  endfunction


  task run_phase(uvm_phase phase);

    axi_txn tx;

    `uvm_info("MON",
              "Monitor Started",
              UVM_NONE)

    forever
    begin

      @(posedge vif.clk);

   

      `uvm_info("MON",
                $sformatf(
                "AWV=%0b AWR=%0b WV=%0b WR=%0b ARV=%0b ARR=%0b RV=%0b RR=%0b",
                vif.awvalid,
                vif.awready,
                vif.wvalid,
                vif.wready,
                vif.arvalid,
                vif.arready,
                vif.rvalid,
                vif.rready),
                UVM_NONE)

      if(vif.awvalid && vif.awready)
      begin

        tx = axi_txn::type_id::create("wr_tx");

        tx.write = 1;
        tx.addr  = vif.awaddr;

        `uvm_info("MON",
                  $sformatf(
                  "WRITE ADDR HANDSHAKE ADDR=%h",
                  tx.addr),
                  UVM_NONE)

        wait(vif.wvalid && vif.wready);

        tx.data = vif.wdata;

        `uvm_info("MON",
                  $sformatf(
                  "WRITE DATA=%h",
                  tx.data),
                  UVM_NONE)

        mon_ap.write(tx);

        `uvm_info("MON",
                  "WRITE TXN SENT TO SCOREBOARD",
                  UVM_NONE)

      end

      if(vif.arvalid && vif.arready)
      begin

        tx = axi_txn::type_id::create("rd_tx");

        tx.write = 0;
        tx.addr  = vif.araddr;

        `uvm_info("MON",
                  $sformatf(
                  "READ ADDR HANDSHAKE ADDR=%h",
                  tx.addr),
                  UVM_NONE)

        wait(vif.rvalid && vif.rready);

        tx.rdata = vif.rdata;

        `uvm_info("MON",
                  $sformatf(
                  "READ DATA=%h",
                  tx.rdata),
                  UVM_NONE)

        mon_ap.write(tx);

        `uvm_info("MON",
                  "READ TXN SENT TO SCOREBOARD",
                  UVM_NONE)

      end

    end

  endtask

endclass
