
class axi_driver extends uvm_driver #(axi_txn);

  `uvm_component_utils(axi_driver)

  virtual axi_if vif;

  function new(string name,
               uvm_component parent);
    super.new(name,parent);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    if(!uvm_config_db #(virtual axi_if)::get
       (this,"","vif",vif))
      `uvm_fatal("DRV","Virtual Interface not found");

  endfunction


  task run_phase(uvm_phase phase);

    axi_txn tx;

    forever begin

      `uvm_info("DRV",
                "Waiting for transaction",
                UVM_LOW)

      seq_item_port.get_next_item(tx);

      `uvm_info("DRV",
                "Got transaction",
                UVM_LOW)

      if(tx.write)
        drive_write(tx);
      else
        drive_read(tx);

      seq_item_port.item_done();

    end

  endtask


  task drive_write(axi_txn tx);

    int timeout;



    @(posedge vif.clk);

    vif.awaddr  <= tx.addr;
    vif.awvalid <= 1'b1;

    `uvm_info("DRV",
              $sformatf("WRITE ADDR=%h",tx.addr),
              UVM_LOW)

    timeout = 100;

    while(!vif.awready && timeout>0)
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if(timeout==0)
      `uvm_fatal("DRV","AWREADY timeout")

    vif.awvalid <= 0;


    @(posedge vif.clk);

    vif.wdata  <= tx.data;
    vif.wvalid <= 1'b1;

    timeout = 100;

    while(!vif.wready && timeout>0)
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if(timeout==0)
      `uvm_fatal("DRV","WREADY timeout")

    vif.wvalid <= 0;

    @(posedge vif.clk);

    vif.bready <= 1'b1;

    timeout = 100;

    while(!vif.bvalid && timeout>0)
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if(timeout==0)
      `uvm_fatal("DRV","BVALID timeout")

    @(posedge vif.clk);

    vif.bready <= 0;

    `uvm_info("DRV",
              $sformatf(
              "WRITE COMPLETE ADDR=%h DATA=%h",
              tx.addr,
              tx.data),
              UVM_LOW)

  endtask



  task drive_read(axi_txn tx);

    int timeout;


    @(posedge vif.clk);

    vif.araddr  <= tx.addr;
    vif.arvalid <= 1'b1;

    `uvm_info("DRV",
              $sformatf("READ ADDR=%h",tx.addr),
              UVM_LOW)

    timeout = 100;

    while(!vif.arready && timeout>0)
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if(timeout==0)
      `uvm_fatal("DRV","ARREADY timeout")

    vif.arvalid <= 0;


    @(posedge vif.clk);

    vif.rready <= 1'b1;

    timeout = 100;

    while(!vif.rvalid && timeout>0)
    begin
      @(posedge vif.clk);
      timeout--;
    end

    if(timeout==0)
      `uvm_fatal("DRV","RVALID timeout")

    tx.rdata = vif.rdata;

    @(posedge vif.clk);

    vif.rready <= 0;

    `uvm_info("DRV",
              $sformatf(
              "READ COMPLETE ADDR=%h DATA=%h",
              tx.addr,
              tx.rdata),
              UVM_LOW)

  endtask

endclass
