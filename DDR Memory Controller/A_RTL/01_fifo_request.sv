module fifo_request
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 128,
    parameter DEPTH      = 8,
    parameter PTR_WIDTH  = 3
)
(
    input clk,
    input reset,

    input                      req_valid_i,
    input                      req_write_i,
    input [ADDR_WIDTH-1:0]     req_addr_i,
    input [DATA_WIDTH-1:0]     req_wdata_i,

    input                      pop_i,

    output                     fifo_valid_o,
    output                     fifo_write_o,
    output [ADDR_WIDTH-1:0]    fifo_addr_o,
    output [DATA_WIDTH-1:0]    fifo_wdata_o,

    output                     full_o,
    output                     empty_o
);

reg                    write_mem [0:DEPTH-1];
reg [ADDR_WIDTH-1:0]   addr_mem  [0:DEPTH-1];
reg [DATA_WIDTH-1:0]   wdata_mem [0:DEPTH-1];

reg [PTR_WIDTH-1:0] wr_ptr;
reg [PTR_WIDTH-1:0] rd_ptr;
reg [PTR_WIDTH:0]   count;

wire push;

assign push = req_valid_i && !full_o;

assign full_o  = (count == DEPTH);
assign empty_o = (count == 0);

assign fifo_valid_o = !empty_o;

assign fifo_write_o = write_mem[rd_ptr];
assign fifo_addr_o  = addr_mem[rd_ptr];
assign fifo_wdata_o = wdata_mem[rd_ptr];

always @(posedge clk) begin

    if(reset) begin

        wr_ptr <= 0;
        rd_ptr <= 0;
        count  <= 0;

    end
    else begin

        case({push,(pop_i && !empty_o)})

            2'b10: begin

                write_mem[wr_ptr] <= req_write_i;
                addr_mem[wr_ptr]  <= req_addr_i;
                wdata_mem[wr_ptr] <= req_wdata_i;

                wr_ptr <= wr_ptr + 1'b1;
                count  <= count + 1'b1;

            end

            2'b01: begin

                rd_ptr <= rd_ptr + 1'b1;
                count  <= count - 1'b1;

            end
                      2'b11: begin

                write_mem[wr_ptr] <= req_write_i;
                addr_mem[wr_ptr]  <= req_addr_i;
                wdata_mem[wr_ptr] <= req_wdata_i;

                wr_ptr <= wr_ptr + 1'b1;
                rd_ptr <= rd_ptr + 1'b1;

            end

            default: begin

 
            end

        endcase

    end

end

property p_no_overflow;
    @(posedge clk)
    disable iff(reset)
    push |-> !full_o;
endproperty

assert property(p_no_overflow)
else
    $fatal(1,"FIFO Overflow");
property p_no_underflow;

    @(posedge clk)
    disable iff(reset)

    pop_i |-> ($past(count) > 0);

endproperty

assert property(p_no_underflow)
else
    $fatal(1,"FIFO Underflow");

endmodule
