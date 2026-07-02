 module pc(input clk, input reset, input stall, input [31:0]pc_next, output reg [31:0]pc);
  
  always@(posedge clk or posedge reset)
    begin
      if(reset)
        pc<=32'h00000000;
      else if(!stall)
        pc<=pc_next;
    end
endmodule

module pc_next(
  input  [31:0] pc,
  input  [31:0] branch_target,
  input  [31:0] jump_target,
  input         branch_taken,
  input         jump,
  output [31:0] pc_next
);

  assign pc_next = jump ? jump_target :
                   branch_taken ? branch_target :
                   pc + 32'd4;

endmodule

module inst_mem( input [31:0]pc, output [31:0] instruction);
  reg [31:0] mem [0:255];
  
  assign instruction = mem[pc[9:2]];
  
  initial
    begin
      $readmemh("program.hex",mem);
    end
  endmodule
