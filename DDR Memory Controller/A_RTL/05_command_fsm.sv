 module command_fsm
#(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 128,
    parameter BANK_WIDTH  = 3,
    parameter ROW_WIDTH   = 13,
    parameter COL_WIDTH   = 10,
    parameter RANK_WIDTH  = 3,

    parameter INIT_DELAY   = 100,
    parameter REF_INTERVAL = 780
)
(
    input clk,
    input reset,

    input                     req_valid_i,
    input                     req_write_i,
    input [ADDR_WIDTH-1:0]    req_addr_i,
    input [DATA_WIDTH-1:0]    req_wdata_i,

    input [BANK_WIDTH-1:0]    bank_i,
    input [ROW_WIDTH-1:0]     row_i,
    input [COL_WIDTH-1:0]     col_i,
    input [RANK_WIDTH-1:0]    rank_i,

    output                    req_ready_o,

    input row_hit_i,
    input row_miss_i,
    input row_conflict_i,

    input trcd_done_i,
    input trp_done_i,
    input tras_done_i,
    input trfc_done_i,

    output reg act_cmd_o,
    output reg pre_cmd_o,
    output reg rd_cmd_o,
    output reg wr_cmd_o,
    output reg refresh_cmd_o,

    output reg [BANK_WIDTH-1:0] bank_o,
    output reg [ROW_WIDTH-1:0]  row_o,
    output reg [COL_WIDTH-1:0]  col_o,
    output reg [RANK_WIDTH-1:0] rank_o,

    output reg [ADDR_WIDTH-1:0] cmd_addr_o,
    output reg [DATA_WIDTH-1:0] cmd_wdata_o,

    output busy_o
);

localparam RESET_STATE = 4'd0;
localparam INIT_STATE  = 4'd1;
localparam IDLE        = 4'd2;
localparam PRECHARGE   = 4'd3;
localparam WAIT_TRP    = 4'd4;
localparam ACTIVATE    = 4'd5;
localparam WAIT_TRCD   = 4'd6;
localparam READ_STATE  = 4'd7;
localparam WRITE_STATE = 4'd8;
localparam REFRESH     = 4'd9;
localparam WAIT_TRFC   = 4'd10;
localparam WAIT_TRAS   = 4'd11;

reg [3:0] state;
reg [3:0] next_state;

reg pending_write;

reg [ADDR_WIDTH-1:0] pending_addr;
reg [DATA_WIDTH-1:0] pending_wdata;

reg [BANK_WIDTH-1:0] pending_bank;
reg [ROW_WIDTH-1:0]  pending_row;
reg [COL_WIDTH-1:0]  pending_col;
reg [RANK_WIDTH-1:0] pending_rank;

reg [15:0] init_counter;
reg [15:0] refresh_counter;

reg refresh_pending;

reg pending_needs_precharge;

assign req_ready_o = (state == IDLE);

assign busy_o = (state != IDLE);

always @(posedge clk) begin

    if(reset) begin

        init_counter    <= 16'd0;
        refresh_counter <= 16'd0;
        refresh_pending <= 1'b0;

        pending_write <= 1'b0;

        pending_addr  <= '0;
        pending_wdata <= '0;

        pending_bank  <= '0;
        pending_row   <= '0;
        pending_col   <= '0;
        pending_rank  <= '0;

    end
    else begin

        if(state == RESET_STATE)

            init_counter <= init_counter + 1'b1;

        if(state != RESET_STATE)

            refresh_counter <= refresh_counter + 1'b1;

        if(refresh_counter >= REF_INTERVAL)

            refresh_pending <= 1'b1;

        if(state == WAIT_TRFC) begin

            refresh_counter <= 16'd0;
            refresh_pending <= 1'b0;

        end

        if(state == IDLE && req_valid_i) begin

            pending_write <= req_write_i;

            pending_addr  <= req_addr_i;
            pending_wdata <= req_wdata_i;

            pending_bank  <= bank_i;
            pending_row   <= row_i;
            pending_col   <= col_i;
            pending_rank  <= rank_i;

        end

    end

end

always @(posedge clk) begin

    if(reset)

        state <= RESET_STATE;

    else

        state <= next_state;

end

