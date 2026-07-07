  
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
      
