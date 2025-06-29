module complex_mul #(
    parameter WIDTH = 16
) (
    input clk,
    input signed [WIDTH-1:0] a_re,
    input signed [WIDTH-1:0] a_im,
    input signed [WIDTH-1:0] b_re,
    input signed [WIDTH-1:0] b_im,
    output reg signed [WIDTH-1:0] c_re,
    output reg signed [WIDTH-1:0] c_im

);
reg [WIDTH*2-1:0] temp1, temp2, temp3;
always @(*) begin
    temp1 = b_re * (a_re - a_im);
    temp2 = a_im * (b_re - b_im);
    temp3 = b_im * (a_re + a_im);
end

always @(posedge clk ) begin
    c_re <= (temp1 + temp2) >>> 8;
    c_im <= (temp3 + temp2) >>> 8;
end

endmodule