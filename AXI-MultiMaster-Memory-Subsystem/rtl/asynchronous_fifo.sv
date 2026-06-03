  // ASYNCHRONOUS FIFO
module asyn_fifo#(parameter data_width = 67,
                  parameter addr_width = 4)(
  
  input wr_clk,
  input wr_resetn,
  input wr_en,
  input [data_width-1:0]wr_data,
  
  input rd_clk,
  input rd_resetn,
  input rd_en,
  output reg [data_width-1:0]rd_data,
  
  output full, 
  output empty);
  
  //memory
  reg [data_width-1:0] mem [0:(1<<addr_width)-1];
  
  //binary pointers
  reg [addr_width:0] wr_ptr_bin;
  reg [addr_width:0] rd_ptr_bin;
  
  //grey code pointers
  reg [addr_width:0] wr_ptr_gray;
  reg [addr_width:0] rd_ptr_gray;
  
  //next pointer
  wire [addr_width:0] wr_ptr_bin_next;
  wire [addr_width:0] rd_ptr_bin_next;
  wire [addr_width:0] wr_ptr_gray_next;
  wire [addr_width:0] rd_ptr_gray_next;
  
  //write pointer logic
  
  assign wr_ptr_bin_next = wr_ptr_bin + (wr_en & ~full);
  assign wr_ptr_gray_next = (wr_ptr_bin_next>>1) ^ wr_ptr_bin_next;
  
  //read pointer logic
  
  assign rd_ptr_bin_next = rd_ptr_bin + (rd_en & ~empty);
  assign rd_ptr_gray_next = (rd_ptr_bin_next>>1) ^ rd_ptr_bin_next;
  
  // write operation
  
  always@(posedge wr_clk or negedge wr_resetn)
    begin
      
      if(!wr_resetn)begin
        wr_ptr_bin<=0;
        wr_ptr_gray<=0;
      end
      
      else
        begin
          if(wr_en && !full)begin
            mem[wr_ptr_bin[addr_width-1:0]]<=wr_data;
            
            wr_ptr_bin<=wr_ptr_bin_next;
            wr_ptr_gray<=wr_ptr_gray_next;
          end
        end
    end
  
  // read operation
  always @(posedge rd_clk or negedge rd_resetn)
    begin
      if(!rd_resetn)
        begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= 0;
        end
        else
        begin
            if(rd_en && !empty)
            begin
              rd_data <= mem[rd_ptr_bin[addr_width-1:0]];

                rd_ptr_bin  <= rd_ptr_bin_next;
                rd_ptr_gray <= rd_ptr_gray_next;
            end
        end
    end

  //read sync
  
  reg[addr_width:0]rd_ptr_gray_sync1;
  reg[addr_width:0]rd_ptr_gray_sync2;
  
  always@(posedge wr_clk or negedge wr_resetn)
    begin
      if(!wr_resetn)
        begin
          rd_ptr_gray_sync1<=0;
          rd_ptr_gray_sync2<=0;
        end
      else 
        begin
        rd_ptr_gray_sync1<=rd_ptr_gray;
        rd_ptr_gray_sync2<=rd_ptr_gray_sync1;
        end
    end
  
  
   //write sync
  
  reg[addr_width:0]wr_ptr_gray_sync1;
  reg[addr_width:0]wr_ptr_gray_sync2;
  
  always@(posedge rd_clk or negedge rd_resetn)
    begin
      if(!rd_resetn)
        begin
          wr_ptr_gray_sync1<=0;
          wr_ptr_gray_sync2<=0;
        end
      else 
        begin
        wr_ptr_gray_sync1<=wr_ptr_gray;
        wr_ptr_gray_sync2<=wr_ptr_gray_sync1;
        end
    end
  
  // empty logic
  
  assign empty = (rd_ptr_gray_next == wr_ptr_gray_sync2);
  
  // full logic
  
  assign full =
        (wr_ptr_gray_next ==
        {
          ~rd_ptr_gray_sync2[addr_width:addr_width-1],
          rd_ptr_gray_sync2[addr_width-2:0]
        });
      
      property p_no_write_when_full;
        @(posedge wr_clk) disable iff(!wr_resetn)
        (full && wr_en) |=> $stable(wr_ptr_bin)
      endproperty
      
      assert property (p_no_write_when_full)
        else $error("Write pointer changed while FIFO full");
        
        
      property p_no_read_when_empty;
       @(posedge rd_clk) disable iff(!rd_resetn)
       (empty && rd_en) |=> $stable(rd_ptr_bin);
      endproperty

      assert property(p_no_read_when_empty)
        else $error("Read pointer changed while FIFO empty");
        
      
endmodule
          
        
