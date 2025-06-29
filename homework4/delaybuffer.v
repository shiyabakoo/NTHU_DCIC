module delaybuffer#(
    parameter depth = 32,
               width = 16
) (
    input             clk,
    input [width-1:0] in_re,
    input [width-1:0] in_img,
    output [width-1:0] out_re,
    output [width-1:0] out_img
);

reg [width-1:0] shift_re [depth-1:0];
reg [width-1:0] shift_img [depth-1:0];

assign out_re = shift_re[depth-1];
assign out_img = shift_img[depth-1];

integer i;
always @(posedge clk) begin
    for(i = depth-1; i > 0; i = i -1) begin
        shift_re[i] <= shift_re[i-1];
        shift_img[i] <= shift_img[i-1];
    end
    shift_re[0] <= in_re;
    shift_img[0] <= in_img;
end

    
endmodule