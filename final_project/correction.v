`include "CORDIC.v"
module cordic #(
    parameter  WIDTH = 16 
) (
    input                     clk,
    input                     rst_n,
    input  signed [WIDTH-1:0] x_input,
    input  signed [WIDTH-1:0] y_input,
    input  signed [WIDTH:0]   z_input,
    input                     mode,
    output signed [WIDTH-1:0] x_output,
    output signed [WIDTH-1:0] y_output,
    output signed [WIDTH:0]   z_output
);

reg signed [WIDTH-1:0] x_start;
reg signed [WIDTH-1:0] y_start;
reg signed [WIDTH:0]   z_start;

cordic_unit u1(
    .clk(clk),
    .rst_n(rst_n),
    .x_start(x_start), 
    .y_start(y_start), 
    .z_start(z_start), 
    .mode(mode), 
    .x_out(x_output), 
    .y_out(y_output),
    .z_out(z_output)
);


parameter VECTOR =1'b0, ROTATION = 1'b1;
wire pre_dir;
wire pre_rot;
wire signed [WIDTH:0] angle_limit;

assign angle_limit = 16'h5A00; // angle 90

assign pre_dir = (x_input < 0);
assign pre_rot = ((z_input > angle_limit) || (z_input < -angle_limit));
// vector mode correction
always@(*) begin
    case (mode)
        VECTOR: if (pre_dir) begin
                    if (y_input >= 0) begin
                        x_start =  y_input;
                        y_start = -x_input;
                        z_start =  z_input + angle_limit;
                    end
                    else begin
                        x_start = -y_input;
                        y_start =  x_input;
                        z_start = z_input - angle_limit;
                    end
                end
                else begin
                    x_start = x_input;
                    y_start = y_input;
                    z_start = z_input;
                end
        ROTATION: if (pre_rot) begin
                    if (z_input >= 0) begin
                        x_start = -y_input;
                        y_start =  x_input;
                        z_start =  z_input - angle_limit;
                    end
                    else begin
                        x_start =  y_input;
                        y_start = -x_input;
                        z_start =  z_input + angle_limit;
                    end
                  end
                  else begin
                    x_start = x_input;
                    y_start = y_input;
                    z_start = z_input;
                  end
        default: begin
                    x_start = 0;
                    y_start = 0;
                    z_start = 0;
                end
    endcase
end
endmodule