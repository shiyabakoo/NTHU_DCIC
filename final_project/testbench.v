`timescale 1ns/1ns
`define CYCLE_TIME 10
module QRD_test #(
    parameter WIDTH = 16
);

reg                     clk;
reg                     rst_n;
reg  signed [WIDTH-1:0] data_re;
reg  signed [WIDTH-1:0] data_im;
reg                     data_valid;
reg signed [WIDTH-1:0] y0_re;
reg signed [WIDTH-1:0] y0_im;
reg signed [WIDTH-1:0] y1_re;
reg signed [WIDTH-1:0] y1_im;
wire signed [WIDTH-1:0] x0_re; 
wire signed [WIDTH-1:0] x0_im; 
wire signed [WIDTH-1:0] x1_re; 
wire signed [WIDTH-1:0] x1_im;
wire                    out_valid;



// QRD uut(
//     .clk        (clk),
//     .rst_n      (rst_n),
//     .data_re     (data_re),
//     .data_im     (data_im),
//     .data_valid (data_valid),
//     .q00_re     (q00_re),
//     .q00_im     (q00_im),
//     .q01_re     (q01_re),
//     .q01_im     (q01_im),
//     .q10_re     (q10_re),   
//     .q10_im     (q10_im),   
//     .q11_re     (q11_re),   
//     .q11_im     (q11_im),
//     .r00_re     (r00_re),
//     .r00_im     (r00_im),
//     .r01_re     (r01_re),
//     .r01_im     (r01_im),
//     .r10_re     (r10_re),   
//     .r10_im     (r10_im),   
//     .r11_re     (r11_re),   
//     .r11_im     (r11_im),
//     .out_valid  (out_valid)      
// );

k_best_detector uut (
    .clk        (clk),            
    .rst_n      (rst_n),
    .data_valid (data_valid),
    .data_re    (data_re),
    .data_im    (data_im),
    .y0_re      (y0_re),
    .y0_im      (y0_im),
    .y1_re      (y1_re),
    .y1_im      (y1_im),
    .x0_re      (x0_re),
    .x0_im      (x0_im),
    .x1_re      (x1_re),
    .x1_im      (x1_im),
    .out_valid  (out_valid)
);

task reset; begin
        rst_n = 1'b1;
        data_valid = 1'b0;
        @(negedge clk);
        rst_n =1'b0;

        repeat(3)@(negedge clk);
        rst_n =1'b1;
end
endtask


always begin
    clk = 1'b0;
    forever begin
        #(`CYCLE_TIME/2) clk = ~clk;
    end
end

initial begin
    //==============//
    //  snr = 0db   //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h0219;
    y0_im   = 16'h0093;
    y1_re   = 16'h0157;
    y1_im   = 16'h0531;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    wait (out_valid == 1);
    //==============//
    //  snr = 3db   //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h0136;
    y0_im   = 16'h0292;
    y1_re   = 16'h0138;
    y1_im   = 16'h0109;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    wait (out_valid == 1);
    //==============//
    //  snr = 6db   //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h0168;
    y0_im   = 16'h01AB;
    y1_re   = 16'h0009;
    y1_im   = 16'h033F;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    wait (out_valid == 1);
    //==============//
    //  snr = 9db   //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h01AD;
    y0_im   = 16'h0190;
    y1_re   = 16'h0126;
    y1_im   = 16'h013E;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    wait (out_valid == 1);
    //==============//
    //  snr = 12db  //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h01CF;
    y0_im   = 16'h00EF;
    y1_re   = 16'h01A6;
    y1_im   = 16'h00D2;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    wait (out_valid == 1);
    //==============//
    //  snr = 15db  //
    //==============//
    reset();
    @(negedge clk);
    y0_re   = 16'h0201;
    y0_im   = 16'h00B6;
    y1_re   = 16'h01F9;
    y1_im   = 16'h0185;
    // y0_re   = 16'hfff6;
    // y0_im   = 16'h018e;
    // y1_re   = 16'h0010;
    // y1_im   = 16'h0194;
    data_re = 16'hFF62;
    data_im =  16'hFFC4;
    data_valid = 1'b1;
    @(negedge clk);
    data_re = 16'h00C3;
    data_im = 16'h00B7;
    @(negedge clk);
    data_re = 16'hFF63;
    data_im = 16'h00E7;
    @(negedge clk);
    data_re = 16'hFF39;
    data_im = 16'h00F7;
    @(negedge clk);
    data_re = 0;
    data_im = 0;
    // repeat(50)@(negedge clk);
    // @(negedge clk);
    // y0_re   = 16'hfe17;
    // y0_im   = 16'h00ee;
    // y1_re   = 16'h00b1;
    // y1_im   = 16'hff65;
    // data_re = 16'hffe3;
    // data_im = 16'hff8a;
    // data_valid = 1'b1;
    // @(negedge clk);
    // data_re = 16'hff0a;
    // data_im = 16'hff65;
    // @(negedge clk);
    // data_re = 16'hffa9;
    // data_im = 16'h00a5;
    // @(negedge clk);
    // data_re = 16'hffd9;
    // data_im = 16'hffdc;
    // @(negedge clk);
    // data_re = 0;
    // data_im = 0;
    repeat(100)@(negedge clk);
    $finish;
end

initial begin
    // $sdf_annotate("fft_syn.sdf", uut);
    $fsdbDumpfile("k_best.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
end


endmodule