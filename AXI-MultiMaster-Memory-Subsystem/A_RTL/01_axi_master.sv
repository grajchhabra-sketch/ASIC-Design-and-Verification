// AXI MASTER
module axi_master#( parameter addr_width=32,
                   parameter data_width=32)(
  input clk, 
  input reset,
//write address channel
  output reg [addr_width-1:0]M_AWADDR,
  output reg                 M_AWVALID,
  input                      M_AWREADY,
//write data channel  
  output reg [data_width-1:0]M_WDATA,
  output reg                 M_WVALID,
  input                      M_WREADY,
//write response channel  
  input                      M_BVALID,
  output reg                 M_BREADY,
//read address channel  
  output reg [addr_width-1:0]M_ARADDR,
  output reg                 M_ARVALID,
  input                      M_ARREADY,
//read data channel  
  input      [data_width-1:0]M_RDATA,
  input                      M_RVALID,
  output reg                 M_RREADY
);
//fsm states
  localparam IDLE = 3'b000;
  localparam SEND_AW = 3'b001;
  localparam SEND_W = 3'b010;
  localparam WAIT_B = 3'b011;
  localparam SEND_AR = 3'b100;
  localparam WAIT_R = 3'b101;
  
  reg [2:0] state;
//0=write, 1=read  
  reg mode;
//read data storage
  reg [data_width-1:0] read_data;
//sequential 
  always@(posedge clk or posedge reset)
    begin
      
      if(reset)
        begin
          state<=IDLE;
          mode<=0;
          M_AWADDR<=0;
          M_AWVALID<=0;
          M_WDATA<=0;
          M_WVALID<=0;
          M_BREADY<=0;
          M_ARADDR<=0;
          M_ARVALID<=0;
          M_RREADY<=0;
          read_data<=0;
        end
      
      else
        begin
          case(state)
            IDLE:
              begin
            
            mode<=~mode;
            
            if(mode==0)
              begin
                M_AWADDR<=32'h1000;
                M_WDATA<=32'hA5A50001;
                M_AWVALID<=1;
                state<=SEND_AW;
              end
            else
              begin
                M_ARADDR<=32'h1000;
                M_ARVALID<=1;
                state<=SEND_AR;
              end
            end
            
            SEND_AW:
              begin
                if(M_AWREADY)
                  begin
                    M_AWVALID<=0;
                    M_WVALID<=1;
                    state<=SEND_W;
                  end
              end
            
            SEND_W:
              begin
                if(M_WREADY)
                  begin
                    M_WVALID<=0;
                    M_BREADY<=1;
                    state<=WAIT_B;
                  end
              end
            
            WAIT_B:
              begin
                if(M_BVALID)
                  begin
                    M_BREADY<=0;
                    M_AWADDR<=M_AWADDR+4;
                    M_WDATA<=M_WDATA+1;
                    state<=IDLE;
                  end
              end
            
            SEND_AR:
              begin
                if(M_ARREADY)
                  begin
                    M_ARVALID<=0;
                    M_RREADY<=1;
                    state<=WAIT_R;
                  end
              end
            
            WAIT_R:
              begin
                if(M_RVALID)
                  begin
                    read_data<=M_RDATA;
                    M_RREADY<=0;
                    M_ARADDR<=M_ARADDR+4;
                    state<=IDLE;
                  end
              end
          endcase
        end
    end
  
  property p_awvalid_until_ready;
  @(posedge clk) disable iff(reset)
    M_AWVALID && !M_AWREADY |=> M_AWVALID;
endproperty

assert property(p_awvalid_until_ready)
  else $error("AWVALID dropped before AWREADY handshake");
  
  
  property p_wvalid_until_ready;
  @(posedge clk) disable iff(reset)
    M_WVALID && !M_WREADY |=> M_WVALID;
endproperty

assert property(p_wvalid_until_ready)
  else $error("WVALID dropped before WREADY handshake");
  
endmodule
