`include "FFT64.v"
`include "autocorrelation.v"
`include "qpsk.v"
module ofdm_top #(
    parameter width = 16
) (
    input                        clk,
    input                        rst_n,
    input                        data_in_en,
    input  signed [width-1:0]    data_in_re,
    input  signed [width-1:0]    data_in_im,
    output                       data_out_en,
    output                       fft_out_en,
    output signed [width-1:0]    fft_out_re,
    output signed [width-1:0]    fft_out_im,
    output        [127:0]        out_bitstream,
    output        [3:0]          peak_point,
    output                       finish // end of compare (find peak point finish)
    
);

// auto to fft
wire                    fft_in_en;
wire signed [width-1:0] fft_in_re;
wire signed [width-1:0] fft_in_im;


autocorrelation #(.width(width)) u1(
    .clk            (clk),
    .rst_n          (rst_n),
    .data_in_en     (data_in_en),
    .data_in_re     (data_in_re),
    .data_in_im     (data_in_im),
    .data_out_en    (fft_in_en),
    .data_out_re    (fft_in_re),
    .data_out_im    (fft_in_im),
    .peak_point     (peak_point),
    .finish         (finish)
);

FFT64 #(.width(width)) u2(
    .clk        (clk),
    .rst_n      (rst_n),
    .di_en      (fft_in_en),
    .di_re      (fft_in_re),
    .di_img     (fft_in_im),
    .do_en      (fft_out_en),
    .do_re      (fft_out_re),
    .do_img     (fft_out_im)
);

qpsk_modulation #(.width(width)) u3(
    .clk            (clk),
    .rst_n          (rst_n),
    .data_in_en     (fft_out_en),
    .data_in_re     (fft_out_re),
    .data_in_im     (fft_out_im),
    .out_valid      (data_out_en),
    .out_bitstream  (out_bitstream)
);

endmodule