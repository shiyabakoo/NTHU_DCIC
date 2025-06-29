`include "correction.v"
module QRD #(
    parameter WIDTH = 16
) (
    input                     clk,
    input                     rst_n,
    input  signed [WIDTH-1:0] data_re,
    input  signed [WIDTH-1:0] data_im,
    input                     data_valid,
    output reg signed [WIDTH-1:0] q_H_00_re,
    output reg signed [WIDTH-1:0] q_H_00_im,
    output reg signed [WIDTH-1:0] q_H_01_re,
    output reg signed [WIDTH-1:0] q_H_01_im,
    output reg signed [WIDTH-1:0] q_H_10_re,   
    output reg signed [WIDTH-1:0] q_H_10_im,   
    output reg signed [WIDTH-1:0] q_H_11_re,   
    output reg signed [WIDTH-1:0] q_H_11_im,
    output reg signed [WIDTH-1:0] r00_re,
    output reg signed [WIDTH-1:0] r00_im,
    output reg signed [WIDTH-1:0] r01_re,
    output reg signed [WIDTH-1:0] r01_im,
    output reg signed [WIDTH-1:0] r10_re,
    output reg signed [WIDTH-1:0] r10_im,      
    output reg signed [WIDTH-1:0] r11_re,   
    output reg signed [WIDTH-1:0] r11_im,      
    output reg                    out_valid
);
// define state
reg [2:0] c_state;
reg [2:0] n_state;
parameter IDLE = 3'b000, // IDLE state
          S1   = 3'b001, // get data
          S2   = 3'b010, // change a00 and a01 to real number
          S3   = 3'b011, // calculate norm a0
          S4   = 3'b100, // calculate r01 r11 step 1 and calculate sin(-theta_1) cos(-theta_1)
          S5   = 3'b101, // calculate r01 r11 step 2 and calculate g00 g10
          S6   = 3'b110; // calculate g01 g11




reg signed [WIDTH-1:0] ain_re;
reg signed [WIDTH-1:0] ain_im;



// delay input one cycle
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ain_re <= 0;
        ain_im <= 0;
    end
    else begin
        ain_re <= data_re;
        ain_im <= data_im;
    end
end
// counter
reg [4:0] counter;
wire      counter_enable;

assign counter_enable = data_valid;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end
    else begin
        counter <= (counter_enable)? counter + 1 : counter;
    end
end


// current state 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        c_state <= IDLE;
    end
    else begin
        c_state <= n_state;
    end
end


//next state logic
always@(*) begin
    case (c_state)
        IDLE: if(data_valid) 
                n_state = S1;
              else
                n_state = IDLE;
        S1:   if(counter == 4)
                n_state = S2;
              else 
                n_state = S1;
        S2:   if(counter == 6)
                n_state = S3;
              else
                n_state = S2;
        S3:   if(counter == 8)
                n_state = S4;
              else
                n_state = S3;
        S4:   if(counter == 10)
                n_state = S5;
              else
                n_state = S4;
        S5:   if(counter == 12)
                n_state = S6;
              else
                n_state = S5;
        S6:   n_state = S6;
        default: n_state = IDLE;
    endcase
end




//===================================================================get data===================================================================//
reg signed [WIDTH-1:0] a00_re;
reg signed [WIDTH-1:0] a00_im;
reg signed [WIDTH-1:0] a01_re;
reg signed [WIDTH-1:0] a01_im;
reg signed [WIDTH-1:0] a10_re;
reg signed [WIDTH-1:0] a10_im;
reg signed [WIDTH-1:0] a11_re;
reg signed [WIDTH-1:0] a11_im;


//send data to a00
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a00_re <= 0;
        a00_im <= 0;
    end
    else begin
        if(counter == 1 && c_state == S1) begin
            a00_re <= ain_re;
            a00_im <= ain_im;
        end
        else begin
            a00_re <= a00_re;
            a00_im <= a00_im;
        end
    end
end

//send data to a01
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a01_re <= 0;
        a01_im <= 0;
    end  
    else begin
        if(counter == 2 && c_state == S1) begin
            a01_re <= ain_re;
            a01_im <= ain_im;
        end
        else begin
            a01_re <= a01_re;
            a01_im <= a01_im;
        end
    end
end

//send data to a10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a10_re <= 0;
        a10_im <= 0;
    end
    else begin
        if(counter == 3 && c_state == S1) begin
            a10_re <= ain_re;
            a10_im <= ain_im;
        end
        else begin
            a10_re <= a10_re;
            a10_im <= a10_im;
        end
    end
end

//send data to a11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a11_re <= 0;
        a11_im <= 0;
    end
    else begin
        if(counter == 4 && c_state == S1) begin
            a11_re <= ain_re;
            a11_im <= ain_im;
        end
        else begin
            a11_re <= a11_re;
            a11_im <= a11_im;
        end
    end
end

//===================================================================calculate a00 a10===================================================================//
reg signed [WIDTH-1:0] cordic_x [0:3];
reg signed [WIDTH-1:0] cordic_y [0:3];
reg signed [WIDTH:0]   a00_phi;
reg signed [WIDTH:0]   a10_phi;
reg signed [WIDTH-1:0] norm_a00;
reg signed [WIDTH-1:0] norm_a10;
reg signed [WIDTH:0] initial_angle[0:3];
reg                    mode[0:3];
wire signed [WIDTH-1:0] cordic_x_out[0:3];
wire signed [WIDTH-1:0] cordic_y_out[0:3];
wire signed [WIDTH:0] cordic_z_out[0:3];
reg signed [WIDTH-1:0] norm_a0;
reg signed [WIDTH:0] theta_1;
reg signed [WIDTH-1:0] a01_exp_a00_phi_re;
reg signed [WIDTH-1:0] a01_exp_a00_phi_im;
reg signed [WIDTH-1:0] a11_exp_a10_phi_re;
reg signed [WIDTH-1:0] a11_exp_a10_phi_im;
reg signed [WIDTH-1:0] cos_theta_1;
reg signed [WIDTH-1:0] sin_theta_1;
reg signed [WIDTH-1:0] g00_re;
reg signed [WIDTH-1:0] g00_im;
reg signed [WIDTH-1:0] g01_re;
reg signed [WIDTH-1:0] g01_im;
reg signed [WIDTH-1:0] g10_re;  
reg signed [WIDTH-1:0] g10_im;  
reg signed [WIDTH-1:0] g11_re;  
reg signed [WIDTH-1:0] g11_im;
//===============================================================
// cordic module instance
cordic u1(
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (mode[0]),
    .x_input    (cordic_x[0]), 
    .y_input    (cordic_y[0]), 
    .z_input    (initial_angle[0]),  
    .x_output   (cordic_x_out[0]), 
    .y_output   (cordic_y_out[0]), 
    .z_output   (cordic_z_out[0])
);
cordic u2(
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (mode[1]),
    .x_input    (cordic_x[1]), 
    .y_input    (cordic_y[1]), 
    .z_input    (initial_angle[1]), 
    .x_output   (cordic_x_out[1]), 
    .y_output   (cordic_y_out[1]), 
    .z_output   (cordic_z_out[1])
);

cordic u3(
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (mode[2]),
    .x_input    (cordic_x[2]), 
    .y_input    (cordic_y[2]), 
    .z_input    (initial_angle[2]),  
    .x_output   (cordic_x_out[2]), 
    .y_output   (cordic_y_out[2]), 
    .z_output   (cordic_z_out[2])
);

cordic u4(
    .clk        (clk),
    .rst_n      (rst_n),
    .mode       (mode[3]),
    .x_input    (cordic_x[3]), 
    .y_input    (cordic_y[3]), 
    .z_input    (initial_angle[3]),  
    .x_output   (cordic_x_out[3]), 
    .y_output   (cordic_y_out[3]), 
    .z_output   (cordic_z_out[3])
);
//===============================================================
// send value to cordic
always @(*) begin
    if (c_state == S2) begin
        cordic_x[0] = a00_re;
        cordic_y[0] = a00_im;
        initial_angle[0] = 0;
        mode[0] = 1'b0;
    end
    else if (c_state == S4) begin
        cordic_x[0] = a01_re;
        cordic_y[0] = a01_im;
        initial_angle[0] = -a00_phi;
        mode[0] = 1'b1;
    end
    else if (c_state == S5) begin
        cordic_x[0] = cos_theta_1;
        cordic_y[0] = 0;
        initial_angle[0] = -a00_phi;
        mode[0] = 1'b1;
    end
    else begin
        cordic_x[0] = 0;
        cordic_y[0] = 0;
        initial_angle[0] = 0;
        mode[0] = 0;
    end
end

always @(*) begin
    if (c_state == S2) begin
        cordic_x[1] = a10_re;
        cordic_y[1] = a10_im;
        initial_angle[1] = 0;
        mode[1] = 1'b0;

    end
    else if (c_state == S4) begin
        cordic_x[1] = a11_re;
        cordic_y[1] = a11_im;
        initial_angle[1] = -a10_phi;
        mode[1] = 1'b1;
    end
    else if (c_state == S5) begin
        cordic_x[1] = sin_theta_1;
        cordic_y[1] = 0;
        initial_angle[1] = -a00_phi;
        mode[1] = 1'b1;
    end
    else begin
        cordic_x[1] = 0;
        cordic_y[1] = 0;
        initial_angle[1] = 0;
        mode[1] = 0;
    end
end

always @(*) begin
    if (c_state == S3) begin
        cordic_x[2] = norm_a00;
        cordic_y[2] = norm_a10;
        initial_angle[2] = 0;
        mode[2] = 1'b0;
    end
    else if (c_state == S4) begin
        cordic_x[2] = 256;
        cordic_y[2] = 0;
        initial_angle[2] = -theta_1;
        mode[2] = 1'b1;
    end
    else if (c_state == S5) begin
        cordic_x[2] = a01_exp_a00_phi_re;
        cordic_y[2] = a11_exp_a10_phi_re;
        initial_angle[2] = -theta_1; 
        mode[2] = 1'b1;
    end
    else if (c_state == S6) begin
        cordic_x[2] = -sin_theta_1;
        cordic_y[2] = 0;
        initial_angle[2] = -a10_phi; 
        mode[2] = 1'b1;
    end
    else begin
        cordic_x[2] = 0;
        cordic_y[2] = 0;
        initial_angle[2] = 0;
        mode[2] = 1'b0;
    end
end

always @(*) begin
    if (c_state == S5) begin
        cordic_x[3] = a01_exp_a00_phi_im;
        cordic_y[3] = a11_exp_a10_phi_im;
        initial_angle[3] = -theta_1;
        mode[3] = 1'b1;
    end
    else if (c_state == S6) begin
        cordic_x[3] = cos_theta_1;
        cordic_y[3] = 0;
        initial_angle[3] = -a10_phi; 
        mode[3] = 1'b1;
    end
    else begin
        cordic_x[3] = 0;
        cordic_y[3] = 0;
        initial_angle[3] = 0;
        mode[3] = 1'b0;
    end
end
//===============================================================
//save norm_a00 and norm_a10 for calculate norm_a0
always @(posedge clk) begin
    if (c_state == S2) begin
        norm_a00 <= cordic_x_out[0];
        a00_phi <= cordic_z_out[0];
    end
    else begin
        norm_a00 <= norm_a00;
        a00_phi <= a00_phi;
    end
end

always @(posedge clk) begin
    if (c_state == S2) begin
        norm_a10 <= cordic_x_out[1];
        a10_phi <= cordic_z_out[1];
    end
    else begin
        norm_a10 <= norm_a10;
        a10_phi <= a10_phi;
    end
end
//===================================================================calculate norm a0===================================================================//

// save norm_a0 and theta_1 for next calculation
always @(posedge clk) begin
    if (c_state == S3) begin
        r00_re <= cordic_x_out[2];
        r10_re <= cordic_y_out[2];
        theta_1 <= cordic_z_out[2];
    end
    else begin
        r00_re <= r00_re;
        r10_re <= r10_re;
        theta_1 <= theta_1;
    end

end
//===============================================================
always@(posedge clk) begin
    if (c_state == S4) begin
        a01_exp_a00_phi_re = cordic_x_out[0];
        a01_exp_a00_phi_im = cordic_y_out[0];
    end
    else begin
        a01_exp_a00_phi_re = a01_exp_a00_phi_re;
        a01_exp_a00_phi_im = a01_exp_a00_phi_im;
    end
end

always@(posedge clk) begin
    if (c_state == S4) begin
        a11_exp_a10_phi_re = cordic_x_out[1];
        a11_exp_a10_phi_im = cordic_y_out[1];
    end
    else begin
        a11_exp_a10_phi_re = a11_exp_a10_phi_re;
        a11_exp_a10_phi_im = a11_exp_a10_phi_im;
    end
end
//===============================================================
always @(posedge clk) begin
    if (c_state == S5) begin
        r01_re = cordic_x_out[2];
        r01_im = cordic_x_out[3];
        r11_re = cordic_y_out[2];
        r11_im = cordic_y_out[3];
    end
    else begin
        r01_re = r01_re;
        r01_im = r01_im;
        r11_re = r11_re;
        r11_im = r11_im;
    end
end
//===============================================================
always @(posedge clk) begin
    if(c_state == S4) begin
        cos_theta_1 <= cordic_x_out[2];
        sin_theta_1 <= cordic_y_out[2];
    end
    else begin
        cos_theta_1 <= cos_theta_1;
        sin_theta_1 <= sin_theta_1;
    end
end
//===============================================================
always @(posedge clk) begin
    if (c_state == S5) begin
        g00_re <= cordic_x_out[0];
        g00_im <= cordic_y_out[0];
        g10_re <= cordic_x_out[1];
        g10_im <= cordic_y_out[1];
    end
    else begin
        g00_re <= g00_re;
        g00_im <= g00_im;
        g10_re <= g10_re;
        g10_im <= g10_im;
    end
end
always @(posedge clk) begin
    if (c_state == S6) begin
        g01_re <= cordic_x_out[2];
        g01_im <= cordic_y_out[2];
        g11_re <= cordic_x_out[3];
        g11_im <= cordic_y_out[3];
    end
    else begin
        g01_re <= g01_re;
        g01_im <= g01_im;
        g11_re <= g11_re;
        g11_im <= g11_im;
    end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_valid <= 0;
    end
    else begin
        if (c_state == S6 && counter == 14) begin
            out_valid <= 1;
        end
        else begin
            out_valid <= out_valid;
        end
    end
end

//===============================================================
//transpose
always @(*) begin
    q_H_00_re = g00_re;
    q_H_00_im = g00_im;
    q_H_01_re = g01_re;
    q_H_01_im = g01_im;
    q_H_10_re = g10_re;
    q_H_10_im = g10_im;
    q_H_11_re = g11_re;
    q_H_11_im = g11_im;
end

endmodule
