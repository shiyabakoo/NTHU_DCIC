`timescale 1ns/1ns
`define CYCLE_TIME 10

module TB;

reg             clk;
reg             rst_n;
reg             in_valid;
reg     [15:0]  in_re;
reg     [15:0]  in_im;
wire            out_valid;
wire            fft_out_en;
wire            finish;
wire    [15:0]  fft_out_re;
wire    [15:0]  fft_out_im;
wire    [3:0]   peak_point;
// wire    [127:0] out_bitstream; //qpsk
wire    [255:0] out_bitstream; //QAM
// wire    [15:0]  cp_remove_signal_re;
// wire    [15:0]  cp_remove_signal_im;


// Module Instances
ofdm_top #(.WIDTH(16)) uut (
    .clk                    (clk),          // i
    .rst_n                  (rst_n),          // i
    .data_in_en             (in_valid),          // i
    .data_in_re             (in_re),          // i
    .data_in_im             (in_im),           // i
    .data_out_en            (out_valid),
    .fft_out_en             (fft_out_en),
    .fft_out_re             (fft_out_re),
    .fft_out_im             (fft_out_im),
    .peak_point             (peak_point),
    .finish                 (finish),
    .out_bitstream          (out_bitstream)
);

//========================
// PARAMETERS & VARIABLES
//========================
parameter CYCLE = `CYCLE_TIME;
parameter PATTERN_COUNT = 1;  // Number of 64-point patterns
parameter POINTS_PER_PATTERN = 80;  // Points per FFT pattern
parameter OFDM_NUM = 10;
reg [15:0]      imem[0:(OFDM_NUM * POINTS_PER_PATTERN * 2 * PATTERN_COUNT) - 1];
reg [255:0]     omem[0:1];
reg [15:0]      omem2[0:127];
reg [6:0]       error_count;
reg [15:0]      golden_out_re;
reg [15:0]      golden_out_im;
//=======================
//    Clock Generate
//=======================
initial clk = 1'b0;
always #(CYCLE/2.0) clk = ~clk;

// Load data from .dat file into imem & omem
initial begin
    // Load input data from "complex_fixed_point_q8_8.dat" file into imem array
    //  $readmemb("golden.dat", omem);
    //  $readmemh("complex_after_fft_pattern.dat", omem2);
    // $readmemh("noise_15db_complex_pattern.dat", imem);
    // $readmemb("noise_golden.dat", omem);
    // $readmemh("noise_15db_complex_after_fft_pattern.dat", omem2);
    $readmemh("noise_15db_QAM_complex_pattern.dat", imem);
    $readmemb("noise_QAM_golden.dat", omem);
    $readmemh("noise_15db_QAM_complex_after_fft_pattern.dat", omem2);
    // $readmemh("QAM_complex_pattern.dat", imem);
    // $readmemb("QAM_golden.dat", omem);
    // $readmemh("QAM_complex_after_fft_pattern.dat", omem2);
end

// Input Control Initialize
initial begin
    wait (rst_n == 0);
    in_valid = 0;
end

//=======================
//         TASK
//=======================
task reset; begin
   rst_n <= 1'b1;
   repeat(1) @(negedge clk);

   rst_n <= 1'b0;
   repeat(3) @(negedge clk);
   
   rst_n <= 1'b1;
end endtask

// Generate input wave for each pattern
task GenerateInputWave(input integer pattern_idx);
    integer n;
    integer k;
    begin
        for(k = 0; k < OFDM_NUM; k = k + 1) begin
            in_valid <= 1;
            for (n = 0; n < POINTS_PER_PATTERN; n = n + 1) begin
                in_re <= imem[(k * POINTS_PER_PATTERN * 2) + (2 * n)];
                in_im <= imem[(k * POINTS_PER_PATTERN * 2) + (2 * n) + 1];
                @(negedge clk);
            end
        end
        in_valid <= 0;
        in_re <= 'bx;
        in_im <= 'bx;
        @(negedge clk);
    end
endtask

task BER;
    integer j;
    begin
        error_count = 0;
        @(posedge out_valid);
        for (j = 0; j < 128; j = j + 1) begin
            if (out_bitstream[127-j] != omem[0][j])
                error_count = error_count + 1;
            $display("error bit =  %0d ", j);
        end
        $display("error count =  %0d ", error_count);
    end

endtask

// Check output and compare with golden data
task CheckOutput(input integer pattern_idx);
    integer k;
    reg signed [15:0] error_re, error_im;
    real error_re_float, error_im_float;
    real max_error, current_error;
    integer max_error_index;

    begin
        max_error = 0;
        max_error_index = -1;

        for (k = 0; k < 64; k = k + 1) begin
            golden_out_re <= omem2[(pattern_idx * 63 * 2) + (2 * k)];
            golden_out_im <= omem2[(pattern_idx * 63 * 2) + (2 * k) + 1];

            @(posedge clk);

            // Calculate signed error
            error_re = $signed(fft_out_re) - $signed(golden_out_re);
            error_im = $signed(fft_out_im) - $signed(golden_out_im);

            // Convert error to floating-point for Q8.8
            error_re_float = error_re / 256.0;
            error_im_float = error_im / 256.0;

            // Calculate the total error magnitude for real and imaginary parts without `abs`
            current_error = (error_re_float < 0 ? -error_re_float : error_re_float) + 
                            (error_im_float < 0 ? -error_im_float : error_im_float);

            // Update maximum error and index if the current error is greater
            if (current_error > max_error) begin
                max_error = current_error;
                max_error_index = k;
            end

            if (fft_out_en) begin
                $display("Point: %2d | Output: Real = %h, Imag = %h | Golden: Real = %h, Imag = %h | Error: Real = %8.3f, Imag = %8.3f", 
                         k, fft_out_re, fft_out_im, golden_out_re, golden_out_im, error_re_float, error_im_float);  
            end 
        end

        // Reset golden output values after comparison
        golden_out_re <= 0;
        golden_out_im <= 0;
    end
endtask
//====================
//       MAIN
//====================
integer i;
initial begin
    for(i = 0; i < PATTERN_COUNT; i = i + 1) begin
        reset();
        // Wait for reset to finish
        @(posedge rst_n);

        // Generate input wave for the current pattern
        GenerateInputWave(i);

    end
    repeat(10) @(negedge clk);
    $finish;
end

initial begin
     @(posedge fft_out_en)
    for(i = 0; i < 1; i = i + 1) begin
        CheckOutput(i);
    end
end
// compare error bit
integer j;
always @(*) begin
    @(posedge out_valid);
    error_count = 0;
    for (j = 0; j < 256; j = j + 1) begin
        if (out_bitstream[j] != omem[0][255 - j]) begin
            error_count = error_count + 1;
            $display("error bit at = %d", j);
        end
    end
    $display("bit error count =  %0d ", error_count);
    $display("BER = %f", error_count / 256);
end
//print bitstream
integer k;
always @(*) begin
    @(posedge out_valid);
    $write("QPSK bitstream :   ");
    for (j = 0; j < 256; j = j + 1) begin
        $write("%b", out_bitstream[j]);
    end
    $display(" ");
    $write("godlen bitstream : ");
    for (k = 0; k < 256; k = k + 1) begin
        $write("%b", omem[0][255 - k]);
    end
    $display(" ");
end
// peak point
integer a;
initial begin
    for (a = 0; a < 3; a = a + 1) begin
        @(posedge finish);
        if (a == 0) 
            $display("first peak point  at %3d", peak_point + a * 80);
        if (a == 1)
            $display("second peak point at %3d", peak_point + a * 80);
        if (a == 2)
            $display("third peak point  at %3d", peak_point + a * 80);
    end
end

initial begin
    // $sdf_annotate("fft_syn.sdf", uut);
    $fsdbDumpfile("top.fsdb");
    $fsdbDumpvars(0,"+mda");
    $fsdbDumpvars();
end

endmodule
