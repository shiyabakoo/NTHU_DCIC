module cordic_unit #(
    parameter WIDTH = 16
) (
    input                        clk,
    input                        rst_n,
    input  signed [WIDTH-1:0]    x_start,
    input  signed [WIDTH-1:0]    y_start,
    input  signed [WIDTH:0]      z_start,
    input                        mode,
    output signed [WIDTH-1:0]    x_out,
    output signed [WIDTH-1:0]    y_out,
    output signed [WIDTH:0]      z_out
);

reg  signed [WIDTH-1:0] xi     [0:WIDTH-2]; // cordic input x 
reg  signed [WIDTH-1:0] yi     [0:WIDTH-2]; // cordic input y
reg  signed [WIDTH:0]   zi     [0:WIDTH-2]; // cordic input z
reg  signed [WIDTH-1:0]   temp_x; // for pipeline    
reg  signed [WIDTH-1:0]   temp_y; // for pipeline    
reg  signed [WIDTH:0]   temp_z; // for pipeline    
wire signed [WIDTH-1:0] arctan [0:WIDTH-2];
wire signed [WIDTH-1:0] K_factor;
parameter VECTOR = 1'b0, ROTATION = 1'b1; // mode = 0 is vector mode , mode = 1 is rotation mode


assign K_factor = 16'h009B; // Scaled compensation factor = 0.60546875

// arctan look up table
assign arctan[0] = 16'h2d00; assign arctan[1] = 16'h1A9A;
assign arctan[2] = 16'h0E00; assign arctan[3] = 16'h071A;
assign arctan[4] = 16'h039A; assign arctan[5] = 16'h01CD;
assign arctan[6] = 16'h00E6; assign arctan[7] = 16'h0066;
assign arctan[8] = 16'h0039; assign arctan[9] = 16'h001D;
assign arctan[10] = 16'h000E; assign arctan[11] = 16'h0007;
assign arctan[12] = 16'h0004; assign arctan[13] = 16'h0002;
assign arctan[14] = 16'h0001; 

// start cordic
always @(*) begin
    xi[0] = x_start;
    yi[0] = y_start;
    zi[0] = z_start;
end
// stage 1
always@(*) begin
    case (mode)
        VECTOR: if(yi[0] >= 0) begin
                    xi[1] = xi[0] + yi[0];
                    yi[1] = yi[0] - xi[0];
                    zi[1] = zi[0] + arctan[0];
                end
                else begin
                    xi[1] = xi[0] - yi[0];
                    yi[1] = yi[0] + xi[0];
                    zi[1] = zi[0] - arctan[0];
                end
        ROTATION: if(zi[0] >= 0) begin
                    xi[1] = xi[0] - yi[0];
                    yi[1] = yi[0] + xi[0];
                    zi[1] = zi[0] - arctan[0];
                end
                else begin
                    xi[1] = xi[0] + yi[0];
                    yi[1] = yi[0] - xi[0];
                    zi[1] = zi[0] + arctan[0];
                end
        default: begin
                 xi[1] = 0;
                 yi[1] = 0;
                 zi[1] = 0;
                 end
    endcase
end
// stage 2
always@(*) begin
    case (mode)
        VECTOR: if(yi[1] >= 0) begin
                    xi[2] = xi[1] + (yi[1] >>> 1);
                    yi[2] = yi[1] - (xi[1] >>> 1);
                    zi[2] = zi[1] + arctan[1];
                end
                else begin
                    xi[2] = xi[1] - (yi[1] >>> 1);
                    yi[2] = yi[1] + (xi[1] >>> 1);
                    zi[2] = zi[1] - arctan[1];
                end
        ROTATION: if(zi[1] >= 0) begin
                    xi[2] = xi[1] - (yi[1] >>> 1);
                    yi[2] = yi[1] + (xi[1] >>> 1);
                    zi[2] = zi[1] - arctan[1];
                end
                else begin
                    xi[2] = xi[1] + (yi[1] >>> 1);
                    yi[2] = yi[1] - (xi[1] >>> 1);
                    zi[2] = zi[1] + arctan[1];
                end
        default: begin
                 xi[2] = 0;
                 yi[2] = 0;
                 zi[2] = 0;
                 end 
    endcase
