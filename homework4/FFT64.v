`include "sdfunit.v"
module FFT64 #(
    parameter width = 16
) (
    input                           clk,
    input                           rst_n,
    input                           di_en,
    input       signed  [width-1:0] di_re,
    input       signed  [width-1:0] di_img,
    output                          do_en,
    output  reg signed  [width-1:0] do_re,
    output  reg signed  [width-1:0] do_img
);
reg             [width-1:0]   fft_re [63:0];
reg             [width-1:0]   fft_img [63:0];
reg             [width-1:0]   temp_re [63:0];
reg             [width-1:0]   temp_img [63:0];
reg             [5:0]         i;
reg             [5:0]         j;
reg                           wirte_en;
wire                          sdf1_out_en;
wire  signed    [width-1:0]   sdf1_out_re;
wire  signed    [width-1:0]   sdf1_out_img;
wire                          sdf2_out_en;
wire  signed    [width-1:0]   sdf2_out_re;
wire  signed    [width-1:0]   sdf2_out_img;
wire                          sdf3_out_en;
wire  signed    [width-1:0]   sdf3_out_re;
wire  signed    [width-1:0]   sdf3_out_img;
wire                          sdf4_out_en;
wire  signed    [width-1:0]   sdf4_out_re;
wire  signed    [width-1:0]   sdf4_out_img;
wire                          sdf5_out_en;
wire  signed    [width-1:0]   sdf5_out_re;
wire  signed    [width-1:0]   sdf5_out_img;
wire                          sdf6_out_en;
wire  signed    [width-1:0]   sdf6_out_re;
wire  signed    [width-1:0]   sdf6_out_img;
wire            [5:0]         order[63:0];

sdfunit #(.N(64), .M(1), .width(width)) u1(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (di_en),
    .di_re          (di_re),
    .di_img         (di_img),
    .sdf_out_en     (sdf1_out_en),
    .sdf_out_re     (sdf1_out_re),
    .sdf_out_img    (sdf1_out_img)
);

sdfunit #(.N(32), .M(2), .width(width)) u2(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (sdf1_out_en),
    .di_re          (sdf1_out_re),
    .di_img         (sdf1_out_img),
    .sdf_out_en     (sdf2_out_en),
    .sdf_out_re     (sdf2_out_re),
    .sdf_out_img    (sdf2_out_img)
);

sdfunit #(.N(16), .M(4), .width(width))u3(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (sdf2_out_en),
    .di_re          (sdf2_out_re),
    .di_img         (sdf2_out_img),
    .sdf_out_en     (sdf3_out_en),
    .sdf_out_re     (sdf3_out_re),
    .sdf_out_img    (sdf3_out_img)
);

sdfunit #(.N(8), .M(8), .width(width)) u4(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (sdf3_out_en),
    .di_re          (sdf3_out_re),
    .di_img         (sdf3_out_img),
    .sdf_out_en     (sdf4_out_en),
    .sdf_out_re     (sdf4_out_re),
    .sdf_out_img    (sdf4_out_img)
);

sdfunit #(.N(4), .M(16), .width(width)) u5(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (sdf4_out_en),
    .di_re          (sdf4_out_re),
    .di_img         (sdf4_out_img),
    .sdf_out_en     (sdf5_out_en),
    .sdf_out_re     (sdf5_out_re),
    .sdf_out_img    (sdf5_out_img)
);

sdfunit #(.N(2), .M(32), .width(width)) u6(
    .clk            (clk),
    .rst_n          (rst_n),
    .di_en          (sdf5_out_en),
    .di_re          (sdf5_out_re),
    .di_img         (sdf5_out_img),
    .sdf_out_en     (sdf6_out_en),
    .sdf_out_re     (sdf6_out_re),
    .sdf_out_img    (sdf6_out_img)
);

// unscramble
assign order[0] = 0;    assign order[1] = 32;   assign order[2] = 16;   assign order[3] = 48;
assign order[4] = 8;    assign order[5] = 40;   assign order[6] = 24;   assign order[7] = 56;
assign order[8] = 4;    assign order[9] = 36;   assign order[10] = 20;  assign order[11] = 52;
assign order[12] = 12;  assign order[13] = 44;  assign order[14] = 28;  assign order[15] = 60;
assign order[16] = 2;   assign order[17] = 34;  assign order[18] = 18;  assign order[19] = 50;
assign order[20] = 10;  assign order[21] = 42;  assign order[22] = 26;  assign order[23] = 58;
assign order[24] = 6;   assign order[25] = 38;  assign order[26] = 22;  assign order[27] = 54;
assign order[28] = 14;  assign order[29] = 46;  assign order[30] = 30;  assign order[31] = 62;
assign order[32] = 1;   assign order[33] = 33;  assign order[34] = 17;  assign order[35] = 49;
assign order[36] = 9;   assign order[37] = 41;  assign order[38] = 25;  assign order[39] = 57;
assign order[40] = 5;   assign order[41] = 37;  assign order[42] = 21;  assign order[43] = 53;
assign order[44] = 13;  assign order[45] = 45;  assign order[46] = 29;  assign order[47] = 61;
assign order[48] = 3;   assign order[49] = 35;  assign order[50] = 19;  assign order[51] = 51;
assign order[52] = 11;  assign order[53] = 43;  assign order[54] = 27;  assign order[55] = 59;
assign order[56] = 7;   assign order[57] = 39;  assign order[58] = 23;  assign order[59] = 55;
assign order[60] = 15;  assign order[61] = 47;  assign order[62] = 31;  assign order[63] = 63;

assign do_en = (j != 0)? 1'b1 : 1'b0;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        i <= 0;
    else if(sdf6_out_en) begin
        fft_re[order[i]] <= sdf6_out_re;
        fft_img[order[i]] <= sdf6_out_img;
        i <= i + 1;
    end
    else begin
        fft_re[order[i]] <= {width{1'b0}};
        fft_img[order[i]] <= {width{1'b0}};
        i <= i;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        j <= 0;
    else
        j <= (i == 63)? j + 1 : j;
end

always @(posedge clk) begin
    wirte_en <= (i == 63)? 1'b1 : 1'b0;
end

integer k ;
always @(*) begin
    if (wirte_en) begin
        for(k = 0; k < 64; k = k+1) begin
            temp_re[k] = fft_re[k];
            temp_img[k] = fft_img[k];
        end
    end
    else begin
        for(k = 0; k < 64; k = k+1) begin
            temp_re[k] = temp_re[k];
            temp_img[k] = temp_img[k];
        end        
    end

end

always @(*) begin
    if (do_en == 1 ) begin
        do_re = temp_re[i];
        do_img = temp_img[i];
    end
    else begin
        do_re = {width{1'b0}};
        do_img = {width{1'b0}};
    end
end
endmodule

