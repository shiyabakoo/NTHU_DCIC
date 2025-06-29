module butterfly #(
    parameter WIDTH = 16
) (
    input       signed [WIDTH-1:0] d0_re,
    input       signed [WIDTH-1:0] d0_img,
    input       signed [WIDTH-1:0] d1_re,
    input       signed [WIDTH-1:0] d1_img,
    output  reg signed [WIDTH-1:0] out0_re,
    output  reg signed [WIDTH-1:0] out0_img,
    output  reg signed [WIDTH-1:0] out1_re,
    output  reg signed [WIDTH-1:0] out1_img
);

    always @(*) begin
        out0_re = d1_re - d0_re;
        out0_img = d1_img - d0_img;
        out1_re = d1_re + d0_re;
        out1_img = d1_img + d0_img;
    end
    // assign out0_re = d1_re - d0_re;
    // assign out0_img = d1_img - d0_img;
    // assign out1_re = d1_re + d0_re;
    // assign out1_img = d1_img + d0_img;
endmodule