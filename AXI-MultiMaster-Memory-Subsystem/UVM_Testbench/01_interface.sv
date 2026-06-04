interface axi_if(input bit clk);

logic reset;

logic [31:0] awaddr;
logic awvalid;
logic awready;

logic [31:0] wdata;
logic wvalid;
logic wready;

logic bvalid;
logic bready;

logic [31:0] araddr;
logic arvalid;
logic arready;

logic [31:0] rdata;
logic rvalid;
logic rready;

endinterface
