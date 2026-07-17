 module ddr_controller_top
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 128,
    parameter DEPTH      = 8,
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH  = 13,
    parameter COL_WIDTH  = 10,
    parameter RANK_WIDTH = 3,
    parameter NUM_BANKS  = 8
)
(
    input clk,
    input reset,

    input                     req_valid_i,
    input                     req_write_i,
    input [ADDR_WIDTH-1:0]    req_addr_i,
    input [DATA_WIDTH-1:0]    req_wdata_i,

    output                    req_ready_o,

    output [DATA_WIDTH-1:0]   cpu_rdata_o,
    output                    cpu_rvalid_o,

    output                    rd_single_error_o,
    output                    rd_double_error_o,

    output                    ddr_cmd_act_o,
    output                    ddr_cmd_pre_o,
    output                    ddr_cmd_rd_o,
    output                    ddr_cmd_wr_o,
    output                    ddr_cmd_refresh_o,

    output [BANK_WIDTH-1:0]   ddr_bank_o,
    output [ROW_WIDTH-1:0]    ddr_row_o,
    output [COL_WIDTH-1:0]    ddr_col_o,
    output [RANK_WIDTH-1:0]   ddr_rank_o,

    output [ADDR_WIDTH-1:0]   ddr_addr_o,

    output [DATA_WIDTH-1:0]   ddr_wdata_o,
    output [15:0]             ddr_wecc_o,
    output                    ddr_wvalid_o,

    input  [DATA_WIDTH-1:0]   ddr_rdata_i,
    input  [15:0]             ddr_recc_i,
    input                     ddr_rvalid_i
);

wire fifo_valid;
wire fifo_write;
wire [ADDR_WIDTH-1:0] fifo_addr;
wire [DATA_WIDTH-1:0] fifo_wdata;
wire fifo_pop;
wire fifo_full;
wire fifo_empty;

wire sched_valid;
wire sched_write;

wire [ADDR_WIDTH-1:0] sched_addr;
wire [DATA_WIDTH-1:0] sched_wdata;

wire [BANK_WIDTH-1:0] sched_bank;
wire [ROW_WIDTH-1:0]  sched_row;
wire [COL_WIDTH-1:0]  sched_col;
wire [RANK_WIDTH-1:0] sched_rank;

wire bank_row_hit;
wire bank_row_miss;
wire bank_row_conflict;

wire [NUM_BANKS-1:0] bank_open_valid;
wire [NUM_BANKS*ROW_WIDTH-1:0] bank_open_row;

wire trcd_done;
wire trp_done;
wire tras_done;
wire trfc_done;

wire req_ready_o_int;
wire controller_busy;

wire [DATA_WIDTH-1:0] ddr_wdata;

assign req_ready_o = !fifo_full;
   
   fifo_request
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
)
u_fifo
(
    .clk(clk),
    .reset(reset),

    .req_valid_i(req_valid_i),
    .req_write_i(req_write_i),
    .req_addr_i(req_addr_i),
    .req_wdata_i(req_wdata_i),

    .pop_i(fifo_pop),

    .fifo_valid_o(fifo_valid),
    .fifo_write_o(fifo_write),
    .fifo_addr_o(fifo_addr),
    .fifo_wdata_o(fifo_wdata),

    .full_o(fifo_full),
    .empty_o(fifo_empty)
);

fr_fcfs_scheduler
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
u_scheduler
(
    .clk(clk),
    .reset(reset),

    .fifo_valid_i(fifo_valid),
    .fifo_write_i(fifo_write),
    .fifo_addr_i(fifo_addr),
    .fifo_wdata_i(fifo_wdata),

    .pop_fifo_o(fifo_pop),

    .bank_open_valid_i(bank_open_valid),
    .bank_open_row_i(bank_open_row),

    .controller_ready_i(req_ready_o_int),
    .sched_ready_i(req_ready_o_int),

    .sched_valid_o(sched_valid),
    .sched_write_o(sched_write),
    .sched_addr_o(sched_addr),
    .sched_wdata_o(sched_wdata),

    .sched_bank_o(sched_bank),
    .sched_row_o(sched_row),
    .sched_col_o(sched_col),
    .sched_rank_o(sched_rank)
);

