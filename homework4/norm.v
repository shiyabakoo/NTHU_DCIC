module norm #(
    parameter width = 16,
              scaling = 8
) (
    input   signed   [width-1:0] a_re,
    input   signed   [width-1:0] a_im,
    output  signed   [width-1:0] out
);

wire signed [width*2-1:0]   temp1, temp2;
wire signed [width:0]   sc_temp1, sc_temp2;

assign temp1 = a_re * a_re;
assign temp2 = a_im * a_im;

assign sc_temp1 = temp1 >>> scaling;
assign sc_temp2 = temp2 >>> scaling;

assign out = sc_temp1 + sc_temp2;
endmodule