      
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
