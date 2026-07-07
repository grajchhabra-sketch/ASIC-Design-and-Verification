module top_axi_system(
    input clk,
    input reset
);

parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH = 32;

wire [ADDR_WIDTH-1:0] m0_awaddr;
wire                  m0_awvalid;
wire                  m0_awready;
wire [DATA_WIDTH-1:0] m0_wdata;
wire                  m0_wvalid;
wire                  m0_wready;
wire                  m0_bvalid;
wire                  m0_bready;
wire [ADDR_WIDTH-1:0] m0_araddr;
wire                  m0_arvalid;
wire                  m0_arready;
wire [DATA_WIDTH-1:0] m0_rdata;
wire                  m0_rvalid;
wire                  m0_rready;

wire [ADDR_WIDTH-1:0] m1_awaddr;
wire                  m1_awvalid;
wire                  m1_awready;
wire [DATA_WIDTH-1:0] m1_wdata;
wire                  m1_wvalid;
wire                  m1_wready;
wire                  m1_bvalid;
wire                  m1_bready;
wire [ADDR_WIDTH-1:0] m1_araddr;
wire                  m1_arvalid;
wire                  m1_arready;
wire [DATA_WIDTH-1:0] m1_rdata;
wire                  m1_rvalid;
wire                  m1_rready;

wire [ADDR_WIDTH-1:0] m2_awaddr;
wire                  m2_awvalid;
wire                  m2_awready;
wire [DATA_WIDTH-1:0] m2_wdata;
wire                  m2_wvalid;
wire                  m2_wready;
wire                  m2_bvalid;
wire                  m2_bready;
wire [ADDR_WIDTH-1:0] m2_araddr;
wire                  m2_arvalid;
wire                  m2_arready;
wire [DATA_WIDTH-1:0] m2_rdata;
wire                  m2_rvalid;
wire                  m2_rready;

axi_master master0(
    .clk(clk), .reset(reset),
    .M_AWADDR(m0_awaddr), .M_AWVALID(m0_awvalid), .M_AWREADY(m0_awready),
    .M_WDATA(m0_wdata), .M_WVALID(m0_wvalid), .M_WREADY(m0_wready),
    .M_BVALID(m0_bvalid), .M_BREADY(m0_bready),
    .M_ARADDR(m0_araddr), .M_ARVALID(m0_arvalid), .M_ARREADY(m0_arready),
    .M_RDATA(m0_rdata), .M_RVALID(m0_rvalid), .M_RREADY(m0_rready)
);

axi_master master1(
    .clk(clk), .reset(reset),
    .M_AWADDR(m1_awaddr), .M_AWVALID(m1_awvalid), .M_AWREADY(m1_awready),
    .M_WDATA(m1_wdata), .M_WVALID(m1_wvalid), .M_WREADY(m1_wready),
    .M_BVALID(m1_bvalid), .M_BREADY(m1_bready),
    .M_ARADDR(m1_araddr), .M_ARVALID(m1_arvalid), .M_ARREADY(m1_arready),
    .M_RDATA(m1_rdata), .M_RVALID(m1_rvalid), .M_RREADY(m1_rready)
);

axi_master master2(
    .clk(clk), .reset(reset),
    .M_AWADDR(m2_awaddr), .M_AWVALID(m2_awvalid), .M_AWREADY(m2_awready),
    .M_WDATA(m2_wdata), .M_WVALID(m2_wvalid), .M_WREADY(m2_wready),
    .M_BVALID(m2_bvalid), .M_BREADY(m2_bready),
    .M_ARADDR(m2_araddr), .M_ARVALID(m2_arvalid), .M_ARREADY(m2_arready),
    .M_RDATA(m2_rdata), .M_RVALID(m2_rvalid), .M_RREADY(m2_rready)
);

wire s_awready;
wire s_wready;
wire s_bvalid;
wire s_arready;
wire s_rvalid;
wire [31:0] s_rdata;



