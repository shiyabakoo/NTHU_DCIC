module shift_register #(
    parameter width = 16,
              depth = 64
) (
    input             clk,
    input             rst_n,
    input[width-1:0] data_re,
    input[width-1:0] data_im,
    //input             data_en,
    output[width-1:0] shift_out_re,
    output[width-1:0] shift_out_im
);

reg [width-1:0] shift_re [depth-1:0];
reg [width-1:0] shift_im [depth-1:0];

assign shift_out_re = shift_re[depth-1];
assign shift_out_im = shift_im[depth-1];

// shift logic
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < depth; i = i + 1) begin
            shift_re[i] <= {width{1'b0}};
            shift_im[i] <= {width{1'b0}};
        end        
    end
    else begin
        for (i = depth - 1; i > 0; i = i - 1) begin
            shift_re[i] <= shift_re[i - 1];
            shift_im[i] <= shift_im[i - 1];
        end
        shift_re[0] <= data_re;
        shift_im[0] <= data_im;
    end

end
endmodule