always @(*) begin

    next_state = state;
    pending_needs_precharge = 1'b0;

    case(state)

        RESET_STATE: begin

            if(init_counter >= INIT_DELAY)

                next_state = INIT_STATE;

        end

        INIT_STATE: begin

            next_state = IDLE;

        end

        IDLE: begin

            if(refresh_pending)

                next_state = REFRESH;

            else if(req_valid_i) begin

                if(row_hit_i) begin

                    if(req_write_i)

                        next_state = WRITE_STATE;

                    else

                        next_state = READ_STATE;

                end

                else if(row_conflict_i) begin

                    if(tras_done_i)

                        next_state = PRECHARGE;

                    else

                        next_state = WAIT_TRAS;

                end

                else if(row_miss_i)

                    next_state = ACTIVATE;

            end

        end

        WAIT_TRAS: begin

            if(tras_done_i)

                next_state = PRECHARGE;

        end

        PRECHARGE: begin

            next_state = WAIT_TRP;

        end

        WAIT_TRP: begin

            if(trp_done_i)

                next_state = ACTIVATE;

        end

        ACTIVATE: begin

            next_state = WAIT_TRCD;

        end

        WAIT_TRCD: begin

            if(trcd_done_i) begin

                if(pending_write)

                    next_state = WRITE_STATE;

                else

                    next_state = READ_STATE;

            end

        end

        READ_STATE: begin

            next_state = IDLE;

        end

        WRITE_STATE: begin

            next_state = IDLE;

        end

        REFRESH: begin

            next_state = WAIT_TRFC;

        end

        WAIT_TRFC: begin

            if(trfc_done_i)

                next_state = IDLE;

        end

        default: begin

            next_state = RESET_STATE;

        end

    endcase

end

always @(*) begin

    act_cmd_o     = 1'b0;
    pre_cmd_o     = 1'b0;
    rd_cmd_o      = 1'b0;
    wr_cmd_o      = 1'b0;
    refresh_cmd_o = 1'b0;

    bank_o = pending_bank;
    row_o  = pending_row;
    col_o  = pending_col;
    rank_o = pending_rank;

    cmd_addr_o  = pending_addr;
    cmd_wdata_o = pending_wdata;

    case(state)

        INIT_STATE: begin

        end

        
        PRECHARGE: begin

            pre_cmd_o = 1'b1;

        end

        ACTIVATE: begin

            act_cmd_o = 1'b1;

        end

        READ_STATE: begin

            rd_cmd_o = 1'b1;

        end

        WRITE_STATE: begin

            wr_cmd_o = 1'b1;

        end

        REFRESH: begin

            refresh_cmd_o = 1'b1;

        end

        default: begin

        end

    endcase

end

always @(posedge clk) begin

    if(!reset) begin

        if(state == ACTIVATE)

            $display("[%0t] ACT Bank=%0d Row=%0d",
                     $time,
                     pending_bank,
                     pending_row);

        if(state == PRECHARGE)

            $display("[%0t] PRE Bank=%0d",
                     $time,
                     pending_bank);

        if(state == READ_STATE)

            $display("[%0t] READ Bank=%0d Row=%0d Col=%0d",
                     $time,
                     pending_bank,
                     pending_row,
                     pending_col);

        if(state == WRITE_STATE)

            $display("[%0t] WRITE Bank=%0d Row=%0d Col=%0d",
                     $time,
                     pending_bank,
                     pending_row,
                     pending_col);

        if(state == REFRESH)

            $display("[%0t] REFRESH",
                     $time);

    end

end

property p_single_command;

    @(posedge clk)
    disable iff(reset)

    !(act_cmd_o && pre_cmd_o) &&
    !(act_cmd_o && rd_cmd_o)  &&
    !(act_cmd_o && wr_cmd_o)  &&
    !(act_cmd_o && refresh_cmd_o) &&
    !(pre_cmd_o && rd_cmd_o)  &&
    !(pre_cmd_o && wr_cmd_o)  &&
    !(pre_cmd_o && refresh_cmd_o) &&
    !(rd_cmd_o && wr_cmd_o)   &&
    !(rd_cmd_o && refresh_cmd_o) &&
    !(wr_cmd_o && refresh_cmd_o);

endproperty

assert property(p_single_command)
else
    $fatal(1,"Multiple DDR commands asserted");

property p_ready_only_idle;

    @(posedge clk)
    disable iff(reset)

    req_ready_o |-> (state == IDLE);

endproperty

assert property(p_ready_only_idle)
else
    $fatal(1,"Request accepted outside IDLE");


property p_busy;

    @(posedge clk)
    disable iff(reset)

    (state != IDLE) |-> busy_o;

endproperty

assert property(p_busy)
else
    $fatal(1,"Busy signal incorrect");


property p_tras_before_precharge;

    @(posedge clk)
    disable iff(reset)

    pre_cmd_o |-> tras_done_i;

endproperty

assert property(p_tras_before_precharge)
else
    $fatal(1,"PRECHARGE issued before tRAS satisfied");

endmodule
  
