interface soc_if #(parameter ADDR_WIDTH = 32,
                   parameter DATA_WIDTH = 32);

    logic clk;
    logic reset;


    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;


    logic [DATA_WIDTH-1:0] wdata;
    logic                  wvalid;
    logic                  wready;


    logic                  bvalid;
    logic                  bready;


    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;


    logic [DATA_WIDTH-1:0] rdata;
    logic                  rvalid;
    logic                  rready;

endinterface

class soc_tx;

    rand bit awvalid;
    rand bit [31:0] awaddr;

    rand bit wvalid;
    rand bit [31:0] wdata;

    rand bit arvalid;
    rand bit [31:0] araddr;

    rand bit bready;
    rand bit rready;

    rand bit [1:0] aw_region;
    rand bit [1:0] ar_region;



    constraint c_rw
    {
        awvalid dist {1:=50,0:=50};

        if(awvalid)
            arvalid == 0;
        else
            arvalid == 1;
    }

    constraint c_wvalid
    {
        if(awvalid)
            wvalid == 1;
        else
            wvalid == 0;
    }

    constraint c_ready
    {
        bready dist {1:=80,0:=20};
        rready dist {1:=80,0:=20};
    }

  
    constraint c_region
    {
        aw_region inside {0,1,2};
        ar_region inside {0,1,2};
    }

    constraint c_data
    {
        wdata dist {

            [32'h00000000:32'h3FFFFFFF] := 25,

            [32'h40000000:32'h7FFFFFFF] := 25,

            [32'h80000000:32'hBFFFFFFF] := 25,

            [32'hC0000000:32'hFFFFFFFF] := 25

        };
    }

   

    function void post_randomize();

        case(aw_region)

            0:
                awaddr = ($urandom_range(0,32'h00000FFF))
                         & 32'hFFFFFFFC;

            1:
                awaddr = (32'h00001000 +
                         $urandom_range(0,32'h0000EFFF))
                         & 32'hFFFFFFFC;

            2:
                awaddr = (32'h00010000 +
                         $urandom_range(0,32'h0000FFFF))
                         & 32'hFFFFFFFC;

        endcase


        case(ar_region)

            0:
                araddr = ($urandom_range(0,32'h00000FFF))
                         & 32'hFFFFFFFC;

            1:
                araddr = (32'h00001000 +
                         $urandom_range(0,32'h0000EFFF))
                         & 32'hFFFFFFFC;

            2:
                araddr = (32'h00010000 +
                         $urandom_range(0,32'h0000FFFF))
                         & 32'hFFFFFFFC;

        endcase

    endfunction


    function void display();

        if(awvalid)
            $display("WRITE ADDR=%h DATA=%h",awaddr,wdata);

        else
            $display("READ  ADDR=%h",araddr);

    endfunction

endclass
class driver;

  virtual soc_if vif;
  mailbox #(soc_tx) gen2drv;

  function new(virtual soc_if vif,
               mailbox #(soc_tx) gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();

    soc_tx tx;

    wait(vif.reset == 0);

    forever begin

      gen2drv.get(tx);

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

    end

  endtask

endclass : driver

class generator;

    mailbox #(soc_tx) gen2drv;

    int num_tx = 30000;

    function new(mailbox #(soc_tx) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    task run();

        soc_tx tx;
        repeat(num_tx)
        begin
            tx = new();

            assert(tx.randomize())
            else
                $fatal("Randomization Failed");

            gen2drv.put(tx);
        end

        directed_write(32'h00000000, 32'h00000000, 1); 
        directed_write(32'h00000004, 32'h50000000, 0); 
        directed_write(32'h00008000, 32'h90000000, 1); 
        directed_write(32'h00008004, 32'hF0000000, 0); 
        directed_write(32'hFFFFFFFC, 32'h00000001, 1); 
        directed_write(32'hFFFFFFF8, 32'hFFFFFFFF, 0); 


        directed_read(32'h00000000, 1);
        directed_read(32'h00000004, 0);
        directed_read(32'h00008000, 1);
        directed_read(32'h00008004, 0);
        directed_read(32'hFFFFFFFC, 1);
        directed_read(32'hFFFFFFF8, 0);

    endtask

 
    task directed_write(bit [31:0] addr, bit [31:0] data, bit bready_val);
        soc_tx tx;
        tx = new();
        tx.awvalid = 1;
        tx.arvalid = 0;
        tx.wvalid  = 1;
        tx.awaddr  = addr;
        tx.wdata   = data;
        tx.bready  = bready_val;
        tx.rready  = 1;
        gen2drv.put(tx);
    endtask

    task directed_read(bit [31:0] addr, bit rready_val);
        soc_tx tx;
        tx = new();
        tx.awvalid = 0;
        tx.arvalid = 1;
        tx.araddr  = addr;
        tx.bready  = 1;
        tx.rready  = rready_val;
        gen2drv.put(tx);
    endtask

endclass
class monitor;

  virtual soc_if vif;

  mailbox #(soc_tx) mon2scb;
  mailbox #(soc_tx) mon2cov;

  function new(
      virtual soc_if vif,
      mailbox #(soc_tx) mon2scb,
      mailbox #(soc_tx) mon2cov
  );
      this.vif     = vif;
      this.mon2scb = mon2scb;
      this.mon2cov = mon2cov;
  endfunction


  task run();

      soc_tx tx;

      wait(vif.reset == 0);

      forever begin

          @(posedge vif.clk);

          if(vif.awvalid || vif.arvalid) begin

              tx = new();

           
              tx.awvalid = vif.awvalid;
              tx.awaddr  = vif.awaddr;

              tx.wvalid  = vif.wvalid;
              tx.wdata   = vif.wdata;

          
              tx.arvalid = vif.arvalid;
              tx.araddr  = vif.araddr;

           
              tx.bready = vif.bready;
              tx.rready = vif.rready;

             
              mon2scb.put(tx);
              mon2cov.put(tx);

          end

      end

  endtask

endclass
class scoreboard;

  mailbox #(soc_tx) mon2scb;

  function new(mailbox #(soc_tx) mon2scb);
    this.mon2scb = mon2scb;
    
  endfunction

  task run();

    soc_tx tx;

    forever begin

      mon2scb.get(tx);

     
      $display("SCOREBOARD");

      // Write Transaction
      if(tx.awvalid)
      begin
        $display("WRITE TRANSACTION");
        $display("Address : %h", tx.awaddr);
        $display("Data    : %h", tx.wdata);

        if(tx.wvalid)
          $display("RESULT  : WRITE PASS");
        else
          $display("RESULT  : WRITE FAIL (WDATA Missing)");
      end

      // Read Transaction
      else if(tx.arvalid)
      begin
        $display("READ TRANSACTION");
        $display("Address : %h", tx.araddr);
        $display("RESULT  : READ PASS");
      end

      else
      begin
        $display("NO VALID TRANSACTION");
      end

    end

  endtask

endclass
      
class coverage;

    mailbox #(soc_tx) mon2cov;
    soc_tx tx;

    covergroup axi_cg;
        option.per_instance = 1;

        cp_write : coverpoint tx.awvalid {
            bins write     = {1};
            bins not_write = {0};
        }

        cp_read : coverpoint tx.arvalid {
            bins read     = {1};
            bins not_read = {0};
        }

        cp_awaddr : coverpoint tx.awaddr {
            bins low  = {[32'h00000000:32'h00000FFF]};
            bins mid  = {[32'h00001000:32'h0000FFFF]};
            bins high = {[32'h00010000:32'hFFFFFFFF]};
            ignore_bins iv = {32'h0} iff (tx.awvalid == 0);
        }

        cp_araddr : coverpoint tx.araddr {
            bins low  = {[32'h00000000:32'h00000FFF]};
            bins mid  = {[32'h00001000:32'h0000FFFF]};
            bins high = {[32'h00010000:32'hFFFFFFFF]};
        }

        cp_wdata : coverpoint tx.wdata {
            bins low  = {[32'h00000000:32'h3FFFFFFF]};
            bins mid1 = {[32'h40000000:32'h7FFFFFFF]};
            bins mid2 = {[32'h80000000:32'hBFFFFFFF]};
            bins high = {[32'hC0000000:32'hFFFFFFFF]};
        }

        cp_bready : coverpoint tx.bready {
            bins ready     = {1};
            bins not_ready = {0};
        }

        cp_rready : coverpoint tx.rready {
            bins ready     = {1};
            bins not_ready = {0};
        }

        cross cp_write, cp_awaddr;
        cross cp_write, cp_wdata;
        cross cp_read, cp_araddr;
        cross cp_write, cp_bready;
        cross cp_read, cp_rready;

    endgroup

    function new(mailbox #(soc_tx) mon2cov);
        this.mon2cov = mon2cov;
        axi_cg = new();
    endfunction

    task run();
        forever begin
            mon2cov.get(tx);
            axi_cg.sample();
        end
    endtask

    function void report();
        $display("FUNCTIONAL COVERAGE = %0.2f %%", axi_cg.get_coverage());
        $display("cp_write   = %0.2f", axi_cg.cp_write.get_coverage());
        $display("cp_read    = %0.2f", axi_cg.cp_read.get_coverage());
        $display("cp_awaddr  = %0.2f", axi_cg.cp_awaddr.get_coverage());
        $display("cp_araddr  = %0.2f", axi_cg.cp_araddr.get_coverage());
        $display("cp_wdata   = %0.2f", axi_cg.cp_wdata.get_coverage());
        $display("cp_bready  = %0.2f", axi_cg.cp_bready.get_coverage());
        $display("cp_rready  = %0.2f", axi_cg.cp_rready.get_coverage());
    endfunction

endclass
class environment;

  generator   gen;
  driver      drv;
  monitor     mon;
  scoreboard  scb;
  coverage    cov;

  mailbox #(soc_tx) gen2drv;
  mailbox #(soc_tx) mon2scb;
  mailbox #(soc_tx) mon2cov;

  virtual soc_if vif;

  function new(virtual soc_if vif);

    this.vif = vif;

    gen2drv = new();
    mon2scb = new();
    mon2cov = new();

    gen = new(gen2drv);
    drv = new(vif, gen2drv);
    mon = new(vif, mon2scb, mon2cov);
    scb = new(mon2scb);
    cov = new(mon2cov);

  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
      cov.run();
    join_none
  endtask

endclass
class test;

  environment env;

  virtual soc_if vif;

  function new(virtual soc_if vif);

    this.vif = vif;

    env = new(vif);

  endfunction

  task run();

    $display(" SOC SYSTEM TEST STARTED");

    env.run();
    
  endtask

  function void report();
    env.cov.report();
  endfunction

endclass

module tb_top;

  soc_if vif();


  top_axi_system dut(
      .clk(vif.clk),
      .reset(vif.reset)
  );

 
  test t;


  initial begin
      vif.clk = 0;
      forever #5 vif.clk = ~vif.clk;
  end

  initial begin
      vif.reset = 1'b1;
      #20;
      vif.reset = 1'b0;
  end

  

  initial begin

      t = new(vif);

      t.run();

  end

  initial begin
      #10000;
      t.report();
      $display("\nSimulation Finished");
      $finish;
  end

 
  initial begin
      $dumpfile("wave.vcd");
      $dumpvars(0, tb_top);
  end

endmodule
      
      
      
      
