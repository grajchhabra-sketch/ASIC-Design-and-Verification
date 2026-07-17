  
  module timing_manager
#(
    parameter TRCD = 4,
    parameter TRP  = 4,
    parameter TRAS = 8,
    parameter TRFC = 16
)
(
    input clk,
    input reset,

    input act_cmd_i,
    input pre_cmd_i,
    input refresh_cmd_i,

    output trcd_done_o,
    output trp_done_o,
    output tras_done_o,
    output trfc_done_o
);

reg [7:0] trcd_cnt;
reg [7:0] trp_cnt;
reg [7:0] tras_cnt;
reg [7:0] trfc_cnt;

assign trcd_done_o = (trcd_cnt == 0);
assign trp_done_o  = (trp_cnt  == 0);
assign tras_done_o = (tras_cnt == 0);
assign trfc_done_o = (trfc_cnt == 0);

always @(posedge clk) begin

    if(reset) begin

        trcd_cnt <= 0;
        trp_cnt  <= 0;
        tras_cnt <= 0;
        trfc_cnt <= 0;

    end
    else begin

   if(act_cmd_i)
    trcd_cnt <= TRCD;
    else if(trcd_cnt!=0)
    trcd_cnt <= trcd_cnt-1;

    if(act_cmd_i)
       tras_cnt <= TRAS;
    else if(tras_cnt!=0)
        tras_cnt <= tras_cnt-1;

        if(pre_cmd_i)

            trp_cnt <= TRP;

        else if(trp_cnt != 0)

            trp_cnt <= trp_cnt - 1;
      
              if(refresh_cmd_i)

            trfc_cnt <= TRFC;

        else if(trfc_cnt != 0)

            trfc_cnt <= trfc_cnt - 1;

    end

end

property p_trcd_load;
    @(posedge clk)
    disable iff(reset)
    act_cmd_i |=> (trcd_cnt == TRCD);
endproperty

assert property(p_trcd_load)
else
    $fatal(1,"tRCD counter not loaded");

property p_trp_load;
    @(posedge clk)
    disable iff(reset)
    pre_cmd_i |=> (trp_cnt == TRP);
endproperty

assert property(p_trp_load)
else
    $fatal(1,"tRP counter not loaded");

property p_trfc_load;
    @(posedge clk)
    disable iff(reset)
    refresh_cmd_i |=> (trfc_cnt == TRFC);
endproperty

assert property(p_trfc_load)
else
    $fatal(1,"tRFC counter not loaded");

endmodule