end
// stage 3
always@(*) begin
    case (mode)
        VECTOR: if(yi[2] >= 0) begin
                    xi[3] = xi[2] + (yi[2] >>> 2);
                    yi[3] = yi[2] - (xi[2] >>> 2);
                    zi[3] = zi[2] + arctan[2];
                end
                else begin
                    xi[3] = xi[2] - (yi[2] >>> 2);
                    yi[3] = yi[2] + (xi[2] >>> 2);
                    zi[3] = zi[2] - arctan[2];
                end
        ROTATION: if(zi[2] >= 0) begin
                    xi[3] = xi[2] - (yi[2] >>> 2);
                    yi[3] = yi[2] + (xi[2] >>> 2);
                    zi[3] = zi[2] - arctan[2];
                end
                else begin
                    xi[3] = xi[2] + (yi[2] >>> 2);
                    yi[3] = yi[2] - (xi[2] >>> 2);
                    zi[3] = zi[2] + arctan[2];
                end
        default: begin 
                 xi[3] = 0;
                 yi[3] = 0;
                 zi[3] = 0;
                 end
    endcase
end
// stage 4
always@(*) begin
    case (mode)
        VECTOR: if(yi[3] >= 0) begin
                    xi[4] = xi[3] + (yi[3] >>> 3);
                    yi[4] = yi[3] - (xi[3] >>> 3);
                    zi[4] = zi[3] + arctan[3];
                end
                else begin
                    xi[4] = xi[3] - (yi[3] >>> 3);
                    yi[4] = yi[3] + (xi[3] >>> 3);
                    zi[4] = zi[3] - arctan[3];
                end
        ROTATION: if(zi[3] >= 0) begin
                    xi[4] = xi[3] - (yi[3] >>> 3);
                    yi[4] = yi[3] + (xi[3] >>> 3);
                    zi[4] = zi[3] - arctan[3];
                end
                else begin
                    xi[4] = xi[3] + (yi[3] >>> 3);
                    yi[4] = yi[3] - (xi[3] >>> 3);
                    zi[4] = zi[3] + arctan[3];
                end
        default: begin
                 xi[4] = 0;
                 yi[4] = 0;
                 zi[4] = 0;
                 end
    endcase
end
// stage 5
always@(*) begin
    case (mode)
        VECTOR: if(yi[4] >= 0) begin
                    xi[5] = xi[4] + (yi[4] >>> 4);
                    yi[5] = yi[4] - (xi[4] >>> 4);
                    zi[5] = zi[4] + arctan[4];
                end
                else begin
                    xi[5] = xi[4] - (yi[4] >>> 4);
                    yi[5] = yi[4] + (xi[4] >>> 4);
                    zi[5] = zi[4] - arctan[4];
                end
        ROTATION: if(zi[4] >= 0) begin
                    xi[5] = xi[4] - (yi[4] >>> 4);
                    yi[5] = yi[4] + (xi[4] >>> 4);
                    zi[5] = zi[4] - arctan[4];
                end
                else begin
                    xi[5] = xi[4] + (yi[4] >>> 4);
                    yi[5] = yi[4] - (xi[4] >>> 4);
                    zi[5] = zi[4] + arctan[4];
                end
        default: begin
                 xi[5] = 0;
                 yi[5] = 0;
                 zi[5] = 0;
                 end
    endcase
end
// stage 6
always@(*) begin
    case (mode)
        VECTOR: if(yi[5] >= 0) begin
                    xi[6] = xi[5] + (yi[5] >>> 5);
                    yi[6] = yi[5] - (xi[5] >>> 5);
                    zi[6] = zi[5] + arctan[5];
                end
                else begin
                    xi[6] = xi[5] - (yi[5] >>> 5);
                    yi[6] = yi[5] + (xi[5] >>> 5);
                    zi[6] = zi[5] - arctan[5];
                end
        ROTATION: if(zi[5] >= 0) begin
                    xi[6] = xi[5] - (yi[5] >>> 5);
                    yi[6] = yi[5] + (xi[5] >>> 5);
                    zi[6] = zi[5] - arctan[5];
                end
                else begin
                    xi[6] = xi[5] + (yi[5] >>> 5);
                    yi[6] = yi[5] - (xi[5] >>> 5);
                    zi[6] = zi[5] + arctan[5];
                end
        default: begin
                 xi[6] = 0;
                 yi[6] = 0;
                 zi[6] = 0;
                 end
    endcase
end
// pipeline stage
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        temp_x <= 0;
        temp_y <= 0;
        temp_z <= 0;
    end 
    else begin
        temp_x <= xi[6];
        temp_y <= yi[6];
        temp_z <= zi[6];
    end
