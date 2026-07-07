interface axi_if #(parameter ADDR_WIDTH = 32,
                   parameter DATA_WIDTH = 32);

    logic clk;
    logic reset;

    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    logic [DATA_WIDTH-1:0] wdata;
    logic                  wvalid;
    logic                  wready;

    logic                  bvalid;
    logic                  bready;

    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    logic [DATA_WIDTH-1:0] rdata;
    logic                  rvalid;
    logic                  rready;

endinterface
