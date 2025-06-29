module twiddle (
    input [4:0] addr,
    output signed [15:0] tw_re,
    output signed [15:0] tw_img
);
wire  [15:0] wn_re [31:0];
wire  [15:0] wn_img [31:0];

assign tw_re = $signed(wn_re[addr]);
assign tw_img = $signed(wn_img[addr]);

assign wn_re[ 0] = 16'h0100;     assign wn_img[ 0] = 16'h0000;   //  0  1.000 -0.000
assign wn_re[ 1] = 16'h00FF;     assign wn_img[ 1] = 16'hFFE7;   //  1  0.995 -0.098
assign wn_re[ 2] = 16'h00FB;     assign wn_img[ 2] = 16'hFFCE;   //  2  0.981 -0.195
assign wn_re[ 3] = 16'h00F5;     assign wn_img[ 3] = 16'hFFB6;   //  3  0.957 -0.290
assign wn_re[ 4] = 16'h00ED;     assign wn_img[ 4] = 16'hFF9E;   //  4  0.924 -0.383
assign wn_re[ 5] = 16'h00E2;     assign wn_img[ 5] = 16'hFF87;   //  5  0.882 -0.471
assign wn_re[ 6] = 16'h00D5;     assign wn_img[ 6] = 16'hFF72;   //  6  0.831 -0.556
assign wn_re[ 7] = 16'h00C6;     assign wn_img[ 7] = 16'hFF5E;   //  7  0.773 -0.634
assign wn_re[ 8] = 16'h00B5;     assign wn_img[ 8] = 16'hFF4B;   //  8  0.707 -0.707
assign wn_re[ 9] = 16'h00A2;     assign wn_img[ 9] = 16'hFF3A;   //  9  0.634 -0.773
assign wn_re[10] = 16'h008E;     assign wn_img[10] = 16'hFF2B;   // 10  0.556 -0.831
assign wn_re[11] = 16'h0079;     assign wn_img[11] = 16'hFF1E;   // 11  0.471 -0.882
assign wn_re[12] = 16'h0062;     assign wn_img[12] = 16'hFF13;   // 12  0.383 -0.924
assign wn_re[13] = 16'h004A;     assign wn_img[13] = 16'hFF0B;   // 13  0.290 -0.957
assign wn_re[14] = 16'h0032;     assign wn_img[14] = 16'hFF05;   // 14  0.195 -0.981
assign wn_re[15] = 16'h0019;     assign wn_img[15] = 16'hFF01;   // 15  0.098 -0.995
assign wn_re[16] = 16'h0000;     assign wn_img[16] = 16'hFF00;   // 16  0.000 -1.000
assign wn_re[17] = 16'hFFE7;     assign wn_img[17] = 16'hFF01;   // 17  -0.098 -0.995
assign wn_re[18] = 16'hFFCE;     assign wn_img[18] = 16'hFF05;   // 18  -0.195 -0.981
assign wn_re[19] = 16'hFFB6;     assign wn_img[19] = 16'hFF0B;   // 19  -0.290 -0.957
assign wn_re[20] = 16'hFF9E;     assign wn_img[20] = 16'hFF13;   // 20  -0.383 -0.924
assign wn_re[21] = 16'hFF87;     assign wn_img[21] = 16'hFF1E;   // 21  -0.471 -0.882
assign wn_re[22] = 16'hFF72;     assign wn_img[22] = 16'hFF2B;   // 22  -0.556 -0.831
assign wn_re[23] = 16'hFF5E;     assign wn_img[23] = 16'hFF3A;   // 23  -0.634 -0.773
assign wn_re[24] = 16'hFF4B;     assign wn_img[24] = 16'hFF4B;   // 24  -0.707 -0.707
assign wn_re[25] = 16'hFF3A;     assign wn_img[25] = 16'hFF5E;   // 25  -0.773 -0.634
assign wn_re[26] = 16'hFF2B;     assign wn_img[26] = 16'hFF72;   // 26  -0.831 -0.556
assign wn_re[27] = 16'hFF1E;     assign wn_img[27] = 16'hFF87;   // 27  -0.882 -0.471
assign wn_re[28] = 16'hFF13;     assign wn_img[28] = 16'hFF9E;   // 28  -0.924 -0.383
assign wn_re[29] = 16'hFF0B;     assign wn_img[29] = 16'hFFB6;   // 29  -0.957 -0.290
assign wn_re[30] = 16'hFF05;     assign wn_img[30] = 16'hFFCE;   // 30  -0.981 -0.195
assign wn_re[31] = 16'hFF01;     assign wn_img[31] = 16'hFFE7;   // 31  -0.995 -0.098


endmodule

