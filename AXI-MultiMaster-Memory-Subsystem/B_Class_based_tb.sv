interface axi_if #(parameter ADDR_WIDTH = 32,
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


class axi_transaction extends uvm_sequence_item;

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

    `uvm_object_utils(axi_transaction)

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

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
            $display("READ ADDR=%h",araddr);

    endfunction

endclass


class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    int num_tx = 200;

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    task body();

        axi_transaction tx;

        repeat(num_tx)
        begin
            tx = axi_transaction::type_id::create("tx");

            start_item(tx);

            assert(tx.randomize())
            else
                `uvm_fatal("SEQ", "Randomization Failed")

            finish_item(tx);
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

    task directed_write(bit [31:0] addr,
                        bit [31:0] data,
                        bit bready_val);

        axi_transaction tx;

        tx = axi_transaction::type_id::create("tx");

        start_item(tx);

        tx.awvalid = 1;
        tx.arvalid = 0;
        tx.wvalid  = 1;
        tx.awaddr  = addr;
        tx.wdata   = data;
        tx.bready  = bready_val;
        tx.rready  = 1;

        finish_item(tx);

    endtask

    task directed_read(bit [31:0] addr,
                       bit rready_val);

        axi_transaction tx;

        tx = axi_transaction::type_id::create("tx");

        start_item(tx);

        tx.awvalid = 0;
        tx.arvalid = 1;
        tx.araddr  = addr;
        tx.bready  = 1;
        tx.rready  = rready_val;

        finish_item(tx);

    endtask

endclass

class axi_sequencer extends uvm_sequencer #(axi_transaction);

    `uvm_component_utils(axi_sequencer)

    function new(string name = "axi_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass


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
      
      
      class axi_agent extends uvm_agent;

    `uvm_component_utils(axi_agent)

    axi_sequencer sequencer;
    axi_driver    driver;
    axi_monitor   monitor;

    function new(string name = "axi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer = axi_sequencer::type_id::create("sequencer", this);
        driver    = axi_driver::type_id::create("driver", this);
        monitor   = axi_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
      
      
      
      class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_transaction, axi_scoreboard) mon2scb;

    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
        mon2scb = new("mon2scb", this);
    endfunction

    function void write(axi_transaction tx);

        $display("SCOREBOARD");

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

    endfunction

endclass
      
      
      class axi_coverage extends uvm_subscriber #(axi_transaction);

    `uvm_component_utils(axi_coverage)

    axi_transaction tx;

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

    function new(string name = "axi_coverage", uvm_component parent);
        super.new(name, parent);
        axi_cg = new();
    endfunction

    function void write(axi_transaction t);
        tx = t;
        axi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

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
      
      
      class axi_test extends uvm_test;

    `uvm_component_utils(axi_test)

    axi_env env;
    axi_sequence seq;

    function new(string name = "axi_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = axi_env::type_id::create("env", this);
        seq = axi_sequence::type_id::create("seq");
    endfunction

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        seq.start(env.agent.sequencer);

        phase.drop_objection(this);

    endtask

endclass
      
      
      module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    axi_if vif();

    top_axi_system dut (
        .clk(vif.clk),
        .reset(vif.reset)
    );

    initial begin
        vif.clk = 0;
        forever #5 vif.clk = ~vif.clk;
    end

    initial begin
        vif.reset = 1;
        #20;
        vif.reset = 0;
    end

    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
        run_test("axi_test");
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
