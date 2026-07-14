module mem_wb(

    input clk,
    input reset,

    // Data inputs
    input  [31:0] memory_data_in,
    input  [31:0] alu_result_in,

    // PC+4 for JAL/JALR writeback
    input  [31:0] pc_plus4_in,

    // Destination register
    input  [4:0]  rd_in,

    // Control inputs
    input         reg_write_in,
    input         mem_to_reg_in,
    input         jump_in,

    // Data outputs
    output reg [31:0] memory_data_out,
    output reg [31:0] alu_result_out,

    output reg [31:0] pc_plus4_out,

    // Destination register output
    output reg [4:0]  rd_out,

    // Control outputs
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        jump_out

);

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            memory_data_out <= 32'b0;
            alu_result_out  <= 32'b0;
            pc_plus4_out    <= 32'b0;
            rd_out          <= 5'b0;
            reg_write_out   <= 1'b0;
            mem_to_reg_out  <= 1'b0;
            jump_out        <= 1'b0;

        end else begin

            memory_data_out <= memory_data_in;
            alu_result_out  <= alu_result_in;
            pc_plus4_out    <= pc_plus4_in;
            rd_out          <= rd_in;
            reg_write_out   <= reg_write_in;
            mem_to_reg_out  <= mem_to_reg_in;
            jump_out        <= jump_in;

        end
    end

endmodule
