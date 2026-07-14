module if_id(input clk, input reset, input stall, input flush, input [31:0] pc_in, input [31:0] instruction_in, output reg [31:0] pc_out, output reg [31:0] instruction_out);
  always@(posedge clk or posedge reset)
    begin
  
  if(reset)
    begin
      pc_out<=32'h00000000;
      instruction_out<=32'h00000013;
    end
  else if (flush)
    begin
      pc_out<=32'h00000000;
      instruction_out<=32'h00000013;
    end
  else if (!stall)
    begin
      pc_out<=pc_in;
      instruction_out<=instruction_in;
    end
  end
  
  property p_ifid_flush_nop;
  @(posedge clk) disable iff(reset)
    flush |=> (instruction_out == 32'h00000013);
endproperty
assert property(p_ifid_flush_nop)
  else $error("IF/ID did not insert NOP on flush");
  
  property p_ifid_stall_hold;
  @(posedge clk) disable iff(reset)
    (stall && !flush) |=> $stable(instruction_out);
endproperty
assert property(p_ifid_stall_hold)
  else $error("IF/ID instruction changed during stall");
endmodule
