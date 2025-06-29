module norm #(
    parameter WIDTH = 16
) (
    input clk,
    input signed [WIDTH-1:0] in_re,
    input signed [WIDTH-1:0] in_im,
    output reg signed [WIDTH-1:0] out
);
reg [WIDTH*2-1:0] temp1, temp2;
always @(*) begin
    temp1 = (in_re * in_re);
    temp2 = (in_im * in_im);
end

always @(posedge clk) begin
    out <= (temp1 + temp2) >>> 8;
end

endmodule