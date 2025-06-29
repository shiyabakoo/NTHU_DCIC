module qpsk_modulation #(
    parameter width = 16
) (
    input                            clk,
    input                            rst_n,
    input                            data_in_en,
    input       signed   [width-1:0] data_in_re,
    input       signed   [width-1:0] data_in_im,
    output  reg                      out_valid,     
    output  reg          [127:0]     out_bitstream // real bit = bit[0], image bit = bit[1]
);
reg [5:0] counter;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else
        out_valid <= (counter == 63)? 1'b1 : 1'b0;
end
//count for save bitstream
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        counter <= 0;
    else begin
        if (data_in_en)
            counter <= counter + 1;
        else
            counter <= 0; 
    end
end
// real part
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 64; i = i + 1) begin
            out_bitstream[i*2] <= 0;
        end
    end
    else begin
        if (data_in_en) begin
            if (data_in_re >= 0)
                out_bitstream[counter * 2] <= 1'b0;
            else
                out_bitstream[counter * 2] <= 1'b1;
        end
        else
            out_bitstream[counter * 2] <= 1'b0;
    end
end

// image part
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 64; i = i + 1) begin
            out_bitstream[i * 2 + 1] <= 0;
        end
    end
    else begin
        if (data_in_en) begin
            if (data_in_im >= 0)
                out_bitstream[(counter * 2) + 1] <= 1'b0;
            else
                out_bitstream[(counter * 2) + 1] <= 1'b1;
        end
        else
            out_bitstream[(counter * 2) + 1] <= 1'b0;
    end
end
endmodule

