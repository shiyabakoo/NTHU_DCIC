module QAM_modulation #(
    parameter width = 16,
              scaling = 8
) (
    input                            clk,
    input                            rst_n,
    input                            data_in_en,
    input       signed   [width-1:0] data_in_re,
    input       signed   [width-1:0] data_in_im,
    output  reg                      out_valid,
    output  reg          [255:0]     out_bitstream    // real bit = bit_output[1:0] image bit = bit_output[3:2]   
);
wire           [width*2-1:0] normalization_factor; //sqrt(10) * scalingFactor
wire    signed [width-1:0] boundary_1; //  2
wire    signed [width-1:0] boundary_2; // -2
wire    signed [width*2-1:0] temp1;
wire    signed [width*2-1:0] temp2;
wire    signed [width-1:0] data_re;
wire    signed [width-1:0] data_im;
reg            [6:0]       counter;

assign normalization_factor = 16'h032a;
assign boundary_1 = 16'h0200;
assign boundary_2 = 16'hfe00;
assign temp1 = data_in_re;
assign temp2 = data_in_im;

assign data_re = (normalization_factor * temp1) >>> scaling;
assign data_im = (normalization_factor * temp2) >>> scaling;

// assign data_re = temp1;
// assign data_im = temp2;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_valid <= 0;
    else
        out_valid <= (counter == 127)? 1'b1 : 1'b0;
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
always @(posedge clk) begin
    if (!rst_n) begin
        for (i = 0; i < 64; i = i + 1) begin
            out_bitstream[i * 4] <= 1'b0;
            out_bitstream[i * 4 + 1] <= 1'b0;
        end
    end
    else begin
        if (data_in_en) begin
            if (data_re <= boundary_2) begin
                out_bitstream[counter * 4] <= 1'b0;
                out_bitstream[counter * 4 + 1] <= 1'b0;
            end
            else if ((data_re > boundary_2) && (data_re <= 0)) begin
                out_bitstream[counter * 4] <= 1'b0;
                out_bitstream[counter * 4 + 1] <= 1'b1;
            end
            else if ((data_re > 0) && (data_re <= boundary_1)) begin
                out_bitstream[counter * 4] <= 1'b1;
                out_bitstream[counter * 4 + 1] <= 1'b1;
            end
            else begin
                out_bitstream[counter * 4] <= 1'b1;
                out_bitstream[counter * 4 + 1] <= 1'b0;
            end
        end
    end
end


// image part
always @(posedge clk) begin
    if (!rst_n) begin
        for (i = 0; i < 64; i = i + 1) begin
            out_bitstream[i * 4 + 2] <= 1'b0;
            out_bitstream[i * 4 + 3] <= 1'b0;
        end
    end
    else begin
        if (data_in_en) begin
            if (data_im > boundary_1) begin
                out_bitstream[counter * 4 + 2] <= 1'b0;
                out_bitstream[counter * 4 + 3] <= 1'b0;
            end
            else if ((data_im > 0) && (data_im <= boundary_1)) begin
                out_bitstream[counter * 4 + 2] <= 1'b0;
                out_bitstream[counter * 4 + 3] <= 1'b1;
            end
            else if ((data_im > boundary_2) && (data_im <= 0)) begin
                out_bitstream[counter * 4 + 2] <= 1'b1;
                out_bitstream[counter * 4 + 3] <= 1'b1;
            end
            else begin
                out_bitstream[counter * 4 + 2] <= 1'b1;
                out_bitstream[counter * 4 + 3] <= 1'b0;
            end
        end
    end
end
endmodule