wire [2:0] req;
assign req[0] = m0_awvalid | m0_arvalid;
assign req[1] = m1_awvalid | m1_arvalid;
assign req[2] = m2_awvalid | m2_arvalid;

wire tx_done;
assign tx_done =
        (s_bvalid && (m0_bready || m1_bready || m2_bready))
     || (s_rvalid && (m0_rready || m1_rready || m2_rready));

wire [2:0] grant;

rr_arbiter arbiter(
    .clk(clk),
    .reset(reset),
    .req(req),
    .tx_done(tx_done),
    .grant(grant)
);

wire grant_valid = |grant;

reg [1:0] active_master;
always @(*)
begin
    case(grant)
        3'b001:  active_master = 2'd0;
        3'b010:  active_master = 2'd1;
        3'b100:  active_master = 2'd2;
        default: active_master = 2'b00; 
    endcase
end

wire [31:0] awaddr_mux =
    (active_master==0) ? m0_awaddr :
    (active_master==1) ? m1_awaddr :
    m2_awaddr;

wire awvalid_mux =
    grant_valid &&
    (
        (active_master==0) ? m0_awvalid :
        (active_master==1) ? m1_awvalid :
                              m2_awvalid
    );

wire [31:0] wdata_mux =
    (active_master==0) ? m0_wdata :
    (active_master==1) ? m1_wdata :
    m2_wdata;

wire wvalid_mux =
    grant_valid &&
    (
        (active_master==0) ? m0_wvalid :
        (active_master==1) ? m1_wvalid :
                              m2_wvalid
    );

wire [31:0] araddr_mux =
    (active_master==0) ? m0_araddr :
    (active_master==1) ? m1_araddr :
    m2_araddr;

wire arvalid_mux =
    grant_valid &&
    (
        (active_master==0) ? m0_arvalid :
        (active_master==1) ? m1_arvalid :
                              m2_arvalid
    );

wire fifo_full;
wire fifo_empty;

