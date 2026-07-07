        
     // AXI SLAVE
module axi_slave
#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH      = 256
)
(
    input clk,
    input reset,

    input  [ADDR_WIDTH-1:0] S_AWADDR,
    input                   S_AWVALID,
    output reg              S_AWREADY,

    input  [DATA_WIDTH-1:0] S_WDATA,
    input                   S_WVALID,
    output reg              S_WREADY,

    output reg              S_BVALID,
    input                   S_BREADY,

    input  [ADDR_WIDTH-1:0] S_ARADDR,
    input                   S_ARVALID,
    output reg              S_ARREADY,

    output reg [DATA_WIDTH-1:0] S_RDATA,
    output reg                  S_RVALID,
    input                       S_RREADY
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

localparam IDLE      = 3'b000;
localparam WAIT_DATA = 3'b001;
localparam WRITE_RESP= 3'b010;

localparam READ_WAIT = 3'b011;
localparam READ_RESP = 3'b100;


reg [2:0] state;

reg [ADDR_WIDTH-1:0] addr_reg;

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin

        S_AWREADY <= 0;
        S_WREADY  <= 0;
        S_BVALID  <= 0;
        S_ARREADY <= 0;
        S_RVALID  <= 0;
        S_RDATA   <= 0;
        addr_reg  <= 0;
        state <= IDLE;

    end


    else
    begin

        case(state)


        IDLE:
        begin

            S_AWREADY <= 1;
            S_ARREADY <= 1;


            if(S_AWVALID)
            begin

                addr_reg <= S_AWADDR;
                S_AWREADY <= 0;
                S_WREADY <= 1;
                S_ARREADY <=0;
                state <= WAIT_DATA;

            end


            else if(S_ARVALID)
            begin

                addr_reg<=S_ARADDR;
                S_ARREADY<=0;
              state<=READ_WAIT;

            end

        end

        WAIT_DATA:
        begin
 
          S_WREADY <= 1;
            if(S_WVALID)
            begin

                mem[addr_reg[9:2]] <=S_WDATA;
                S_WREADY<=0;
                S_BVALID<=1;
                state<=WRITE_RESP;

            end

        end

        WRITE_RESP:
        begin

            if(S_BREADY)
            begin

                S_BVALID<=0;
                state<=IDLE;

            end

        end

        READ_WAIT:
        begin

            S_RDATA<= mem[addr_reg[9:2]];

            S_RVALID<=1;

            state<=READ_RESP;

        end

        READ_RESP:
        begin

            if(S_RREADY)
            begin

                S_RVALID<=0;
                state<=IDLE;

            end
        end
        endcase

    end
end
  
  property p_bvalid_until_bready;
  @(posedge clk) disable iff(reset)
    S_BVALID && !S_BREADY |=> S_BVALID;
endproperty

assert property(p_bvalid_until_bready)
  else $error("BVALID dropped before BREADY");
  
  property p_rvalid_until_rready;
  @(posedge clk) disable iff(reset)
    S_RVALID && !S_RREADY |=> S_RVALID;
endproperty

assert property(p_rvalid_until_rready)
  else $error("RVALID dropped before RREADY");
  
endmodule
