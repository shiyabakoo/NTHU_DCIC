module square #(
    parameter width = 16,
              scaling = 8
) (
    input   signed  [width-1:0] a,
    output  signed  [width-1:0] b
);
wire signed  [width*2-1:0] temp;

assign temp = a * a;
assign b = temp >>> scaling;
endmodule