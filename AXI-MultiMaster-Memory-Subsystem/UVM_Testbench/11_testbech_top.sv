`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_top;


  bit clk;
  bit reset;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
  end


  axi_if m0_if(clk);
  axi_if m1_if(clk);
  axi_if m2_if(clk);


  top_axi_system dut(
    .clk   (clk),
    .reset (reset)
  );


  always @(posedge clk) begin
    $display("T=%0t m0_awvalid=%b m0_awready=%b m0_arvalid=%b m0_arready=%b",
             $time,
             dut.m0_awvalid,
             dut.m0_awready,
             dut.m0_arvalid,
             dut.m0_arready);
  end



  assign m0_if.awaddr  = dut.m0_awaddr;
  assign m0_if.awvalid = dut.m0_awvalid;
  assign m0_if.awready = dut.m0_awready;
  assign m0_if.wdata   = dut.m0_wdata;
  assign m0_if.wvalid  = dut.m0_wvalid;
  assign m0_if.wready  = dut.m0_wready;
  assign m0_if.bvalid  = dut.m0_bvalid;
  assign m0_if.bready  = dut.m0_bready;
  assign m0_if.araddr  = dut.m0_araddr;
  assign m0_if.arvalid = dut.m0_arvalid;
  assign m0_if.arready = dut.m0_arready;
  assign m0_if.rdata   = dut.m0_rdata;
  assign m0_if.rvalid  = dut.m0_rvalid;
  assign m0_if.rready  = dut.m0_rready;

  assign m1_if.awaddr  = dut.m1_awaddr;
  assign m1_if.awvalid = dut.m1_awvalid;
  assign m1_if.awready = dut.m1_awready;
  assign m1_if.wdata   = dut.m1_wdata;
  assign m1_if.wvalid  = dut.m1_wvalid;
  assign m1_if.wready  = dut.m1_wready;
  assign m1_if.bvalid  = dut.m1_bvalid;
  assign m1_if.bready  = dut.m1_bready;
  assign m1_if.araddr  = dut.m1_araddr;
  assign m1_if.arvalid = dut.m1_arvalid;
  assign m1_if.arready = dut.m1_arready;
  assign m1_if.rdata   = dut.m1_rdata;
  assign m1_if.rvalid  = dut.m1_rvalid;
  assign m1_if.rready  = dut.m1_rready;

  assign m2_if.awaddr  = dut.m2_awaddr;
  assign m2_if.awvalid = dut.m2_awvalid;
  assign m2_if.awready = dut.m2_awready;
  assign m2_if.wdata   = dut.m2_wdata;
  assign m2_if.wvalid  = dut.m2_wvalid;
  assign m2_if.wready  = dut.m2_wready;
  assign m2_if.bvalid  = dut.m2_bvalid;
  assign m2_if.bready  = dut.m2_bready;
  assign m2_if.araddr  = dut.m2_araddr;
  assign m2_if.arvalid = dut.m2_arvalid;
  assign m2_if.arready = dut.m2_arready;
  assign m2_if.rdata   = dut.m2_rdata;
  assign m2_if.rvalid  = dut.m2_rvalid;
  assign m2_if.rready  = dut.m2_rready;

  initial begin

    uvm_config_db #(virtual axi_if)::set(
      null,
      "*agent0*",
      "vif",
      m0_if);

    uvm_config_db #(virtual axi_if)::set(
      null,
      "*agent1*",
      "vif",
      m1_if);

    uvm_config_db #(virtual axi_if)::set(
      null,
      "*agent2*",
      "vif",
      m2_if);

    run_test("axi_test");
  end

endmodule
