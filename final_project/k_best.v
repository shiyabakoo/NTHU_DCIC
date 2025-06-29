`include "QRD.v"
`include "norm.v"
`include "complex_mul.v"
module k_best_detector #(
    parameter WIDTH = 16
) (
    input                          clk,
    input                          rst_n,
    input                          data_valid,
    input       signed [WIDTH-1:0] data_re,
    input       signed [WIDTH-1:0] data_im,
    input       signed [WIDTH-1:0] y0_re,
    input       signed [WIDTH-1:0] y0_im,
    input       signed [WIDTH-1:0] y1_re,
    input       signed [WIDTH-1:0] y1_im,                                                
    output  reg signed [WIDTH-1:0] x0_re,
    output  reg signed [WIDTH-1:0] x0_im,
    output  reg signed [WIDTH-1:0] x1_re,
    output  reg signed [WIDTH-1:0] x1_im,
    output  reg                    out_valid
);

// martix Q_H and R
wire    signed  [WIDTH-1:0]     q_H_00_re;
wire    signed  [WIDTH-1:0]     q_H_00_im;
wire    signed  [WIDTH-1:0]     q_H_01_re;
wire    signed  [WIDTH-1:0]     q_H_01_im;
wire    signed  [WIDTH-1:0]     q_H_10_re;
wire    signed  [WIDTH-1:0]     q_H_10_im;
wire    signed  [WIDTH-1:0]     q_H_11_re;
wire    signed  [WIDTH-1:0]     q_H_11_im;
wire    signed  [WIDTH-1:0]     r00_re;
wire    signed  [WIDTH-1:0]     r00_im;
wire    signed  [WIDTH-1:0]     r01_re;
wire    signed  [WIDTH-1:0]     r01_im;
wire    signed  [WIDTH-1:0]     r10_re;
wire    signed  [WIDTH-1:0]     r10_im;
wire    signed  [WIDTH-1:0]     r11_re;
wire    signed  [WIDTH-1:0]     r11_im;
wire                            qr_valid;
// reg     signed  [WIDTH-1:0]     complex_mul_in1_re [0:3];
// reg     signed  [WIDTH-1:0]     complex_mul_in1_im [0:3];
// reg     signed  [WIDTH-1:0]     complex_mul_in2_re [0:3];
// reg     signed  [WIDTH-1:0]     complex_mul_in2_im [0:3];
// wire    signed  [WIDTH-1:0]     complex_mul_out_re [0:3];
// wire    signed  [WIDTH-1:0]     complex_mul_out_im [0:3];
reg     signed  [WIDTH-1:0]     complex_mul_in1_re;
reg     signed  [WIDTH-1:0]     complex_mul_in1_im;
reg     signed  [WIDTH-1:0]     complex_mul_in2_re;
reg     signed  [WIDTH-1:0]     complex_mul_in2_im;
wire    signed  [WIDTH-1:0]     complex_mul_out_re;
wire    signed  [WIDTH-1:0]     complex_mul_out_im;
reg     signed  [WIDTH-1:0]     complex_mul_in1_re_1;
reg     signed  [WIDTH-1:0]     complex_mul_in1_im_1;
reg     signed  [WIDTH-1:0]     complex_mul_in2_re_1;
reg     signed  [WIDTH-1:0]     complex_mul_in2_im_1;
wire    signed  [WIDTH-1:0]     complex_mul_out_re_1;
wire    signed  [WIDTH-1:0]     complex_mul_out_im_1;
reg     signed  [WIDTH-1:0]     norm_re;
reg     signed  [WIDTH-1:0]     norm_im;
wire    signed  [WIDTH-1:0]     norm_out;

QRD u1(
    .clk           (clk),
    .rst_n         (rst_n),
    .data_re       (data_re),
    .data_im       (data_im),
    .data_valid    (data_valid),
    .q_H_00_re     (q_H_00_re),
    .q_H_00_im     (q_H_00_im),
    .q_H_01_re     (q_H_01_re),
    .q_H_01_im     (q_H_01_im),
    .q_H_10_re     (q_H_10_re),   
    .q_H_10_im     (q_H_10_im),   
    .q_H_11_re     (q_H_11_re),   
    .q_H_11_im     (q_H_11_im),
    .r00_re        (r00_re),
    .r00_im        (r00_im),
    .r01_re        (r01_re),
    .r01_im        (r01_im),
    .r10_re        (r10_re),   
    .r10_im        (r10_im),   
    .r11_re        (r11_re),   
    .r11_im        (r11_im),
    .out_valid     (qr_valid)      
);

complex_mul u2(
    .clk    (clk),
    .a_re   (complex_mul_in1_re),
    .a_im   (complex_mul_in1_im),
    .b_re   (complex_mul_in2_re),
    .b_im   (complex_mul_in2_im),
    .c_re   (complex_mul_out_re),
    .c_im   (complex_mul_out_im)
);
complex_mul u4(
    .clk    (clk),
    .a_re   (complex_mul_in1_re_1),
    .a_im   (complex_mul_in1_im_1),
    .b_re   (complex_mul_in2_re_1),
    .b_im   (complex_mul_in2_im_1),
    .c_re   (complex_mul_out_re_1),
    .c_im   (complex_mul_out_im_1)
);
norm u3(
    .clk   (clk),
    .in_re (norm_re),
    .in_im (norm_im),
    .out   (norm_out)
);
// counter
reg [6:0] counter;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end
    else begin
        counter <= (qr_valid)? counter + 1 : counter;
    end
end


reg [3:0]  c_state;
reg [3:0]  n_state;
parameter IDLE = 4'b0000,
          S1   = 4'b0001, // calculate Q_H * y
          S2   = 4'b0010, // calculate PED level step 1
          S3   = 4'b0011, // calculate PED level step 2 
          S4   = 4'b0100, // prepare for bubble sort
          S5   = 4'b0101, // start bubble sort
          S6   = 4'b0110, // start calculate level 2 PED
          S7   = 4'b0111,
          S8   = 4'b1000, // prepare for level2 bubble sort
          S9   = 4'b1001, // start bubble sort(level 2)
          S10  = 4'b1010; // final compare

reg signed [WIDTH-1:0] y_0_re;
reg signed [WIDTH-1:0] y_0_im;
reg signed [WIDTH-1:0] y_1_re;
reg signed [WIDTH-1:0] y_1_im;
reg signed [WIDTH-1:0] y_hat_0_re;
reg signed [WIDTH-1:0] y_hat_0_im;
reg signed [WIDTH-1:0] y_hat_1_re;
reg signed [WIDTH-1:0] y_hat_1_im;
wire signed [WIDTH-1:0] symbol_0_re;
wire signed [WIDTH-1:0] symbol_0_im;
wire signed [WIDTH-1:0] symbol_1_re;
wire signed [WIDTH-1:0] symbol_1_im;
wire signed [WIDTH-1:0] symbol_2_re;
wire signed [WIDTH-1:0] symbol_2_im;
wire signed [WIDTH-1:0] symbol_3_re;
wire signed [WIDTH-1:0] symbol_3_im;
reg signed  [WIDTH-1:0] PED1_temp_re [0:3];
reg signed  [WIDTH-1:0] PED1_temp_im [0:3];
//for bubble sort
reg signed [WIDTH-1:0] candidate_1_re [0:3];
reg signed [WIDTH-1:0] candidate_1_im [0:3];
reg signed [WIDTH-1:0] candidate_2_re [0:7];
reg signed [WIDTH-1:0] candidate_2_im [0:7];
reg signed [WIDTH-1:0] sort_PED [0:3];
reg signed  [WIDTH-1:0] r01_x1_re [0:1];
reg signed  [WIDTH-1:0] r01_x1_im [0:1];
reg signed  [WIDTH-1:0] PED2_temp_re[0:7];
reg signed  [WIDTH-1:0] PED2_temp_im[0:7];
reg signed [WIDTH-1:0] sort_2_PED [0:7];


assign  symbol_0_re =  256;
assign  symbol_0_im =  256;
assign  symbol_1_re =  256;
assign  symbol_1_im = -256;
assign  symbol_2_re = -256;
assign  symbol_2_im = -256;
assign  symbol_3_re = -256;
assign  symbol_3_im =  256;

//
//current state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        c_state <= IDLE;
    end
    else begin
        c_state <= n_state;
    end
end

// next state
always @(*) begin
    case (c_state)
        IDLE: if (qr_valid)
                n_state = S1;
            else
                n_state = IDLE;
        S1  : if (counter == 5)
                n_state = S2;
              else
                n_state = S1;
        S2  : if (counter == 10)
                n_state = S3;
              else
                n_state = S2;
        S3  : if (counter == 17)
                n_state = S4;
              else
                n_state = S3;
        S4  : if (counter == 18)
                n_state = S5;
              else
                n_state = S4;
        S5  : if (counter == 24)
                n_state = S6;
              else
                n_state = S5;
        S6  : if (counter == 31)
                n_state = S7;
              else
                n_state = S6;
        S7  : if (counter == 40)
                n_state = S8;
              else
                n_state = S7;
        S8  :   n_state = S9;
        S9  : if (counter == 47)
                n_state = S10;
              else
                n_state = S9;
        S10 : n_state = IDLE;
        default: n_state = IDLE;
    endcase
end

// calculate matrix y_hat

always @(*) begin
    if (c_state == S1 && counter == 1 ) begin
        complex_mul_in1_re = q_H_00_re;
        complex_mul_in1_im = q_H_00_im;
        complex_mul_in2_re = y0_re;
        complex_mul_in2_im = y0_im;
    end
    else if (c_state == S1 && counter == 2) begin
        complex_mul_in1_re = q_H_01_re;
        complex_mul_in1_im = q_H_01_im;
        complex_mul_in2_re = y1_re;
        complex_mul_in2_im = y1_im;
    end
    else if (c_state == S1 && counter == 3) begin
        complex_mul_in1_re = q_H_10_re;
        complex_mul_in1_im = q_H_10_im;
        complex_mul_in2_re = y0_re;
        complex_mul_in2_im = y0_im;
    end
    else if (c_state == S1 && counter == 4) begin
        complex_mul_in1_re = q_H_11_re;
        complex_mul_in1_im = q_H_11_im;
        complex_mul_in2_re = y1_re;
        complex_mul_in2_im = y1_im;
    end
    else if (c_state == S2 && counter == 6) begin
        complex_mul_in1_re  = r11_re;
        complex_mul_in1_im  = r11_im;
        complex_mul_in2_re  = symbol_0_re;
        complex_mul_in2_im  = symbol_0_im; 
    end
    else if (c_state == S2 && counter == 7) begin
        complex_mul_in1_re  = r11_re;
        complex_mul_in1_im  = r11_im;
        complex_mul_in2_re  = symbol_1_re;
        complex_mul_in2_im  = symbol_1_im; 
    end
    else if (c_state == S2 && counter == 8) begin
        complex_mul_in1_re  = r11_re;
        complex_mul_in1_im  = r11_im;
        complex_mul_in2_re  = symbol_2_re;
        complex_mul_in2_im  = symbol_2_im; 
    end
    else if (c_state == S2 && counter == 9) begin
        complex_mul_in1_re  = r11_re;
        complex_mul_in1_im  = r11_im;
        complex_mul_in2_re  = symbol_3_re;
        complex_mul_in2_im  = symbol_3_im; 
    end
    // level 2 calculate
    else if (c_state == S6 && counter == 25) begin
        complex_mul_in1_re = r01_re;
        complex_mul_in1_im = r01_im;
        complex_mul_in2_re = candidate_1_re[0];
        complex_mul_in2_im = candidate_1_im[0];
    end
    else if (c_state == S6 && counter == 26) begin
        complex_mul_in1_re = r01_re;
        complex_mul_in1_im = r01_im;
        complex_mul_in2_re = candidate_1_re[1];
        complex_mul_in2_im = candidate_1_im[1];
    end
    else if (c_state == S6 && counter == 27) begin
        complex_mul_in1_re = r00_re;
        complex_mul_in1_im = 0;
        complex_mul_in2_re = symbol_0_re;
        complex_mul_in2_im = symbol_0_im;
    end
    else if (c_state == S6 && counter == 28) begin
        complex_mul_in1_re = r00_re;
        complex_mul_in1_im = 0;
        complex_mul_in2_re = symbol_1_re;
        complex_mul_in2_im = symbol_1_im;
    end
    else if (c_state == S6 && counter == 29) begin
        complex_mul_in1_re = r00_re;
        complex_mul_in1_im = 0;
        complex_mul_in2_re = symbol_2_re;
        complex_mul_in2_im = symbol_2_im;
    end
    else if (c_state == S6 && counter == 30) begin
        complex_mul_in1_re = r00_re;
        complex_mul_in1_im = 0;
        complex_mul_in2_re = symbol_3_re;
        complex_mul_in2_im = symbol_3_im;
    end
    else begin
        complex_mul_in1_re = 0;
        complex_mul_in1_im = 0;
        complex_mul_in2_re = 0;
        complex_mul_in2_im = 0;
    end
end


reg signed [WIDTH-1:0] temp_re;
reg signed [WIDTH-1:0] temp_im;
always @(posedge clk) begin
    if (c_state == S1 && (counter == 2 || counter == 4)  ) begin
        temp_re <= complex_mul_out_re;
        temp_im <= complex_mul_out_im;
    end
    else begin
        temp_re <= temp_re;
        temp_im <= temp_im;
    end
end

always@(posedge clk) begin
    if (c_state == S1 && counter == 3) begin
        y_hat_0_re = complex_mul_out_re + temp_re;
        y_hat_0_im = complex_mul_out_im + temp_im;
    end
    if (c_state == S1 && counter == 5) begin
        y_hat_1_re = complex_mul_out_re + temp_re;
        y_hat_1_im = complex_mul_out_im + temp_im;
    end
    else begin
        y_hat_0_re = y_hat_0_re;
        y_hat_0_im = y_hat_0_im;
        y_hat_1_re = y_hat_1_re;
        y_hat_1_im = y_hat_1_im;
    end
end

//=========================================================================
//calculate PED step1
reg [WIDTH-1:0] PED [0:7];
// reg [WIDTH-1:0] PED1_temp_re [0:7];
// reg [WIDTH-1:0] PED1_temp_im [0:7];

always@(posedge clk) begin
    if (c_state == S2 && counter == 7) begin
        PED1_temp_re[0] <= y_hat_1_re - complex_mul_out_re;
        PED1_temp_im[0] <= y_hat_1_im - complex_mul_out_im;  
    end
    else begin
        PED1_temp_re[0] <= PED1_temp_re[0];
        PED1_temp_im[0] <= PED1_temp_im[0]; 
    end
end
always@(posedge clk) begin
    if (c_state == S2 && counter == 8) begin
        PED1_temp_re[1] <= y_hat_1_re - complex_mul_out_re;
        PED1_temp_im[1] <= y_hat_1_im - complex_mul_out_im;  
    end
    else begin
        PED1_temp_re[1] <= PED1_temp_re[1];
        PED1_temp_im[1] <= PED1_temp_im[1]; 
    end
end
always@(posedge clk) begin
    if (c_state == S2 && counter == 9) begin
        PED1_temp_re[2] <= y_hat_1_re - complex_mul_out_re;
        PED1_temp_im[2] <= y_hat_1_im - complex_mul_out_im;  
    end
    else begin
        PED1_temp_re[2] <= PED1_temp_re[2];
        PED1_temp_im[2] <= PED1_temp_im[2]; 
    end
end
always@(posedge clk) begin
    if (c_state == S2 && counter == 10) begin
        PED1_temp_re[3] <= y_hat_1_re - complex_mul_out_re;
        PED1_temp_im[3] <= y_hat_1_im - complex_mul_out_im;  
    end
    else begin
        PED1_temp_re[3] <= PED1_temp_re[3];
        PED1_temp_im[3] <= PED1_temp_im[3]; 
    end
end

//=========================================================================
//calculate PED step2
always @(*) begin
    if (c_state == S3 && counter == 11) begin
        norm_re = PED1_temp_re[0];
        norm_im = PED1_temp_im[0]; 
    end 
    else if (c_state == S3 && counter ==12) begin
        norm_re = PED1_temp_re[1];
        norm_im = PED1_temp_im[1];
    end
    else if (c_state == S3 && counter ==13) begin
        norm_re = PED1_temp_re[2];
        norm_im = PED1_temp_im[2];
    end
    else if (c_state == S3 && counter ==14) begin
        norm_re = PED1_temp_re[3];
        norm_im = PED1_temp_im[3];
    end
    else if (c_state == S7 && counter == 32) begin
        norm_re = PED2_temp_re[0];
        norm_im = PED2_temp_im[0]; 
    end 
    else if (c_state == S7 && counter ==33) begin
        norm_re = PED2_temp_re[1];
        norm_im = PED2_temp_im[1];
    end
    else if (c_state == S7 && counter ==34) begin
        norm_re = PED2_temp_re[2];
        norm_im = PED2_temp_im[2];
    end
    else if (c_state == S7 && counter ==35) begin
        norm_re = PED2_temp_re[3];
        norm_im = PED2_temp_im[3];
    end
    else if (c_state == S7 && counter ==36) begin
        norm_re = PED2_temp_re[4];
        norm_im = PED2_temp_im[4];
    end
    else if (c_state == S7 && counter ==37) begin
        norm_re = PED2_temp_re[5];
        norm_im = PED2_temp_im[5];
    end
    else if (c_state == S7 && counter ==38) begin
        norm_re = PED2_temp_re[6];
        norm_im = PED2_temp_im[6];
    end
    else if (c_state == S7 && counter ==39) begin
        norm_re = PED2_temp_re[7];
        norm_im = PED2_temp_im[7];
    end
    else begin
        norm_re = 0;
        norm_im = 0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        PED[0] <= 0;
        PED[1] <= 0;
        PED[2] <= 0;
        PED[3] <= 0;
    end
    else begin
        if (c_state == S3 && counter == 12) begin
            PED[0] <= norm_out;
        end
        else if (c_state == S3 && counter ==13) begin
            PED[1] <= norm_out;
        end
        else if (c_state == S3 && counter ==14) begin
            PED[2] <= norm_out;
        end
        else if (c_state == S3 && counter ==15) begin
            PED[3] <= norm_out;
        end
        else begin
            PED[0] <= PED[0];
            PED[1] <= PED[1];
            PED[2] <= PED[2];
            PED[3] <= PED[3];
        end
    end
end

//=========================================================================
//calculate PED level 2

always@(posedge clk) begin
    if(c_state == S6 && counter == 26) begin
        r01_x1_re[0] <= complex_mul_out_re;
        r01_x1_im[0] <= complex_mul_out_im;
    end
    else begin
        r01_x1_re[0] <= r01_x1_re[0];
        r01_x1_im[0] <= r01_x1_im[0];
    end
end
always@(posedge clk) begin
    if(c_state == S6 && counter == 27) begin
        r01_x1_re[1] <= complex_mul_out_re;
        r01_x1_im[1] <= complex_mul_out_im;
    end
    else begin
        r01_x1_re[1] <= r01_x1_re[1];
        r01_x1_im[1] <= r01_x1_im[1];
    end
end

always @(posedge clk) begin
    if(c_state == S6 && counter ==28) begin
        PED2_temp_re[0] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[0];
        PED2_temp_re[4] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[1];
        PED2_temp_im[0] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[0];
        PED2_temp_im[4] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[1];
    end
    else begin
        PED2_temp_re[0] <= PED2_temp_re[0];
        PED2_temp_re[4] <= PED2_temp_re[4];
        PED2_temp_im[0] <= PED2_temp_im[0];
        PED2_temp_im[4] <= PED2_temp_im[4];
    end
end
always @(posedge clk) begin
    if(c_state == S6 && counter ==29) begin
        PED2_temp_re[1] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[0];
        PED2_temp_re[5] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[1];
        PED2_temp_im[1] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[0];
        PED2_temp_im[5] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[1];
    end
    else begin
        PED2_temp_re[1] <= PED2_temp_re[1];
        PED2_temp_re[5] <= PED2_temp_re[5];
        PED2_temp_im[1] <= PED2_temp_im[1];
        PED2_temp_im[5] <= PED2_temp_im[5];
    end
end
always @(posedge clk) begin
    if(c_state == S6 && counter ==30) begin
        PED2_temp_re[2] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[0];
        PED2_temp_re[6] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[1];
        PED2_temp_im[2] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[0];
        PED2_temp_im[6] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[1];
    end
    else begin
        PED2_temp_re[2] <= PED2_temp_re[2];
        PED2_temp_re[6] <= PED2_temp_re[6];
        PED2_temp_im[2] <= PED2_temp_im[2];
        PED2_temp_im[6] <= PED2_temp_im[6];
    end
end
always @(posedge clk) begin
    if(c_state == S6 && counter ==31) begin
        PED2_temp_re[3] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[0];
        PED2_temp_re[7] <= y_hat_0_re - complex_mul_out_re - r01_x1_re[1];
        PED2_temp_im[3] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[0];
        PED2_temp_im[7] <= y_hat_0_im - complex_mul_out_im - r01_x1_im[1];
    end
    else begin
        PED2_temp_re[3] <= PED2_temp_re[3];
        PED2_temp_re[7] <= PED2_temp_re[7];
        PED2_temp_im[3] <= PED2_temp_im[3];
        PED2_temp_im[7] <= PED2_temp_im[7];
    end
end
//=========================================================================
//calculate PED step2(level2)
reg signed [WIDTH-1:0] PED2 [0:7];

always @(posedge clk) begin
        if (c_state == S7 && counter == 33) begin
            PED2[0] <= norm_out + sort_PED[0];
        end
        else if (c_state == S7 && counter ==34) begin
            PED2[1] <= norm_out + sort_PED[0];
        end
        else if (c_state == S7 && counter ==35) begin
            PED2[2] <= norm_out + sort_PED[0];
        end
        else if (c_state == S7 && counter ==36) begin
            PED2[3] <= norm_out + sort_PED[0];
        end
        else if (c_state == S7 && counter ==37) begin
            PED2[4] <= norm_out + sort_PED[1];
        end
        else if (c_state == S7 && counter ==38) begin
            PED2[5] <= norm_out + sort_PED[1];
        end
        else if (c_state == S7 && counter ==39) begin
            PED2[6] <= norm_out + sort_PED[1];
        end
        else if (c_state == S7 && counter ==40) begin
            PED2[7] <= norm_out + sort_PED[1];
        end
        else begin
            PED2[0] <= PED2[0];
            PED2[1] <= PED2[1];
            PED2[2] <= PED2[2];
            PED2[3] <= PED2[3];
            PED2[4] <= PED2[4];
            PED2[5] <= PED2[5];
            PED2[6] <= PED2[6];
            PED2[7] <= PED2[7];
        end
    end

//=========================================================================
//level1 bubble sort (stage 1)
reg        [2:0]       sort_count;
reg                    sort_enable;
always@(*) begin
    if (c_state == S5)
        sort_enable = 1;
    else
        sort_enable = 0;
end
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sort_count <= 0;
    end
    else begin
        sort_count <= (sort_enable)? sort_count + 1 : 0;
    end
end

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        candidate_1_re[0] <= symbol_0_re;
        candidate_1_im[0] <= symbol_0_im;
        candidate_1_re[1] <= symbol_1_re;
        candidate_1_im[1] <= symbol_1_im;
        candidate_1_re[2] <= symbol_2_re;
        candidate_1_im[2] <= symbol_2_im;
        candidate_1_re[3] <= symbol_3_re;
        candidate_1_im[3] <= symbol_3_im;
    end
    else begin 
        if(sort_enable) begin
            if ((sort_PED[0] > sort_PED[1]) && sort_count == 0) begin
                candidate_1_re[0] <= candidate_1_re[1];
                candidate_1_im[0] <= candidate_1_im[1];
                candidate_1_re[1] <= candidate_1_re[0];
                candidate_1_im[1] <= candidate_1_im[0];
            end
            else if ((sort_PED[2] > sort_PED[3]) && sort_count == 1) begin
                candidate_1_re[2] <= candidate_1_re[3];
                candidate_1_im[2] <= candidate_1_im[3];
                candidate_1_re[3] <= candidate_1_re[2];
                candidate_1_im[3] <= candidate_1_im[2];
            end
            else if ((sort_PED[1] > sort_PED[2]) && sort_count == 2) begin
                candidate_1_re[1] <= candidate_1_re[2];
                candidate_1_im[1] <= candidate_1_im[2];
                candidate_1_re[2] <= candidate_1_re[1];
                candidate_1_im[2] <= candidate_1_im[1];
            end
            else if ((sort_PED[0] > sort_PED[1]) && sort_count == 3) begin
                candidate_1_re[0] <= candidate_1_re[1];
                candidate_1_im[0] <= candidate_1_im[1];
                candidate_1_re[1] <= candidate_1_re[0];
                candidate_1_im[1] <= candidate_1_im[0];
            end
            else if ((sort_PED[2] > sort_PED[3]) && sort_count == 4) begin
                candidate_1_re[2] <= candidate_1_re[3];
                candidate_1_im[2] <= candidate_1_im[3];
                candidate_1_re[3] <= candidate_1_re[2];
                candidate_1_im[3] <= candidate_1_im[2];
            end
            else if ((sort_PED[1] > sort_PED[2]) && sort_count == 5) begin
                candidate_1_re[1] <= candidate_1_re[2];
                candidate_1_im[1] <= candidate_1_im[2];
                candidate_1_re[2] <= candidate_1_re[1];
                candidate_1_im[2] <= candidate_1_im[1];
            end
            else begin
                candidate_1_re[0] <= candidate_1_re[0];
                candidate_1_im[0] <= candidate_1_im[0];
                candidate_1_re[1] <= candidate_1_re[1];
                candidate_1_im[1] <= candidate_1_im[1];
                candidate_1_re[2] <= candidate_1_re[2];
                candidate_1_im[2] <= candidate_1_im[2];
                candidate_1_re[3] <= candidate_1_re[3];
                candidate_1_im[3] <= candidate_1_im[3];
            end
        end
        else begin
            candidate_1_re[0] <= candidate_1_re[0];
            candidate_1_im[0] <= candidate_1_im[0];
            candidate_1_re[1] <= candidate_1_re[1];
            candidate_1_im[1] <= candidate_1_im[1];
            candidate_1_re[2] <= candidate_1_re[2];
            candidate_1_im[2] <= candidate_1_im[2];
            candidate_1_re[3] <= candidate_1_re[3];
            candidate_1_im[3] <= candidate_1_im[3];
        end
    end
end
//level1 bubble sort (stage 2)
// always @(posedge clk) begin
//     if (c_state == S4) begin
//         sort_PED[0] <= PED[0];
//         sort_PED[1] <= PED[1];
//     end
//     else begin
//         if (sort_enable) begin
//             if ((sort_PED[0] > sort_PED[1]) && sort_count == 0) begin
//                     sort_PED[1] <= sort_PED[0];
//                     sort_PED[0] <= sort_PED[1];
//                 end
//             else if ((sort_PED[0] > sort_PED[1]) && sort_count == 2) begin
//                 sort_PED[1] <= sort_PED[0];
//                 sort_PED[0] <= sort_PED[1];
//             end
//             else begin
//                 sort_PED[0] <= sort_PED[0];
//                 sort_PED[1] <= sort_PED[1];
//             end
//         end
//         else begin
//             sort_PED[0] <= sort_PED[0];
//             sort_PED[1] <= sort_PED[1];
//         end
//     end
// end
// always @(posedge clk) begin
//     if (c_state == S4) begin
//         sort_PED[2] <= PED[2];
//         sort_PED[3] <= PED[3];
//     end
//     else begin
//         if (sort_enable) begin
//             if ((sort_PED[2] > sort_PED[3]) && sort_count == 0) begin
//                 sort_PED[2] <= sort_PED[3];
//                 sort_PED[3] <= sort_PED[2];
//             end
//             else if ((sort_PED[2] > sort_PED[3]) && sort_count == 2) begin
//                 sort_PED[2] <= sort_PED[3];
//                 sort_PED[3] <= sort_PED[2];
//             end
//             else begin
//                 sort_PED[2] <= sort_PED[2];
//                 sort_PED[3] <= sort_PED[3];
//             end
//         end
//         else begin
//             sort_PED[2] <= sort_PED[2];
//             sort_PED[3] <= sort_PED[3];
//         end
//     end
// end
always @(posedge clk) begin
    if (c_state == S4) begin
        sort_PED[0] <= PED[0];
        sort_PED[1] <= PED[1];
        sort_PED[2] <= PED[2];
        sort_PED[3] <= PED[3];
    end
    else begin
        if (sort_enable) begin
            if ((sort_PED[0] > sort_PED[1]) && sort_count == 0) begin
                    sort_PED[1] <= sort_PED[0];
                    sort_PED[0] <= sort_PED[1];
                end
            else if ((sort_PED[2] > sort_PED[3]) && sort_count == 1) begin
                sort_PED[2] <= sort_PED[3];
                sort_PED[3] <= sort_PED[2];
            end
            else if ((sort_PED[1] > sort_PED[2]) && sort_count == 2) begin
                sort_PED[1] <= sort_PED[2];
                sort_PED[2] <= sort_PED[1];
            end
            else if ((sort_PED[0] > sort_PED[1]) && sort_count == 3) begin
                sort_PED[1] <= sort_PED[0];
                sort_PED[0] <= sort_PED[1];
            end
            else if ((sort_PED[2] > sort_PED[3]) && sort_count == 4) begin
                sort_PED[2] <= sort_PED[3];
                sort_PED[3] <= sort_PED[2];
            end
            else if ((sort_PED[1] > sort_PED[2]) && sort_count == 5) begin
                sort_PED[1] <= sort_PED[2];
                sort_PED[2] <= sort_PED[1];
            end
            else begin
                sort_PED[0] <= sort_PED[0];
                sort_PED[1] <= sort_PED[1];
                sort_PED[2] <= sort_PED[2];
                sort_PED[3] <= sort_PED[3];
            end
        end
        else begin
            sort_PED[0] <= sort_PED[0];
            sort_PED[1] <= sort_PED[1];
            sort_PED[2] <= sort_PED[2];
            sort_PED[3] <= sort_PED[3];
        end
    end
end
//=========================================================================
//level2 bubble sort (stage 1)
reg        [2:0]       sort_2_count;
reg                    sort_2_enable;
always@(*) begin
    if (c_state == S9)
        sort_2_enable = 1;
    else
        sort_2_enable = 0;
end
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sort_2_count <= 0;
    end
    else begin
        sort_2_count <= (sort_2_enable)? sort_2_count + 1 : 0;
    end
end
// sort for PED2 0~3
always@(posedge clk ) begin
    if(c_state == S8) begin
        candidate_2_re[0] <= symbol_0_re;
        candidate_2_im[0] <= symbol_0_im;
        candidate_2_re[1] <= symbol_1_re;
        candidate_2_im[1] <= symbol_1_im;
        candidate_2_re[2] <= symbol_2_re;
        candidate_2_im[2] <= symbol_2_im;
        candidate_2_re[3] <= symbol_3_re;
        candidate_2_im[3] <= symbol_3_im;
        
    end
    else begin 
        if ((sort_2_PED[0] > sort_2_PED[1]) && sort_2_count == 0) begin
            candidate_2_re[0] <= candidate_2_re[1];
            candidate_2_im[0] <= candidate_2_im[1];
            candidate_2_re[1] <= candidate_2_re[0];
            candidate_2_im[1] <= candidate_2_im[0];
        end
        else if ((sort_2_PED[2] > sort_2_PED[3]) && sort_2_count == 1) begin
            candidate_2_re[2] <= candidate_2_re[3];
            candidate_2_im[2] <= candidate_2_im[3];
            candidate_2_re[3] <= candidate_2_re[2];
            candidate_2_im[3] <= candidate_2_im[2];
        end
        else if ((sort_2_PED[1] > sort_2_PED[2]) && sort_2_count == 2) begin
            candidate_2_re[1] <= candidate_2_re[2];
            candidate_2_im[1] <= candidate_2_im[2];
            candidate_2_re[2] <= candidate_2_re[1];
            candidate_2_im[2] <= candidate_2_im[1];
        end
        else if ((sort_2_PED[0] > sort_2_PED[1]) && sort_2_count == 3) begin
            candidate_2_re[0] <= candidate_2_re[1];
            candidate_2_im[0] <= candidate_2_im[1];
            candidate_2_re[1] <= candidate_2_re[0];
            candidate_2_im[1] <= candidate_2_im[0];
        end
        else if ((sort_2_PED[2] > sort_2_PED[3]) && sort_2_count == 4) begin
            candidate_2_re[2] <= candidate_2_re[3];
            candidate_2_im[2] <= candidate_2_im[3];
            candidate_2_re[3] <= candidate_2_re[2];
            candidate_2_im[3] <= candidate_2_im[2];
        end
        else if ((sort_2_PED[1] > sort_2_PED[2]) && sort_2_count == 5) begin
            candidate_2_re[1] <= candidate_2_re[2];
            candidate_2_im[1] <= candidate_2_im[2];
            candidate_2_re[2] <= candidate_2_re[1];
            candidate_2_im[2] <= candidate_2_im[1];
        end
        else begin
            candidate_2_re[0] <= candidate_2_re[0];
            candidate_2_im[0] <= candidate_2_im[0];
            candidate_2_re[1] <= candidate_2_re[1];
            candidate_2_im[1] <= candidate_2_im[1];
            candidate_2_re[2] <= candidate_2_re[2];
            candidate_2_im[2] <= candidate_2_im[2];
            candidate_2_re[3] <= candidate_2_re[3];
            candidate_2_im[3] <= candidate_2_im[3];
        end
    end
end
// sort for PED2 4~7
always@(posedge clk) begin
    if(c_state == S8) begin
        candidate_2_re[4] <= symbol_0_re;
        candidate_2_im[4] <= symbol_0_im;
        candidate_2_re[5] <= symbol_1_re;
        candidate_2_im[5] <= symbol_1_im;
        candidate_2_re[6] <= symbol_2_re;
        candidate_2_im[6] <= symbol_2_im;
        candidate_2_re[7] <= symbol_3_re;
        candidate_2_im[7] <= symbol_3_im;
        
    end
    else begin 
        if ((sort_2_PED[4] > sort_2_PED[5]) && sort_2_count == 0) begin
            candidate_2_re[4] <= candidate_2_re[5];
            candidate_2_im[4] <= candidate_2_im[5];
            candidate_2_re[5] <= candidate_2_re[4];
            candidate_2_im[5] <= candidate_2_im[4];
        end
        else if ((sort_2_PED[6] > sort_2_PED[7]) && sort_2_count == 1) begin
            candidate_2_re[6] <= candidate_2_re[7];
            candidate_2_im[6] <= candidate_2_im[7];
            candidate_2_re[7] <= candidate_2_re[6];
            candidate_2_im[7] <= candidate_2_im[6];
        end
        else if ((sort_2_PED[5] > sort_2_PED[6]) && sort_2_count == 2) begin
            candidate_2_re[5] <= candidate_2_re[6];
            candidate_2_im[5] <= candidate_2_im[6];
            candidate_2_re[6] <= candidate_2_re[5];
            candidate_2_im[6] <= candidate_2_im[5];
        end
        else if ((sort_2_PED[4] > sort_2_PED[5]) && sort_2_count == 3) begin
            candidate_2_re[4] <= candidate_2_re[5];
            candidate_2_im[4] <= candidate_2_im[5];
            candidate_2_re[5] <= candidate_2_re[4];
            candidate_2_im[5] <= candidate_2_im[4];
        end
        else if ((sort_2_PED[6] > sort_2_PED[7]) && sort_2_count == 4) begin
            candidate_2_re[6] <= candidate_2_re[7];
            candidate_2_im[6] <= candidate_2_im[7];
            candidate_2_re[7] <= candidate_2_re[6];
            candidate_2_im[7] <= candidate_2_im[6];
        end
        else if ((sort_2_PED[5] > sort_2_PED[6]) && sort_2_count == 5) begin
            candidate_2_re[5] <= candidate_2_re[6];
            candidate_2_im[5] <= candidate_2_im[6];
            candidate_2_re[6] <= candidate_2_re[5];
            candidate_2_im[6] <= candidate_2_im[5];
        end
        else begin
            candidate_2_re[4] <= candidate_2_re[4];
            candidate_2_im[4] <= candidate_2_im[4];
            candidate_2_re[5] <= candidate_2_re[5];
            candidate_2_im[5] <= candidate_2_im[5];
            candidate_2_re[6] <= candidate_2_re[6];
            candidate_2_im[6] <= candidate_2_im[6];
            candidate_2_re[7] <= candidate_2_re[7];
            candidate_2_im[7] <= candidate_2_im[7];
        end
    end
end
//level1 bubble sort (stage 2)
//sort for PED2 0~3
always @(posedge clk) begin
    if (c_state == S8) begin
        sort_2_PED[0] <= PED2[0];
        sort_2_PED[1] <= PED2[1];
        sort_2_PED[2] <= PED2[2];
        sort_2_PED[3] <= PED2[3];
    end
    else begin
        if (sort_2_enable) begin
            if ((sort_2_PED[0] > sort_2_PED[1]) && sort_2_count == 0) begin
                    sort_2_PED[0] <= sort_2_PED[1];
                    sort_2_PED[1] <= sort_2_PED[0];
                end
            else if ((sort_2_PED[2] > sort_2_PED[3]) && sort_2_count == 1) begin
                sort_2_PED[2] <= sort_2_PED[3];
                sort_2_PED[3] <= sort_2_PED[2];
            end
            else if ((sort_2_PED[1] > sort_2_PED[2]) && sort_2_count == 2) begin
                sort_2_PED[1] <= sort_2_PED[2];
                sort_2_PED[2] <= sort_2_PED[1];
            end
            else if ((sort_2_PED[0] > sort_2_PED[1]) && sort_2_count == 3) begin
                sort_2_PED[1] <= sort_2_PED[0];
                sort_2_PED[0] <= sort_2_PED[1];
            end
            else if ((sort_2_PED[2] > sort_2_PED[3]) && sort_2_count == 4) begin
                sort_2_PED[2] <= sort_2_PED[3];
                sort_2_PED[3] <= sort_2_PED[2];
            end
            else if ((sort_2_PED[1] > sort_2_PED[2]) && sort_2_count == 5) begin
                sort_2_PED[1] <= sort_2_PED[2];
                sort_2_PED[2] <= sort_2_PED[1];
            end
            else begin
                sort_2_PED[0] <= sort_2_PED[0];
                sort_2_PED[1] <= sort_2_PED[1];
                sort_2_PED[2] <= sort_2_PED[2];
                sort_2_PED[3] <= sort_2_PED[3];
            end
        end
        else begin
            sort_2_PED[0] <= sort_2_PED[0];
            sort_2_PED[1] <= sort_2_PED[1];
            sort_2_PED[2] <= sort_2_PED[2];
            sort_2_PED[3] <= sort_2_PED[3];
        end
    end
end
//sort for PED2 4~7
always @(posedge clk) begin
    if (c_state == S8) begin
        sort_2_PED[4] <= PED2[4];
        sort_2_PED[5] <= PED2[5];
        sort_2_PED[6] <= PED2[6];
        sort_2_PED[7] <= PED2[7];
    end
    else begin
        if (sort_2_enable) begin
            if ((sort_2_PED[4] > sort_2_PED[5]) && sort_2_count == 0) begin
                    sort_2_PED[4] <= sort_2_PED[5];
                    sort_2_PED[5] <= sort_2_PED[4];
                end
            else if ((sort_2_PED[6] > sort_2_PED[7]) && sort_2_count == 1) begin
                sort_2_PED[6] <= sort_2_PED[7];
                sort_2_PED[7] <= sort_2_PED[6];
            end
            else if ((sort_2_PED[5] > sort_2_PED[6]) && sort_2_count == 2) begin
                sort_2_PED[5] <= sort_2_PED[6];
                sort_2_PED[6] <= sort_2_PED[5];
            end
            else if ((sort_2_PED[4] > sort_2_PED[5]) && sort_2_count == 3) begin
                sort_2_PED[4] <= sort_2_PED[5];
                sort_2_PED[5] <= sort_2_PED[4];
            end
            else if ((sort_2_PED[6] > sort_2_PED[7]) && sort_2_count == 4) begin
                sort_2_PED[6] <= sort_2_PED[7];
                sort_2_PED[7] <= sort_2_PED[6];
            end
            else if ((sort_2_PED[5] > sort_2_PED[6]) && sort_2_count == 5) begin
                sort_2_PED[5] <= sort_2_PED[6];
                sort_2_PED[6] <= sort_2_PED[5];
            end
            else begin
                sort_2_PED[4] <= sort_2_PED[4];
                sort_2_PED[5] <= sort_2_PED[5];
                sort_2_PED[6] <= sort_2_PED[6];
                sort_2_PED[7] <= sort_2_PED[7];
            end
        end
        else begin
            sort_2_PED[4] <= sort_2_PED[4];
            sort_2_PED[5] <= sort_2_PED[5];
            sort_2_PED[6] <= sort_2_PED[6];
            sort_2_PED[7] <= sort_2_PED[7];
        end
    end
end
//=========================================================================
//final compare
always @(posedge clk) begin
    if (c_state == S10) begin
        if (sort_2_PED[4] < sort_2_PED[0])begin
            x0_re = candidate_2_re[4];
            x0_im = candidate_2_im[4];
            x1_re = candidate_1_re[1];
            x1_im = candidate_1_im[1];
        end
        else begin
            x1_re = candidate_1_re[0];
            x1_im = candidate_1_im[0];
            x0_re = candidate_2_re[0];
            x0_im = candidate_2_im[0];
        end
    end
    else begin
        x0_re = x0_re;
        x0_im = x0_im;
        x1_re = x1_re;
        x1_im = x1_im;
    end
end
// out valid
always @(posedge clk) begin
    if (c_state == S10) 
        out_valid = 1;
    else
        out_valid = 0;
end
endmodule