bank_state
#(
    .NUM_BANKS(NUM_BANKS),
    .BANK_WIDTH(BANK_WIDTH),
    .ROW_WIDTH(ROW_WIDTH)
)
u_bank_state
(
    .clk(clk),
    .reset(reset),

    .req_valid_i(sched_valid),
    .bank_i(sched_bank),
    .row_i(sched_row),

    .act_cmd_i(ddr_cmd_act_o),
    .act_bank_i(ddr_bank_o),
    .act_row_i(ddr_row_o),

    .pre_cmd_i(ddr_cmd_pre_o),
    .pre_bank_i(ddr_bank_o),

    .row_hit_o(bank_row_hit),
    .row_miss_o(bank_row_miss),
    .row_conflict_o(bank_row_conflict),

    .bank_open_valid_o(bank_open_valid),
    .bank_open_row_o(bank_open_row)
);
   
   timing_manager
u_timing
(
    .clk(clk),
    .reset(reset),

    .act_cmd_i(ddr_cmd_act_o),
    .pre_cmd_i(ddr_cmd_pre_o),
    .refresh_cmd_i(ddr_cmd_refresh_o),

    .trcd_done_o(trcd_done),
    .trp_done_o(trp_done),
    .tras_done_o(tras_done),
    .trfc_done_o(trfc_done)
);

command_fsm
#(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BANK_WIDTH(BANK_WIDTH),
    .ROW_WIDTH(ROW_WIDTH),
    .COL_WIDTH(COL_WIDTH),
    .RANK_WIDTH(RANK_WIDTH)
)
u_command_fsm
(
    .clk(clk),
    .reset(reset),

    .req_valid_i(sched_valid),
    .req_write_i(sched_write),
    .req_addr_i(sched_addr),
    .req_wdata_i(sched_wdata),

    .bank_i(sched_bank),
    .row_i(sched_row),
    .col_i(sched_col),
    .rank_i(sched_rank),

    .req_ready_o(req_ready_o_int),

    .row_hit_i(bank_row_hit),
    .row_miss_i(bank_row_miss),
    .row_conflict_i(bank_row_conflict),

    .trcd_done_i(trcd_done),
    .trp_done_i(trp_done),
    .tras_done_i(tras_done),
    .trfc_done_i(trfc_done),

    .act_cmd_o(ddr_cmd_act_o),
    .pre_cmd_o(ddr_cmd_pre_o),
    .rd_cmd_o(ddr_cmd_rd_o),
    .wr_cmd_o(ddr_cmd_wr_o),
    .refresh_cmd_o(ddr_cmd_refresh_o),

    .bank_o(ddr_bank_o),
    .row_o(ddr_row_o),
    .col_o(ddr_col_o),
    .rank_o(ddr_rank_o),

    .cmd_addr_o(ddr_addr_o),
    .cmd_wdata_o(ddr_wdata),

    .busy_o(controller_busy)
);
   write_data_path
#(
    .DATA_WIDTH(DATA_WIDTH)
)
u_write_path
(
    .clk(clk),
    .reset(reset),

    .cmd_wr_i(ddr_cmd_wr_o),
    .cmd_wdata_i(ddr_wdata),

    .ddr_wdata_o(ddr_wdata_o),
    .ddr_wecc_o(ddr_wecc_o),
    .ddr_wvalid_o(ddr_wvalid_o)
);

read_data_path
#(
    .DATA_WIDTH(DATA_WIDTH)
)
u_read_path
(
    .clk(clk),
    .reset(reset),

    .read_valid_i(ddr_rvalid_i),

    .ddr_rdata_i(ddr_rdata_i),
    .ddr_recc_i(ddr_recc_i),

    .cpu_rdata_o(cpu_rdata_o),
    .cpu_rvalid_o(cpu_rvalid_o),

    .single_error_o(rd_single_error_o),
    .double_error_o(rd_double_error_o)
);

endmodule