end
// stage 7
always@(*) begin
    case (mode)
        VECTOR: if(temp_y >= 0) begin
                    xi[7] = temp_x + (temp_y >>> 6);
                    yi[7] = temp_y - (temp_x >>> 6);
                    zi[7] = temp_z + arctan[6];
                end
                else begin
                    xi[7] = temp_x - (temp_y >>> 6);
                    yi[7] = temp_y + (temp_x >>> 6);
                    zi[7] = temp_z - arctan[6];
                end
        ROTATION: if(temp_z >= 0) begin
                    xi[7] = temp_x - (temp_y >>> 6);
                    yi[7] = temp_y + (temp_x >>> 6);
                    zi[7] = temp_z - arctan[6];
                end
                else begin
                    xi[7] = temp_x + (temp_y >>> 6);
                    yi[7] = temp_y - (temp_x >>> 6);
                    zi[7] = temp_z + arctan[6];
                end
        default: begin
                 xi[7] = 0;
                 yi[7] = 0;
                 zi[7] = 0;
                 end
    endcase
end
// stage 8
always@(*) begin
    case (mode)
        VECTOR: if(yi[7] >= 0) begin
                    xi[8] = xi[7] + (yi[7] >>> 7);
                    yi[8] = yi[7] - (xi[7] >>> 7);
                    zi[8] = zi[7] + arctan[7];
                end
                else begin
                    xi[8] = xi[7] - (yi[7] >>> 7);
                    yi[8] = yi[7] + (xi[7] >>> 7);
                    zi[8] = zi[7] - arctan[7];
                end
        ROTATION: if(zi[7] >= 0) begin
                    xi[8] = xi[7] - (yi[7] >>> 7);
                    yi[8] = yi[7] + (xi[7] >>> 7);
                    zi[8] = zi[7] - arctan[7];
                end
                else begin
                    xi[8] = xi[7] + (yi[7] >>> 7);
                    yi[8] = yi[7] - (xi[7] >>> 7);
                    zi[8] = zi[7] + arctan[7];
                end
        default: begin
                 xi[8] = 0;
                 yi[8] = 0;
                 zi[8] = 0;
                 end
    endcase
end
// stage 9
always@(*) begin
    case (mode)
        VECTOR: if(yi[8] >= 0) begin
                    xi[9] = xi[8] + (yi[8] >>> 8);
                    yi[9] = yi[8] - (xi[8] >>> 8);
                    zi[9] = zi[8] + arctan[8];
                end
                else begin
                    xi[9] = xi[8] - (yi[8] >>> 8);
                    yi[9] = yi[8] + (xi[8] >>> 8);
                    zi[9] = zi[8] - arctan[8];
                end
        ROTATION: if(zi[8] >= 0) begin
                    xi[9] = xi[8] - (yi[8] >>> 8);
                    yi[9] = yi[8] + (xi[8] >>> 8);
                    zi[9] = zi[8] - arctan[8];
                end
                else begin
                    xi[9] = xi[8] + (yi[8] >>> 8);
                    yi[9] = yi[8] - (xi[8] >>> 8);
                    zi[9] = zi[8] + arctan[8];
                end
        default: begin
                 xi[9] = 0;
                 yi[9] = 0;
                 zi[9] = 0;
                 end
    endcase
end
// stage 10
always@(*) begin
    case (mode)
        VECTOR: if(yi[9] >= 0) begin
                    xi[10] = xi[9] + (yi[9] >>> 9);
                    yi[10] = yi[9] - (xi[9] >>> 9);
                    zi[10] = zi[9] + arctan[9];
                end
                else begin
                    xi[10] = xi[9] - (yi[9] >>> 9);
                    yi[10] = yi[9] + (xi[9] >>> 9);
                    zi[10] = zi[9] - arctan[9];
                end
        ROTATION: if(zi[9] >= 0) begin
                    xi[10] = xi[9] - (yi[9] >>> 9);
                    yi[10] = yi[9] + (xi[9] >>> 9);
                    zi[10] = zi[9] - arctan[9];
                end
                else begin
                    xi[10] = xi[9] + (yi[9] >>> 9);
                    yi[10] = yi[9] - (xi[9] >>> 9);
                    zi[10] = zi[9] + arctan[9];
                end
        default: begin
                 xi[10] = 0;
                 yi[10] = 0;
                 zi[10] = 0;
                 end
    endcase
