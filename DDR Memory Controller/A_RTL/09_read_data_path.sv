  module read_data_path
#(
    parameter DATA_WIDTH = 128
)
(
    input clk,
    input reset,

    input                    read_valid_i,

    input [DATA_WIDTH-1:0]   ddr_rdata_i,
    input [15:0]             ddr_recc_i,

    output reg [DATA_WIDTH-1:0] cpu_rdata_o,
    output reg                  cpu_rvalid_o,

    output reg single_error_o,
    output reg double_error_o
);

wire [63:0] corrected_lo;
wire [63:0] corrected_hi;

wire sbe_lo;
wire dbe_lo;
wire sbe_hi;
wire dbe_hi;

secded_decoder_64 u_dec_lo
(
    .data_i(ddr_rdata_i[63:0]),
    .ecc_i(ddr_recc_i[7:0]),

    .corrected_data_o(corrected_lo),

    .single_error_o(sbe_lo),
    .double_error_o(dbe_lo)
);

secded_decoder_64 u_dec_hi
(
    .data_i(ddr_rdata_i[127:64]),
    .ecc_i(ddr_recc_i[15:8]),

    .corrected_data_o(corrected_hi),

    .single_error_o(sbe_hi),
    .double_error_o(dbe_hi)
);

always @(posedge clk) begin

    if(reset) begin

        cpu_rdata_o <= '0;
        cpu_rvalid_o <= 1'b0;

        single_error_o <= 1'b0;
        double_error_o <= 1'b0;

    end
    else begin

        cpu_rvalid_o <= 1'b0;

        single_error_o <= 1'b0;
        double_error_o <= 1'b0;
              if(read_valid_i) begin

            cpu_rdata_o  <= {corrected_hi, corrected_lo};
            cpu_rvalid_o <= 1'b1;

            single_error_o <= sbe_lo | sbe_hi;
            double_error_o <= dbe_lo | dbe_hi;

        end

    end

end

property p_read_valid;

    @(posedge clk)
    disable iff(reset)

    read_valid_i |=> cpu_rvalid_o;

endproperty

assert property(p_read_valid)
else
    $fatal(1,"Read valid not asserted");

property p_single_double_error;

    @(posedge clk)
    disable iff(reset)

    !(single_error_o && double_error_o);

endproperty

assert property(p_single_double_error)
else
    $fatal(1,"Single and Double error asserted together");

property p_read_data_valid;

    @(posedge clk)
    disable iff(reset)

    cpu_rvalid_o |-> !$isunknown(cpu_rdata_o);

endproperty

assert property(p_read_data_valid)
else
    $fatal(1,"CPU read data contains unknown values");

endmodule