assign m0_awready = (grant==3'b001 && !fifo_full) ? s_awready : 1'b0;
assign m1_awready = (grant==3'b010 && !fifo_full) ? s_awready : 1'b0;
assign m2_awready = (grant==3'b100 && !fifo_full) ? s_awready : 1'b0;

assign m0_wready = (grant==3'b001 && !fifo_full) ? s_wready : 1'b0;
assign m1_wready = (grant==3'b010 && !fifo_full) ? s_wready : 1'b0;
assign m2_wready = (grant==3'b100 && !fifo_full) ? s_wready : 1'b0;

assign m0_arready = (grant==3'b001 && !fifo_full) ? s_arready : 1'b0;
assign m1_arready = (grant==3'b010 && !fifo_full) ? s_arready : 1'b0;
assign m2_arready = (grant==3'b100 && !fifo_full) ? s_arready : 1'b0;

assign m0_bvalid = (grant==3'b001) ? s_bvalid : 1'b0;
assign m1_bvalid = (grant==3'b010) ? s_bvalid : 1'b0;
assign m2_bvalid = (grant==3'b100) ? s_bvalid : 1'b0;

assign m0_rvalid = (grant==3'b001) ? s_rvalid : 1'b0;
assign m1_rvalid = (grant==3'b010) ? s_rvalid : 1'b0;
assign m2_rvalid = (grant==3'b100) ? s_rvalid : 1'b0;

assign m0_rdata = s_rdata;
assign m1_rdata = s_rdata;
assign m2_rdata = s_rdata;

wire bready_mux =
    (grant==3'b001) ? m0_bready :
    (grant==3'b010) ? m1_bready :
    (grant==3'b100) ? m2_bready :
                       1'b0;

wire rready_mux =
    (grant==3'b001) ? m0_rready :
    (grant==3'b010) ? m1_rready :
    (grant==3'b100) ? m2_rready :
                       1'b0;



wire [66:0] fifo_wr_data;
assign fifo_wr_data =
{
    (awvalid_mux | arvalid_mux),
    awvalid_mux,
    1'b0,
    awvalid_mux ? awaddr_mux : araddr_mux,
    awvalid_mux ? wdata_mux  : 32'd0
};

wire fifo_wr_en;
assign fifo_wr_en = (awvalid_mux || arvalid_mux) && !fifo_full;


wire [66:0] fifo_rd_data;
wire        fifo_rd_en;

reg [66:0] current_pkt;
reg        current_pkt_valid;
reg        pkt_active;
reg        pkt_aw_done;
reg        pkt_w_done;
reg        pkt_ar_seen;
reg        fifo_rd_en_d;   

wire pkt_valid = current_pkt_valid && current_pkt[66];
wire pkt_write = current_pkt[65];
wire [31:0] pkt_addr = current_pkt[63:32];
wire [31:0] pkt_data = current_pkt[31:0];

wire write_complete = pkt_active && pkt_valid && pkt_write &&
                       pkt_aw_done && pkt_w_done && s_bvalid && bready_mux;

wire read_complete  = pkt_active && pkt_valid && !pkt_write &&
                       pkt_ar_seen && s_rvalid && rready_mux;

assign fifo_rd_en = !fifo_empty && (!pkt_active || write_complete || read_complete);

always @(posedge clk or posedge reset)
begin
    if (reset) begin
        current_pkt       <= 67'd0;
        current_pkt_valid <= 1'b0;
        pkt_active         <= 1'b0;
        pkt_aw_done        <= 1'b0;
        pkt_w_done         <= 1'b0;
        pkt_ar_seen        <= 1'b0;
        fifo_rd_en_d       <= 1'b0;
    end
    else begin
        fifo_rd_en_d <= fifo_rd_en;

     
        if (fifo_rd_en_d) begin
            current_pkt       <= fifo_rd_data;
            current_pkt_valid <= 1'b1;
            pkt_active        <= 1'b1;
            pkt_aw_done        <= 1'b0;
            pkt_w_done         <= 1'b0;
            pkt_ar_seen        <= 1'b0;
        end
        else if (write_complete || read_complete) begin
            
            current_pkt_valid <= 1'b0;
            pkt_active         <= 1'b0;
            pkt_aw_done        <= 1'b0;
            pkt_w_done         <= 1'b0;
            pkt_ar_seen        <= 1'b0;
        end
        else begin
            if (pkt_active && pkt_valid && pkt_write) begin
                if (s_awready && !pkt_aw_done) pkt_aw_done <= 1'b1;
                if (s_wready  && !pkt_w_done)  pkt_w_done  <= 1'b1;
            end
            if (pkt_active && pkt_valid && !pkt_write) begin
                if (s_arready && !pkt_ar_seen) pkt_ar_seen <= 1'b1;
            end
        end
    end
end



asyn_fifo #(
    .data_width(67),
    .addr_width(4)
) fifo (
    .wr_clk(clk),
    .wr_resetn(~reset),
    .wr_en(fifo_wr_en),
    .wr_data(fifo_wr_data),

    .rd_clk(clk),
    .rd_resetn(~reset),
    .rd_en(fifo_rd_en),
    .rd_data(fifo_rd_data),

    .full(fifo_full),
    .empty(fifo_empty)
);



axi_slave slave0(
    .clk(clk),
    .reset(reset),

    .S_AWADDR(pkt_addr),
    .S_AWVALID(pkt_active && pkt_valid && pkt_write && !pkt_aw_done),
    .S_AWREADY(s_awready),

    .S_WDATA(pkt_data),
    .S_WVALID(pkt_active && pkt_valid && pkt_write && !pkt_w_done),
    .S_WREADY(s_wready),

    .S_BVALID(s_bvalid),
    .S_BREADY(bready_mux),

    .S_ARADDR(pkt_addr),
    .S_ARVALID(pkt_active && pkt_valid && !pkt_write && !pkt_ar_seen),
    .S_ARREADY(s_arready),

    .S_RDATA(s_rdata),
    .S_RVALID(s_rvalid),
    .S_RREADY(rready_mux)
);

endmodule
