`timescale 1ns/1ps

module tb_ddr_controller;

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 128;
parameter DEPTH      = 8;
parameter BANK_WIDTH = 3;
parameter ROW_WIDTH  = 13;
parameter COL_WIDTH  = 10;
parameter RANK_WIDTH = 3;
parameter NUM_BANKS  = 8;

reg clk;
reg reset;

reg                    req_valid;
reg                    req_write;
reg [ADDR_WIDTH-1:0]   req_addr;
reg [DATA_WIDTH-1:0]   req_wdata;

wire                   req_ready;

wire [DATA_WIDTH-1:0]  cpu_rdata;
wire                   cpu_rvalid;

wire                   rd_single_error;
wire                   rd_double_error;

wire                   ddr_cmd_act;
wire                   ddr_cmd_pre;
wire                   ddr_cmd_rd;
wire                   ddr_cmd_wr;
wire                   ddr_cmd_refresh;

wire [BANK_WIDTH-1:0]  ddr_bank;
wire [ROW_WIDTH-1:0]   ddr_row;
wire [COL_WIDTH-1:0]   ddr_col;
wire [RANK_WIDTH-1:0]  ddr_rank;

wire [ADDR_WIDTH-1:0]  ddr_addr;

wire [DATA_WIDTH-1:0]  ddr_wdata;
wire [15:0]            ddr_wecc;
wire                   ddr_wvalid;

reg  [DATA_WIDTH-1:0]  ddr_rdata;
reg  [15:0]            ddr_recc;
reg                    ddr_rvalid;

ddr_controller_top
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .BANK_WIDTH(BANK_WIDTH),
    .ROW_WIDTH(ROW_WIDTH),
    .COL_WIDTH(COL_WIDTH),
    .RANK_WIDTH(RANK_WIDTH),
    .NUM_BANKS(NUM_BANKS)
)
dut
(
    .clk(clk),
    .reset(reset),

    .req_valid_i(req_valid),
    .req_write_i(req_write),
    .req_addr_i(req_addr),
    .req_wdata_i(req_wdata),

    .req_ready_o(req_ready),

    .cpu_rdata_o(cpu_rdata),
    .cpu_rvalid_o(cpu_rvalid),

    .rd_single_error_o(rd_single_error),
    .rd_double_error_o(rd_double_error),

    .ddr_cmd_act_o(ddr_cmd_act),
    .ddr_cmd_pre_o(ddr_cmd_pre),
    .ddr_cmd_rd_o(ddr_cmd_rd),
    .ddr_cmd_wr_o(ddr_cmd_wr),
    .ddr_cmd_refresh_o(ddr_cmd_refresh),

    .ddr_bank_o(ddr_bank),
    .ddr_row_o(ddr_row),
    .ddr_col_o(ddr_col),
    .ddr_rank_o(ddr_rank),

    .ddr_addr_o(ddr_addr),

    .ddr_wdata_o(ddr_wdata),
    .ddr_wecc_o(ddr_wecc),
    .ddr_wvalid_o(ddr_wvalid),

    .ddr_rdata_i(ddr_rdata),
    .ddr_recc_i(ddr_recc),
    .ddr_rvalid_i(ddr_rvalid)
);

always #5 clk = ~clk;

initial begin

    clk = 1'b0;
    reset = 1'b1;

    req_valid = 1'b0;
    req_write = 1'b0;
    req_addr  = '0;
    req_wdata = '0;

    ddr_rdata  = '0;
    ddr_recc   = '0;
    ddr_rvalid = 1'b0;

end
  
  reg [DATA_WIDTH-1:0] mem     [0:255];
reg [15:0]           mem_ecc [0:255];

task reset_dut;
begin

    reset = 1'b1;

    repeat(5) @(posedge clk);

    reset = 1'b0;

    repeat(5) @(posedge clk);

end
endtask

task cpu_write;

input [ADDR_WIDTH-1:0] addr;
input [DATA_WIDTH-1:0] data;

begin

    @(posedge clk);

    while(!req_ready)
        @(posedge clk);

    req_valid <= 1'b1;
    req_write <= 1'b1;
    req_addr  <= addr;
    req_wdata <= data;

    @(posedge clk);

    req_valid <= 1'b0;
    req_write <= 1'b0;
    req_addr  <= '0;
    req_wdata <= '0;

end

endtask

task cpu_read;

input [ADDR_WIDTH-1:0] addr;

begin

    @(posedge clk);

    while(!req_ready)
        @(posedge clk);

    req_valid <= 1'b1;
    req_write <= 1'b0;
    req_addr  <= addr;
    req_wdata <= '0;

    @(posedge clk);

    req_valid <= 1'b0;
    req_addr  <= '0;

end

endtask

always @(posedge clk) begin

    ddr_rvalid <= 1'b0;

    if(ddr_wvalid) begin

        mem[ddr_addr[9:2]]     <= ddr_wdata;
        mem_ecc[ddr_addr[9:2]] <= ddr_wecc;

    end

    if(ddr_cmd_rd) begin

        ddr_rdata  <= mem[ddr_addr[9:2]];
        ddr_recc   <= mem_ecc[ddr_addr[9:2]];
        ddr_rvalid <= 1'b1;

    end

end
  
  initial begin

    reset_dut();

    $display("TEST 1 : SINGLE WRITE");

    cpu_write(
        32'h0001_1000,
        128'h11112222333344445555666677778888
    );

    repeat(20) @(posedge clk);

    $display("TEST 2 : SINGLE READ");

    cpu_read(32'h0001_1000);

    wait(cpu_rvalid);

    $display("[%0t] READ DATA = %h",
             $time,
             cpu_rdata);

    repeat(20) @(posedge clk);

    $display("TEST 3 : ROW HIT");

    cpu_write(
        32'h0001_1008,
        128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    );

    cpu_write(
        32'h0001_1010,
        128'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
    );

    repeat(30) @(posedge clk);

    $display("TEST 4 : ROW CONFLICT");

    cpu_write(
        32'h0012_1000,
        128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
    );

    repeat(40) @(posedge clk);

    $display("TEST 5 : REFRESH");

    repeat(900) @(posedge clk);

    cpu_read(32'h0012_1000);

    wait(cpu_rvalid);

    $display("[%0t] READ DATA AFTER REFRESH = %h",
             $time,
             cpu_rdata);

    repeat(20) @(posedge clk);

    $display("ALL DIRECTED TESTS COMPLETED");

    $finish;

end
  
  always @(posedge clk) begin

    if(ddr_cmd_act)

        $display("[%0t] ACTIVATE  Bank=%0d Row=%0d",
                 $time,
                 ddr_bank,
                 ddr_row);

    if(ddr_cmd_pre)

        $display("[%0t] PRECHARGE Bank=%0d",
                 $time,
                 ddr_bank);

    if(ddr_cmd_rd)

        $display("[%0t] READ      Addr=%h Bank=%0d Row=%0d Col=%0d",
                 $time,
                 ddr_addr,
                 ddr_bank,
                 ddr_row,
                 ddr_col);

    if(ddr_cmd_wr)

        $display("[%0t] WRITE     Addr=%h Bank=%0d Row=%0d Col=%0d",
                 $time,
                 ddr_addr,
                 ddr_bank,
                 ddr_row,
                 ddr_col);

    if(ddr_cmd_refresh)

        $display("[%0t] REFRESH",
                 $time);

    if(ddr_wvalid)

        $display("[%0t] DDR WRITE DATA = %h  ECC = %h",
                 $time,
                 ddr_wdata,
                 ddr_wecc);

    if(cpu_rvalid)

        $display("[%0t] CPU READ DATA = %h",
                 $time,
                 cpu_rdata);

    if(rd_single_error)

        $display("[%0t] ECC SINGLE BIT ERROR DETECTED",
                 $time);

    if(rd_double_error)

        $display("[%0t] ECC DOUBLE BIT ERROR DETECTED",
                 $time);

end

initial begin

    $monitor("[%0t] READY=%b VALID=%b WRITE=%b ADDR=%h",
             $time,
             req_ready,
             req_valid,
             req_write,
             req_addr);

end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_ddr_controller);
end

endmodule
