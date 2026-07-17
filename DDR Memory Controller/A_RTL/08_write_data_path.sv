  module write_data_path
#(
    parameter DATA_WIDTH = 128
)
(
    input clk,
    input reset,

    input                     cmd_wr_i,
    input [DATA_WIDTH-1:0]    cmd_wdata_i,

    output reg [DATA_WIDTH-1:0] ddr_wdata_o,
    output reg [15:0]           ddr_wecc_o,
    output reg                  ddr_wvalid_o
);

wire [7:0] ecc_lo;
wire [7:0] ecc_hi;

secded_encoder_64 u_enc_lo
(
    .data_i(cmd_wdata_i[63:0]),
    .ecc_o(ecc_lo)
);

secded_encoder_64 u_enc_hi
(
    .data_i(cmd_wdata_i[127:64]),
    .ecc_o(ecc_hi)
);

always @(posedge clk) begin

    if(reset) begin

        ddr_wdata_o  <= '0;
        ddr_wecc_o   <= '0;
        ddr_wvalid_o <= 1'b0;

    end
    else begin

        ddr_wvalid_o <= 1'b0;
              if(cmd_wr_i) begin

            ddr_wdata_o  <= cmd_wdata_i;
            ddr_wecc_o   <= {ecc_hi,ecc_lo};
            ddr_wvalid_o <= 1'b1;

        end

    end

end

property p_write_valid;

    @(posedge clk)
    disable iff(reset)

    cmd_wr_i |=> ddr_wvalid_o;

endproperty

assert property(p_write_valid)
else
    $fatal(1,"Write valid not asserted");

property p_write_data;

    @(posedge clk)
    disable iff(reset)

    cmd_wr_i |=> (ddr_wdata_o == $past(cmd_wdata_i));

endproperty

assert property(p_write_data)
else
    $fatal(1,"Write data mismatch");

property p_write_ecc;

    @(posedge clk)
    disable iff(reset)

    cmd_wr_i |=> (ddr_wecc_o == $past({ecc_hi,ecc_lo}));

endproperty

assert property(p_write_ecc)
else
    $fatal(1,"ECC generation failed");

endmodule
  