end
// stage 11
always@(*) begin
    case (mode)
        VECTOR: if(yi[10] >= 0) begin
                    xi[11] = xi[10] + (yi[10] >>> 10);
                    yi[11] = yi[10] - (xi[10] >>> 10);
                    zi[11] = zi[10] + arctan[10];
                end
                else begin
                    xi[11] = xi[10] - (yi[10] >>> 10);
                    yi[11] = yi[10] + (xi[10] >>> 10);
                    zi[11] = zi[10] - arctan[10];
                end
        ROTATION: if(zi[10] >= 0) begin
                    xi[11] = xi[10] - (yi[10] >>> 10);
                    yi[11] = yi[10] + (xi[10] >>> 10);
                    zi[11] = zi[10] - arctan[10];
                end
                else begin
                    xi[11] = xi[10] + (yi[10] >>> 10);
                    yi[11] = yi[10] - (xi[10] >>> 10);
                    zi[11] = zi[10] + arctan[10];
                end
        default: begin
                 xi[11] = 0;
                 yi[11] = 0;
                 zi[11] = 0;
                 end
    endcase
end
// stage 12
always@(*) begin
    case (mode)
        VECTOR: if(yi[11] >= 0) begin
                    xi[12] = xi[11] + (yi[11] >>> 11);
                    yi[12] = yi[11] - (xi[11] >>> 11);
                    zi[12] = zi[11] + arctan[11];
                end
                else begin
                    xi[12] = xi[11] - (yi[11] >>> 11);
                    yi[12] = yi[11] + (xi[11] >>> 11);
                    zi[12] = zi[11] - arctan[11];
                end
        ROTATION: if(zi[11] >= 0) begin
                    xi[12] = xi[11] - (yi[11] >>> 11);
                    yi[12] = yi[11] + (xi[11] >>> 11);
                    zi[12] = zi[11] - arctan[11];
                end
                else begin
                    xi[12] = xi[11] + (yi[11] >>> 11);
                    yi[12] = yi[11] - (xi[11] >>> 11);
                    zi[12] = zi[11] + arctan[11];
                end
        default: begin
                 xi[12] = 0;
                 yi[12] = 0;
                 zi[12] = 0;
                 end
    endcase
end
// stage 13
always@(*) begin
    case (mode)
        VECTOR: if(yi[12] >= 0) begin
                    xi[13] = xi[12] + (yi[12] >>> 12);
                    yi[13] = yi[12] - (xi[12] >>> 12);
                    zi[13] = zi[12] + arctan[12];
                end
                else begin
                    xi[13] = xi[12] - (yi[12] >>> 12);
                    yi[13] = yi[12] + (xi[12] >>> 12);
                    zi[13] = zi[12] - arctan[12];
                end
        ROTATION: if(zi[12] >= 0) begin
                    xi[13] = xi[12] - (yi[12] >>> 12);
                    yi[13] = yi[12] + (xi[12] >>> 12);
                    zi[13] = zi[12] - arctan[12];
                end
                else begin
                    xi[13] = xi[12] + (yi[12] >>> 12);
                    yi[13] = yi[12] - (xi[12] >>> 12);
                    zi[13] = zi[12] + arctan[12];
                end
        default: begin
                 xi[13] = 0;
                 yi[13] = 0;
                 zi[13] = 0;
                 end
    endcase
end
// stage 14
always@(*) begin
    case (mode)
        VECTOR: if(yi[13] >= 0) begin
                    xi[14] = xi[13] + (yi[13] >>> 13);
                    yi[14] = yi[13] - (xi[13] >>> 13);
                    zi[14] = zi[13] + arctan[13];
                end
                else begin
                    xi[14] = xi[13] - (yi[13] >>> 13);
                    yi[14] = yi[13] + (xi[13] >>> 13);
                    zi[14] = zi[13] - arctan[13];
                end
        ROTATION: if(zi[13] >= 0) begin
                    xi[14] = xi[13] - (yi[13] >>> 13);
                    yi[14] = yi[13] + (xi[13] >>> 13);
                    zi[14] = zi[13] - arctan[13];
                end
                else begin
                    xi[14] = xi[13] + (yi[13] >>> 13);
                    yi[14] = yi[13] - (xi[13] >>> 13);
                    zi[14] = zi[13] + arctan[13];
                end
        default: begin
                 xi[14] = 0;
                 yi[14] = 0;
                 zi[14] = 0;
                 end
    endcase
end
wire signed [WIDTH*2:0] temp1;// prevent overflow
wire signed [WIDTH*2:0] temp2;// prevent overflow

assign temp1 = xi[14] * K_factor;
assign temp2 = yi[14] * K_factor;

assign x_out = temp1 >>> 8;
assign y_out = temp2 >>> 8;
assign z_out = zi[14];
endmodule