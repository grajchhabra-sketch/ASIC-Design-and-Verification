module secded_encoder_64
(
    input  [63:0] data_i,
    output [7:0]  ecc_o
);

assign ecc_o[0] = ^data_i[7:0];
assign ecc_o[1] = ^data_i[15:8];
assign ecc_o[2] = ^data_i[23:16];
assign ecc_o[3] = ^data_i[31:24];
assign ecc_o[4] = ^data_i[39:32];
assign ecc_o[5] = ^data_i[47:40];
assign ecc_o[6] = ^data_i[55:48];
assign ecc_o[7] = ^data_i[63:56];

endmodule
