  module secded_decoder_64
(
    input  [63:0] data_i,
    input  [7:0]  ecc_i,

    output [63:0] corrected_data_o,

    output single_error_o,
    output double_error_o
);

wire [7:0] ecc_calc;

assign ecc_calc[0] = ^data_i[7:0];
assign ecc_calc[1] = ^data_i[15:8];
assign ecc_calc[2] = ^data_i[23:16];
assign ecc_calc[3] = ^data_i[31:24];
assign ecc_calc[4] = ^data_i[39:32];
assign ecc_calc[5] = ^data_i[47:40];
assign ecc_calc[6] = ^data_i[55:48];
assign ecc_calc[7] = ^data_i[63:56];

assign corrected_data_o = data_i;

assign single_error_o = (ecc_calc != ecc_i);
assign double_error_o = 1'b0;

endmodule
  
