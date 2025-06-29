`include "butterfly.v"
`include "delaybuffer.v"
`include "multiply.v"
`include "twiddle.v"
module sdfunit #(
        parameter N = 64,
                  M = 1,
                  width = 16
) (
    input                           clk,
    input                           rst_n,
    input                           di_en,
    input       signed  [width-1:0] di_re,
    input       signed  [width-1:0] di_img,
    output reg                      sdf_out_en,
    output reg  signed  [width-1:0] sdf_out_re,
    output reg  signed  [width-1:0] sdf_out_img
);

//  log2 constant function
function integer log2;
    input integer x;
    integer value;
    begin
        value = x-1;
        for (log2=0; value>0; log2=log2+1)
            value = value>>1;
    end
endfunction

localparam  LOG_N = log2(N);    //  Bit Length of N
localparam IDLE = 2'b00,
           S1   = 2'b01, // data in to delay buffer stage
           S2   = 2'b10, // butterfly stage
           S3   = 2'b11; // delay buffer out to multiply stage 

reg         [1:0]       state;
reg         [1:0]       n_state;
reg                     data_en;
wire        [4:0]       tw_addr;
wire                    tw_weight;
reg                     temp_en;
reg  signed [width-1:0] temp_re;
reg  signed [width-1:0] temp_img;
reg         [LOG_N-1:0] do_counter;
reg  signed [width-1:0] data_in_re;
reg  signed [width-1:0] data_in_img ;
reg         [LOG_N-1:0] di_count; // counter for S1 delay buffer
reg  signed [width-1:0] db_in_re; // data to delay buffer
reg  signed [width-1:0] db_in_img; 
reg  signed [width-1:0] bf_in0_re; //data to butterfly
reg  signed [width-1:0] bf_in0_img;
wire signed [width-1:0] bf_out0_re; // data from butterfly
wire signed [width-1:0] bf_out0_img;
reg  signed [width-1:0] bf_in1_re; //data to butterfly
reg  signed [width-1:0] bf_in1_img;
wire signed [width-1:0] bf_out1_re; // data from butterfly
wire signed [width-1:0] bf_out1_img;
reg  signed [width-1:0] mul_in0_re;
reg  signed [width-1:0] mul_in0_img;
wire signed [width-1:0] mul_in1_re;
wire signed [width-1:0] mul_in1_img;
wire signed [width-1:0] mul_out_re;
wire signed [width-1:0] mul_out_img;
wire signed [width-1:0] db_out_re;
wire signed [width-1:0] db_out_img;
//module instance
butterfly u1(   
    .d0_re(bf_in0_re), 
    .d0_img(bf_in0_img), 
    .d1_re(bf_in1_re), 
    .d1_img(bf_in1_img), 
    .out0_re(bf_out0_re), 
    .out0_img(bf_out0_img), 
    .out1_re(bf_out1_re), 
    .out1_img(bf_out1_img)
);
delaybuffer #(.depth(N >> 1)) u2(
    .clk (clk),
    .in_re(db_in_re),
    .in_img(db_in_img),
    .out_re(db_out_re),
    .out_img(db_out_img)
);
multiply u3(
    .a_re  (mul_in0_re),
    .a_img (mul_in0_img),
    .b_re  (mul_in1_re),
    .b_img (mul_in1_img),
    .c_re  (mul_out_re),
    .c_img (mul_out_img)
);
twiddle u4(
    .addr   (tw_addr),
    .tw_re  (mul_in1_re),
    .tw_img (mul_in1_img)
);

// get input data
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_in_re <= {width{1'b0}};
        data_in_img <= {width{1'b0}};

    end
    else begin
        data_in_re <= di_re;
        data_in_img <= di_img;
    end

end
// input data ready
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_en <= 1'b0;
    else
        data_en <= di_en;
end

// current state
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= n_state;
end

// next state logic
always@(*) begin
    case(state)
        IDLE: if(di_en)
                n_state = S1;
              else
                n_state = IDLE;
        S1  : if(di_count == (N >> 1) - 1'b1)
                n_state = S2;
              else
                n_state = S1;
        S2  : if(di_count == {LOG_N{1'b1}})
                n_state = S3;
              else
                n_state = S2;
        S3  : if(di_count == (N >> 1) - 1'b1)
                n_state = S2;
              else
                n_state = S3;
        default: n_state = IDLE;
    endcase
end

//data_in counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        di_count <= {LOG_N{1'b0}};
    end
    else begin
        di_count <= (data_en || state == S3)? (di_count + 1'b1) : {LOG_N{1'b0}};
    end
end
//delay buffer input
always@(*) begin
    if(state == S1 || state == S3) begin
        db_in_re = data_in_re;
        db_in_img = data_in_img; 
    end
    else if(state == S2) begin
        db_in_re = bf_out0_re;
        db_in_img = bf_out0_img;
    end
    else begin
        db_in_re = {width{1'b0}};
        db_in_img = {width{1'b0}};
    end
end

//butterfly input
always @(*) begin
    if(state == S2) begin
        bf_in0_re = data_in_re;
        bf_in0_img = data_in_img;
        bf_in1_re = db_out_re;
        bf_in1_img = db_out_img;
    end
    else begin
        bf_in0_re = {width{1'b0}};
        bf_in0_img = {width{1'b0}};
        bf_in1_re = {width{1'b0}};
        bf_in1_img = {width{1'b0}};
    end
end

//multiplication input0
always @(*) begin
    if (state == S3) begin
        mul_in0_re = db_out_re;
        mul_in0_img = db_out_img;
    end
    else begin
        mul_in0_re = {width{1'b0}};
        mul_in0_img = {width{1'b0}};
    end
end
//twiddle factor
assign tw_addr = di_count * M; // decide twiddle factor, M = 64 / N (N point FFT)

//prepare output data
always @(*) begin
    if(state == S2) begin
        temp_re = bf_out1_re;
        temp_img = bf_out1_img;
    end
    else if (state == S3 && tw_addr == 0) begin
        temp_re = db_out_re;
        temp_img = db_out_img;
    end
    else if (state == 3) begin
        temp_re = mul_out_re;
        temp_img = mul_out_img;        
    end
    else begin
        temp_re = {width{1'b0}};
        temp_img = {width{1'b0}};
    end
end

always @(*) begin
    if (state == S3 || state == S2) begin
        temp_en = 1'b1;
    end
    else begin
        temp_en = 1'b0;
    end

end

//sdf_out & sdf_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sdf_out_re <= {width{1'b0}};
        sdf_out_img <= {width{1'b0}};
    end
    else begin
        sdf_out_re <= temp_re;
        sdf_out_img <= temp_img;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sdf_out_en <= 1'b0;
    end
    else begin
        sdf_out_en <= temp_en;
    end
end
endmodule
