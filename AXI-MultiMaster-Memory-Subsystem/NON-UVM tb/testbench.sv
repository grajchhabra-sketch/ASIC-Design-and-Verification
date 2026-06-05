`timescale 1ns/1ps

module tb_axi_normal;

reg clk;
reg reset;

initial begin
clk = 0;
forever #5 clk = ~clk;
end

initial begin
reset = 1;
#30;
reset = 0;
end

top_axi_system dut(
.clk(clk),
.reset(reset)
);

reg [31:0] ref_mem [0:255];

integer write_count;
integer read_count;
integer pass_count;
integer fail_count;
integer i;

covergroup axi_cg @(posedge clk);

option.per_instance = 1;

AWADDR_CP : coverpoint dut.m0_awaddr
iff(dut.m0_awvalid && dut.m0_awready)
{
    bins b0 = {[32'h1000:32'h103F]};
    bins b1 = {[32'h1040:32'h107F]};
    bins b2 = {[32'h1080:32'h10BF]};
    bins b3 = {[32'h10C0:32'h10FF]};
    bins b4 = {[32'h1100:32'h113F]};
    bins b5 = {[32'h1140:32'h117F]};
    bins b6 = {[32'h1180:32'h11BF]};
    bins b7 = {[32'h11C0:32'h11FF]};
}

WDATA_CP : coverpoint dut.m0_wdata
iff(dut.m0_wvalid && dut.m0_wready)
{
    bins zero = {32'h00000000};
    bins ones = {32'hFFFFFFFF};
    bins alt1 = {32'h55555555};
    bins alt2 = {32'hAAAAAAAA};

    bins range1 = {[32'hA5A50000:32'hA5A53FFF]};
    bins range2 = {[32'hA5A54000:32'hA5A57FFF]};
    bins range3 = {[32'hA5A58000:32'hA5A5BFFF]};
    bins range4 = {[32'hA5A5C000:32'hA5A5FFFF]};
}

RDATA_CP : coverpoint dut.m0_rdata
iff(dut.m0_rvalid && dut.m0_rready)
{
    bins zero = {32'h00000000};
    bins ones = {32'hFFFFFFFF};
    bins alt1 = {32'h55555555};
    bins alt2 = {32'hAAAAAAAA};

    bins range1 = {[32'hA5A50000:32'hA5A53FFF]};
    bins range2 = {[32'hA5A54000:32'hA5A57FFF]};
    bins range3 = {[32'hA5A58000:32'hA5A5BFFF]};
    bins range4 = {[32'hA5A5C000:32'hA5A5FFFF]};
}

MASTER_CP : coverpoint dut.active_master
{
    bins m0 = {0};
    bins m1 = {1};
    bins m2 = {2};
}
WRITE_HS : coverpoint
(dut.m0_awvalid && dut.m0_awready);

READ_HS : coverpoint
(dut.m0_rvalid && dut.m0_rready);
  
  M1_AW : coverpoint dut.m1_awvalid;
M2_AW : coverpoint dut.m2_awvalid;
endgroup

axi_cg cg = new();

always @(posedge clk)
begin


if(dut.m0_awvalid && dut.m0_awready)
begin
    write_count = write_count + 1;
    $display("WRITE_ADDR,%0t,%h",$time,dut.m0_awaddr);
end

if(dut.m0_wvalid && dut.m0_wready)
begin
    ref_mem[dut.m0_awaddr[9:2]] = dut.m0_wdata;
    $display("WRITE_DATA,%0t,%h",$time,dut.m0_wdata);
end


end

always @(posedge clk)
begin


if(dut.m0_rvalid && dut.m0_rready)
begin

    read_count = read_count + 1;

    if(dut.m0_rdata == ref_mem[dut.m0_araddr[9:2]])
    begin
        pass_count = pass_count + 1;
        $display("READ_PASS,%0t,%h",$time,dut.m0_rdata);
    end
    else
    begin
        fail_count = fail_count + 1;
        $display("READ_FAIL,%0t EXP=%h GOT=%h",
                 $time,
                 ref_mem[dut.m0_araddr[9:2]],
                 dut.m0_rdata);
    end

end


end

initial
begin


write_count = 0;
read_count  = 0;
pass_count  = 0;
fail_count  = 0;

for(i=0;i<256;i=i+1)
    ref_mem[i] = 0;


end

initial
begin


  wait(write_count >= 310 && read_count >= 310);

#100;

$display("");
$display("AXI TEST SUMMARY");

$display("WRITES    = %0d",write_count);
$display("READS     = %0d",read_count);
$display("PASS      = %0d",pass_count);
$display("FAIL      = %0d",fail_count);
$display("COVERAGE  = %0.2f %%",cg.get_coverage());

if(fail_count == 0)
    $display("TEST_PASS");
else
    $display("TEST_FAIL");

$finish;


end

initial
begin
#50000;

$display("TIMEOUT");
$display("TEST_FAIL");

$finish;


end

endmodule

