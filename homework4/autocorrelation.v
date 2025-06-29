`include "conjugate.v"
`include "norm.v"
`include "shift.v"
`include "square.v"

module autocorrelation #(
    parameter width = 16, // fixed point length
              M = 5,
              scaling = 8 
) (
    input                           clk,
    input                           rst_n,
    input       signed  [width-1:0] data_in_re,
    input       signed  [width-1:0] data_in_im,
    input                           data_in_en,
    output reg  signed  [width-1:0] data_out_re,
    output reg  signed  [width-1:0] data_out_im,
    output reg                      data_out_en,
    output reg          [3:0]       peak_point,
    output reg                      finish // end of compare (find peak point finish)
);
wire    signed  [width-1:0] shift_out_re;    // delay buffer out real part
wire    signed  [width-1:0] shift_out_im;    // delay buffer out image part
reg     signed  [width-1:0] data_re;         // input data real part
reg     signed  [width-1:0] data_im;         // input data image part
reg             [6:0]       counter;         // count for input
reg                         data_en;         //  data ready
reg     signed  [width-1:0] phi_d_re [0:15]; // phi_d0 ~ phi_d15 (real)
reg     signed  [width-1:0] phi_d_im [0:15]; // phi_d0 ~ phi_d15 (image)
reg             [width-1:0] p_d [0:15];      // p_d0 ~ p_d15
wire    signed  [width-1:0] phi_d_con_re;    // phi_d calculator real part
wire    signed  [width-1:0] phi_d_con_im;    // phi_d calculator image part
wire            [width-1:0] norm;            // p_d calculator
reg             [width-1:0] gamma_d [0:15];  // gammad0 ~ gammad15
reg                         valid;            // prevent the d1_en go high at first counter == 0
reg             [4:0]       boundary;




always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        data_en <= 1'b0;
    else
        data_en <= data_in_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_re <= $signed({width{1'b0}});
        data_im <= $signed({width{1'b0}});
    end
    else begin
        data_re <= data_in_re;
        data_im <= data_in_im;
    end
end

shift_register #(.width(width)) u1(
    .clk            (clk),
    .rst_n          (rst_n),
    .data_re        (data_re),
    .data_im        (data_im),
    .shift_out_re   (shift_out_re),
    .shift_out_im   (shift_out_im)
);

conjugate #(.width(width)) u2(
    .a_re   (shift_out_re),
    .a_im   (shift_out_im),
    .b_re   (data_re),
    .b_im   (data_im),
    .c_re   (phi_d_con_re),
    .c_im   (phi_d_con_im)
);

norm #(.width(width)) norm_u1(
    .a_re(data_re),
    .a_im(data_im),
    .out(norm)
);

//counter from 0 ~ 79 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
    end
    else if(counter == 79) begin
        counter <= 0;
    end
    else begin
        counter <= (data_en)? counter + 1 : counter;
    end    
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n)
        valid <= 0;
    else        
        valid <= (counter == 79)? 1'b1 : valid; 
end
//=========================================================calaulate phi_d0=========================================================//

reg     signed  [width-1:0] phi_d0_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d0_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d0_group_re;
reg     signed  [width-1:0] phi_d0_group_im;
reg             [2:0]       d0_m;
reg             [1:0]       d0_group_num;
reg                         d0_group_en;
reg                         d0_en;



//calculate phi_d0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[0] <= 0;
        phi_d_im[0] <= 0;
    end
    else if (counter >= 64 && counter <= 79) begin
        phi_d_re[0] <= phi_d_con_re + phi_d_re[0];
        phi_d_im[0] <= phi_d_con_im + phi_d_im[0];
    end
    else begin
        phi_d_re[0] <= phi_d_re[0];
        phi_d_im[0] <= phi_d_im[0];
    end
end
// flag when phi_d0[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d0_en <= 0;
    end
    else
        d0_en <= (counter == 79)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d0_m <= 0;
    end
    else begin
        if (d0_m == M-1) begin
            d0_m <= (d0_en)? 0 : d0_m;
        end
        else begin
           d0_m <= (d0_en)? d0_m + 1 : d0_m;
        end
    end
end
//record phi_d0
integer  i ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d0_re_temp[i] <= 0;
            phi_d0_im_temp[i] <= 0;
        end
    end
    else begin
        if (d0_en) begin
            if (d0_m == 0) begin
                phi_d0_re_temp[d0_m] <=  phi_d_re[0] - phi_d0_re_temp[M-1]; 
                phi_d0_im_temp[d0_m] <=  phi_d_im[0] - phi_d0_im_temp[M-1]; 
            end
            else begin
                phi_d0_re_temp[d0_m] <=  phi_d_re[0] - phi_d0_re_temp[d0_m - 1]; 
                phi_d0_im_temp[d0_m] <=  phi_d_im[0] - phi_d0_im_temp[d0_m - 1]; 
            end
        end
        else begin
            phi_d0_re_temp[d0_m] <= phi_d0_re_temp[d0_m];
            phi_d0_im_temp[d0_m] <= phi_d0_im_temp[d0_m];
        end
    end

end
// count group for phi_d0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d0_group_en <= 0;
    end
    else
        d0_group_en <= (d0_m == 4 && counter == 79)? 1'b1 : d0_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d0_group_num <= 0;
    end
    else begin
        if (d0_m == 4 && d0_en) 
            d0_group_num <= d0_group_num + 1; 
        else
            d0_group_num <= d0_group_num;
    end
end
// calculate next group phi_d0
always @(posedge clk) begin
    if (d0_group_en && d0_en) begin
        if (d0_group_num == 0) begin
            phi_d0_group_re <= phi_d_re[0];
            phi_d0_group_im <= phi_d_im[0];
        end
        else begin
            phi_d0_group_re <= phi_d_re[0] - phi_d0_re_temp[d0_m];
            phi_d0_group_im <= phi_d_im[0] - phi_d0_im_temp[d0_m];
        end
    end
    else begin
        phi_d0_group_re <= phi_d0_group_re;
        phi_d0_group_im <= phi_d0_group_im;
    end
end

//=========================================================calaulate p_d0=========================================================//
reg     [width-1:0] p_d0_temp [M-1:0];
reg     [width-1:0] p_d0_group;
//calculate p_d0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[0] <= 0;
    else begin
        if (counter >= 64 && counter <= 79) begin
            p_d[0] <= norm + p_d[0];
        end
        else begin
            p_d[0] <= p_d[0];
        end
    end
end
//record p_d0
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d0_temp[0] <= {width{1'b0}};
        p_d0_temp[1] <= {width{1'b0}};
        p_d0_temp[2] <= {width{1'b0}};
        p_d0_temp[3] <= {width{1'b0}};
        p_d0_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d0_en) begin
            if (d0_m == 0) begin
                p_d0_temp[d0_m] <=  p_d[0] - p_d0_temp[M-1]; 
            end
            else begin
                p_d0_temp[d0_m] <=  p_d[0] - p_d0_temp[d0_m - 1]; 
            end
        end
        else begin
            p_d0_temp[d0_m] <= p_d0_temp[d0_m];
        end
    end
end

// calculate next group p_d0
always @(posedge clk) begin
    if (d0_group_en && d0_en) begin
        if (d0_group_num == 0) begin
            p_d0_group <= p_d[0];
        end
        else begin
            p_d0_group <= p_d[0] - p_d0_temp[d0_m];
        end
    end
    else begin
        p_d0_group <= p_d0_group;
    end
end
// //=========================================================calaulate gamma_d0=========================================================//
reg         [width*2-1:0] phi_d0_norm;
reg         [width*2-1:0] p_d0_sqr;
wire signed [width*2-1:0] phi_d0_norm_re;
wire signed [width*2-1:0] phi_d0_norm_im;
wire        [width*2-1:0] p_d0_sqr_in;
reg                       d0_value_en; // tell gamma_d0 that p_d0 and phi_d0 is ready
// calaulate phi_d norm
assign phi_d0_norm_re = phi_d0_group_re;
assign phi_d0_norm_im = phi_d0_group_im;
always @(*) begin
        phi_d0_norm <= (phi_d0_norm_re * phi_d0_norm_re + phi_d0_norm_im * phi_d0_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d0_sqr_in = p_d0_group;
always @(*) begin
    p_d0_sqr <= (p_d0_sqr_in * p_d0_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d0_value_en <= 0;
    else
        d0_value_en <= (d0_group_en && d0_en)? d0_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[0] <= 0;
    end
    else begin
        if (d0_value_en) 
            gamma_d[0] <= (phi_d0_norm <<< scaling) / p_d0_sqr;
        else
            gamma_d[0] <= gamma_d[0];
    end
end

//=========================================================calaulate phi_d1=========================================================//

reg     signed  [width-1:0] phi_d1_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d1_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d1_group_re;
reg     signed  [width-1:0] phi_d1_group_im;
reg             [2:0]       d1_m;
reg             [1:0]       d1_group_num;
reg                         d1_group_en;
reg                         d1_en;



//calculate phi_d1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[1] <= 16'b0;
        phi_d_im[1] <= 16'b0;
    end
    else if ((counter >= 65 && counter <= 79) || (counter == 0 && valid)) begin
        phi_d_re[1] <= phi_d_con_re + phi_d_re[1];
        phi_d_im[1] <= phi_d_con_im + phi_d_im[1];
    end
    else begin
        phi_d_re[1] <= phi_d_re[1];
        phi_d_im[1] <= phi_d_im[1];
    end
end
// flag when phi_d1[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d1_en <= 0;
    end
    else
        d1_en <= (counter == 0 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d1_m <= 0;
    end
    else begin
        if (d1_m == M-1) begin
            d1_m <= (d1_en)? 0 : d1_m;
        end
        else begin
           d1_m <= (d1_en)? d1_m + 1 : d1_m;
        end
    end
end
//record phi_d1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d1_re_temp[i] <= 0;
            phi_d1_im_temp[i] <= 0;
        end
    end
    else begin
        if (d1_en) begin
            if (d1_m == 0) begin
                phi_d1_re_temp[d1_m] <=  phi_d_re[1]; 
                phi_d1_im_temp[d1_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d1_re_temp[d1_m] <=  phi_d_re[1] - phi_d1_re_temp[d1_m - 1]; 
                phi_d1_im_temp[d1_m] <=  phi_d_im[1] - phi_d1_im_temp[d1_m - 1]; 
            end
        end
        else begin
            phi_d1_re_temp[d1_m] <= phi_d1_re_temp[d1_m];
            phi_d1_im_temp[d1_m] <= phi_d1_im_temp[d1_m];
        end
    end

end
// count group for phi_d1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d1_group_en <= 0;
    end
    else
        d1_group_en <= (d1_m == 4 && counter == 79)? 1'b1 : d1_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d1_group_num <= 0;
    end
    else begin
        if (d1_m == 4 && d1_en) 
            d1_group_num <= d1_group_num + 1; 
        else
            d1_group_num <= d1_group_num;
    end
end
// calculate next group phi_d1
always @(posedge clk) begin
    if (d1_group_en && d1_en) begin
        if (d1_group_num == 0) begin
            phi_d1_group_re <= phi_d_re[1];
            phi_d1_group_im <= phi_d_im[1];
        end
        else begin
            phi_d1_group_re <= phi_d_re[1] - phi_d1_re_temp[d1_m];
            phi_d1_group_im <= phi_d_im[1] - phi_d1_im_temp[d1_m];
        end
    end
    else begin
        phi_d1_group_re <= phi_d1_group_re;
        phi_d1_group_im <= phi_d1_group_im;
    end
end

//=========================================================calaulate p_d1=========================================================//
reg     [width-1:0] p_d1_temp [M-1:0];
reg     [width-1:0] p_d1_group;
//calculate p_d1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[1] <= 0;
    else begin
        if ((counter >= 65 && counter <= 79) || (counter == 0 && valid)) begin
            p_d[1] <= norm + p_d[1];
        end
        else begin
            p_d[1] <= p_d[1];
        end
    end
end
//record p_d1
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d1_temp[0] <= {width{1'b0}};
        p_d1_temp[1] <= {width{1'b0}};
        p_d1_temp[2] <= {width{1'b0}};
        p_d1_temp[3] <= {width{1'b0}};
        p_d1_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d1_en) begin
            if (d1_m == 0) begin
                p_d1_temp[d1_m] <=  p_d[1]; 
            end
            else begin
                p_d1_temp[d1_m] <=  p_d[1] - p_d1_temp[d1_m - 1]; 
            end
        end
        else begin
            p_d1_temp[d1_m] <= p_d1_temp[d1_m];
        end
    end
end

// calculate next group p_d1
always @(posedge clk) begin
    if (d1_group_en && d1_en) begin
        if (d1_group_num == 0) begin
            p_d1_group <= p_d[1];
        end
        else begin
            p_d1_group <= p_d[1] - p_d1_temp[d1_m];
        end
    end
    else begin
        p_d1_group <= p_d1_group;
    end
end
// //=========================================================calaulate gamma_d1=========================================================//
reg [width*2-1:0] phi_d1_norm;
reg [width*2-1:0] p_d1_sqr;
wire [width*2-1:0] phi_d1_norm_re;
wire [width*2-1:0] phi_d1_norm_im;
wire [width*2-1:0] p_d1_sqr_in;
reg d1_value_en; // tell gamma_d1 that p_d1 and phi_d1 is ready

// calaulate phi_d norm
assign phi_d1_norm_re = phi_d1_group_re;
assign phi_d1_norm_im = phi_d1_group_im;
always @(*) begin
        phi_d1_norm <= (phi_d1_norm_re * phi_d1_norm_re + phi_d1_norm_im * phi_d1_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d1_sqr_in = p_d1_group;
always @(*) begin
    p_d1_sqr <= (p_d1_sqr_in * p_d1_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d1_value_en <= 0;
    else
        d1_value_en <= (d1_group_en && d1_en)? d1_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[1] <= 0;
    end
    else begin
        if (d1_value_en) 
            gamma_d[1] <= (phi_d1_norm <<< scaling) / p_d1_sqr;
        else
            gamma_d[1] <= gamma_d[1];
    end
end

//=========================================================calaulate phi_d2=========================================================//

reg     signed  [width-1:0] phi_d2_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d2_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d2_group_re;
reg     signed  [width-1:0] phi_d2_group_im;
reg             [2:0]       d2_m;
reg             [1:0]       d2_group_num;
reg                         d2_group_en;
reg                         d2_en;



//calculate phi_d2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[2] <= 0;
        phi_d_im[2] <= 0;
    end
    else if ((counter >= 66 && counter <= 79) || counter == 0 || counter == 1) begin
        phi_d_re[2] <= phi_d_con_re + phi_d_re[2];
        phi_d_im[2] <= phi_d_con_im + phi_d_im[2];
    end
    else begin
        phi_d_re[2] <= phi_d_re[2];
        phi_d_im[2] <= phi_d_im[2];
    end
end
// flag when phi_d2[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_en <= 0;
    end
    else
        d2_en <= (counter == 1 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_m <= 0;
    end
    else begin
        if (d2_m == M-1) begin
            d2_m <= (d2_en)? 0 : d2_m;
        end
        else begin
           d2_m <= (d2_en)? d2_m + 1 : d2_m;
        end
    end
end
//record phi_d2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d2_re_temp[i] <= 0;
            phi_d2_im_temp[i] <= 0;
        end
    end
    else begin
        if (d2_en) begin
            if (d2_m == 0) begin
                phi_d2_re_temp[d2_m] <=  phi_d_re[1]; 
                phi_d2_im_temp[d2_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d2_re_temp[d2_m] <=  phi_d_re[1] - phi_d2_re_temp[d2_m - 1]; 
                phi_d2_im_temp[d2_m] <=  phi_d_im[1] - phi_d2_im_temp[d2_m - 1]; 
            end
        end
        else begin
            phi_d2_re_temp[d2_m] <= phi_d2_re_temp[d2_m];
            phi_d2_im_temp[d2_m] <= phi_d2_im_temp[d2_m];
        end
    end

end
// count group for phi_d2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_group_en <= 0;
    end
    else
        d2_group_en <= (d2_m == 4 && counter == 79)? 1'b1 : d2_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_group_num <= 0;
    end
    else begin
        if (d2_m == 4 && d2_en) 
            d2_group_num <= d2_group_num + 1; 
        else
            d2_group_num <= d2_group_num;
    end
end
// calculate next group phi_d2
always @(posedge clk) begin
    if (d2_group_en && d2_en) begin
        if (d2_group_num == 0) begin
            phi_d2_group_re <= phi_d_re[2];
            phi_d2_group_im <= phi_d_im[2];
        end
        else begin
            phi_d2_group_re <= phi_d_re[2] - phi_d2_re_temp[d2_m];
            phi_d2_group_im <= phi_d_im[2] - phi_d2_im_temp[d2_m];
        end
    end
    else begin
        phi_d2_group_re <= phi_d2_group_re;
        phi_d2_group_im <= phi_d2_group_im;
    end
end

//=========================================================calaulate p_d2=========================================================//
reg     [width-1:0] p_d2_temp [M-1:0];
reg     [width-1:0] p_d2_group;
//calculate p_d2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[2] <= 0;
    else begin
        if ((counter >= 66 && counter <= 79) || (counter == 0 || counter == 1) && valid) begin
            p_d[2] <= norm + p_d[2];
        end
        else begin
            p_d[2] <= p_d[2];
        end
    end
end
//record p_d2
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d2_temp[0] <= {width{1'b0}};
        p_d2_temp[1] <= {width{1'b0}};
        p_d2_temp[2] <= {width{1'b0}};
        p_d2_temp[3] <= {width{1'b0}};
        p_d2_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d2_en) begin
            if (d2_m == 0) begin
                p_d2_temp[d2_m] <=  p_d[2]; 
            end
            else begin
                p_d2_temp[d2_m] <=  p_d[2] - p_d2_temp[d2_m - 1]; 
            end
        end
        else begin
            p_d2_temp[d2_m] <= p_d2_temp[d2_m];
        end
    end
end

// calculate next group p_d2
always @(posedge clk) begin
    if (d2_group_en && d2_en) begin
        if (d2_group_num == 0) begin
            p_d2_group <= p_d[2];
        end
        else begin
            p_d2_group <= p_d[2] - p_d2_temp[d2_m];
        end
    end
    else begin
        p_d2_group <= p_d2_group;
    end
end
// //=========================================================calaulate gamma_d2=========================================================//
reg [width*2-1:0] phi_d2_norm;
reg [width*2-1:0] p_d2_sqr;
wire [width*2-1:0] phi_d2_norm_re;
wire [width*2-1:0] phi_d2_norm_im;
wire [width*2-1:0] p_d2_sqr_in;
reg d2_value_en; // tell gamma_d2 that p_d2 and phi_d2 is ready

// calaulate phi_d norm
assign phi_d2_norm_re = phi_d2_group_re;
assign phi_d2_norm_im = phi_d2_group_im;
always @(*) begin
        phi_d2_norm <= (phi_d2_norm_re * phi_d2_norm_re + phi_d2_norm_im * phi_d2_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d2_sqr_in = p_d2_group;
always @(*) begin
    p_d2_sqr <= (p_d2_sqr_in * p_d2_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d2_value_en <= 0;
    else
        d2_value_en <= (d2_group_en && d2_en)? d2_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[2] <= 0;
    end
    else begin
        if (d2_value_en) 
            gamma_d[2] <= (phi_d2_norm <<< scaling) / p_d2_sqr;
        else
            gamma_d[2] <= gamma_d[2];
    end
end

//=========================================================calaulate phi_d3=========================================================//

reg     signed  [width-1:0] phi_d3_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d3_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d3_group_re;
reg     signed  [width-1:0] phi_d3_group_im;
reg             [2:0]       d3_m;
reg             [1:0]       d3_group_num;
reg                         d3_group_en;
reg                         d3_en;



//calculate phi_d3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[3] <= 0;
        phi_d_im[3] <= 0;
    end
    else if ((counter >= 67 && counter <= 79) || (counter >= 0 && counter <= 2)) begin
        phi_d_re[3] <= phi_d_con_re + phi_d_re[3];
        phi_d_im[3] <= phi_d_con_im + phi_d_im[3];
    end
    else begin
        phi_d_re[3] <= phi_d_re[3];
        phi_d_im[3] <= phi_d_im[3];
    end
end
// flag when phi_d3[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d3_en <= 0;
    end
    else
        d3_en <= (counter == 2 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d3_m <= 0;
    end
    else begin
        if (d3_m == M-1) begin
            d3_m <= (d3_en)? 0 : d3_m;
        end
        else begin
           d3_m <= (d3_en)? d3_m + 1 : d3_m;
        end
    end
end
//record phi_d3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d3_re_temp[i] <= 0;
            phi_d3_im_temp[i] <= 0;
        end
    end
    else begin
        if (d3_en) begin
            if (d3_m == 0) begin
                phi_d3_re_temp[d3_m] <=  phi_d_re[1]; 
                phi_d3_im_temp[d3_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d3_re_temp[d3_m] <=  phi_d_re[1] - phi_d3_re_temp[d3_m - 1]; 
                phi_d3_im_temp[d3_m] <=  phi_d_im[1] - phi_d3_im_temp[d3_m - 1]; 
            end
        end
        else begin
            phi_d3_re_temp[d3_m] <= phi_d3_re_temp[d3_m];
            phi_d3_im_temp[d3_m] <= phi_d3_im_temp[d3_m];
        end
    end

end
// count group for phi_d3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d3_group_en <= 0;
    end
    else
        d3_group_en <= (d3_m == 4 && counter == 79)? 1'b1 : d3_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d3_group_num <= 0;
    end
    else begin
        if (d3_m == 4 && d3_en) 
            d3_group_num <= d3_group_num + 1; 
        else
            d3_group_num <= d3_group_num;
    end
end
// calculate next group phi_d3
always @(posedge clk) begin
    if (d3_group_en && d3_en) begin
        if (d3_group_num == 0) begin
            phi_d3_group_re <= phi_d_re[3];
            phi_d3_group_im <= phi_d_im[3];
        end
        else begin
            phi_d3_group_re <= phi_d_re[3] - phi_d3_re_temp[d3_m];
            phi_d3_group_im <= phi_d_im[3] - phi_d3_im_temp[d3_m];
        end
    end
    else begin
        phi_d3_group_re <= phi_d3_group_re;
        phi_d3_group_im <= phi_d3_group_im;
    end
end

//=========================================================calaulate p_d3=========================================================//
reg     [width-1:0] p_d3_temp [M-1:0];
reg     [width-1:0] p_d3_group;
//calculate p_d3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[3] <= 0;
    else begin
        if ((counter >= 67 && counter <= 79) || ((counter >= 0 && counter <= 2)&& valid)) begin
            p_d[3] <= norm + p_d[3];
        end
        else begin
            p_d[3] <= p_d[3];
        end
    end
end
//record p_d3
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d3_temp[0] <= {width{1'b0}};
        p_d3_temp[1] <= {width{1'b0}};
        p_d3_temp[2] <= {width{1'b0}};
        p_d3_temp[3] <= {width{1'b0}};
        p_d3_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d3_en) begin
            if (d3_m == 0) begin
                p_d3_temp[d3_m] <=  p_d[3]; 
            end
            else begin
                p_d3_temp[d3_m] <=  p_d[3] - p_d3_temp[d3_m - 1]; 
            end
        end
        else begin
            p_d3_temp[d3_m] <= p_d3_temp[d3_m];
        end
    end
end

// calculate next group p_d3
always @(posedge clk) begin
    if (d3_group_en && d3_en) begin
        if (d3_group_num == 0) begin
            p_d3_group <= p_d[3];
        end
        else begin
            p_d3_group <= p_d[3] - p_d3_temp[d3_m];
        end
    end
    else begin
        p_d3_group <= p_d3_group;
    end
end
// //=========================================================calaulate gamma_d3=========================================================//
reg [width*2-1:0] phi_d3_norm;
reg [width*2-1:0] p_d3_sqr;
wire [width*2-1:0] phi_d3_norm_re;
wire [width*2-1:0] phi_d3_norm_im;
wire [width*2-1:0] p_d3_sqr_in;
reg d3_value_en; // tell gamma_d3 that p_d3 and phi_d3 is ready

// calaulate phi_d norm
assign phi_d3_norm_re = phi_d3_group_re;
assign phi_d3_norm_im = phi_d3_group_im;
always @(*) begin
        phi_d3_norm <= (phi_d3_norm_re * phi_d3_norm_re + phi_d3_norm_im * phi_d3_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d3_sqr_in = p_d3_group;
always @(*) begin
    p_d3_sqr <= (p_d3_sqr_in * p_d3_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d3_value_en <= 0;
    else
        d3_value_en <= (d3_group_en && d3_en)? d3_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[3] <= 0;
    end
    else begin
        if (d3_value_en) 
            gamma_d[3] <= (phi_d3_norm <<< scaling) / p_d3_sqr;
        else
            gamma_d[3] <= gamma_d[3];
    end
end

//=========================================================calaulate phi_d4=========================================================//

reg     signed  [width-1:0] phi_d4_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d4_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d4_group_re;
reg     signed  [width-1:0] phi_d4_group_im;
reg             [2:0]       d4_m;
reg             [1:0]       d4_group_num;
reg                         d4_group_en;
reg                         d4_en;



//calculate phi_d4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[4] <= 0;
        phi_d_im[4] <= 0;
    end
    else if ((counter >= 68 && counter <= 79) || (counter >= 0 && counter <= 3)) begin
        phi_d_re[4] <= phi_d_con_re + phi_d_re[4];
        phi_d_im[4] <= phi_d_con_im + phi_d_im[4];
    end
    else begin
        phi_d_re[4] <= phi_d_re[4];
        phi_d_im[4] <= phi_d_im[4];
    end
end
// flag when phi_d4[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d4_en <= 0;
    end
    else
        d4_en <= (counter == 3 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d4_m <= 0;
    end
    else begin
        if (d4_m == M-1) begin
            d4_m <= (d4_en)? 0 : d4_m;
        end
        else begin
           d4_m <= (d4_en)? d4_m + 1 : d4_m;
        end
    end
end
//record phi_d4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d4_re_temp[i] <= 0;
            phi_d4_im_temp[i] <= 0;
        end
    end
    else begin
        if (d4_en) begin
            if (d4_m == 0) begin
                phi_d4_re_temp[d4_m] <=  phi_d_re[1]; 
                phi_d4_im_temp[d4_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d4_re_temp[d4_m] <=  phi_d_re[1] - phi_d4_re_temp[d4_m - 1]; 
                phi_d4_im_temp[d4_m] <=  phi_d_im[1] - phi_d4_im_temp[d4_m - 1]; 
            end
        end
        else begin
            phi_d4_re_temp[d4_m] <= phi_d4_re_temp[d4_m];
            phi_d4_im_temp[d4_m] <= phi_d4_im_temp[d4_m];
        end
    end

end
// count group for phi_d4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d4_group_en <= 0;
    end
    else
        d4_group_en <= (d4_m == 4 && counter == 79)? 1'b1 : d4_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d4_group_num <= 0;
    end
    else begin
        if (d4_m == 4 && d4_en) 
            d4_group_num <= d4_group_num + 1; 
        else
            d4_group_num <= d4_group_num;
    end
end
// calculate next group phi_d4
always @(posedge clk) begin
    if (d4_group_en && d4_en) begin
        if (d4_group_num == 0) begin
            phi_d4_group_re <= phi_d_re[4];
            phi_d4_group_im <= phi_d_im[4];
        end
        else begin
            phi_d4_group_re <= phi_d_re[4] - phi_d4_re_temp[d4_m];
            phi_d4_group_im <= phi_d_im[4] - phi_d4_im_temp[d4_m];
        end
    end
    else begin
        phi_d4_group_re <= phi_d4_group_re;
        phi_d4_group_im <= phi_d4_group_im;
    end
end

//=========================================================calaulate p_d4=========================================================//
reg     [width-1:0] p_d4_temp [M-1:0];
reg     [width-1:0] p_d4_group;
//calculate p_d4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[4] <= 0;
    else begin
        if ((counter >= 68 && counter <= 79) || ((counter >= 0 && counter <= 3)&& valid)) begin
            p_d[4] <= norm + p_d[4];
        end
        else begin
            p_d[4] <= p_d[4];
        end
    end
end
//record p_d4
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d4_temp[0] <= {width{1'b0}};
        p_d4_temp[1] <= {width{1'b0}};
        p_d4_temp[2] <= {width{1'b0}};
        p_d4_temp[3] <= {width{1'b0}};
        p_d4_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d4_en) begin
            if (d4_m == 0) begin
                p_d4_temp[d4_m] <=  p_d[4]; 
            end
            else begin
                p_d4_temp[d4_m] <=  p_d[4] - p_d4_temp[d4_m - 1]; 
            end
        end
        else begin
            p_d4_temp[d4_m] <= p_d4_temp[d4_m];
        end
    end
end

// calculate next group p_d4
always @(posedge clk) begin
    if (d4_group_en && d4_en) begin
        if (d4_group_num == 0) begin
            p_d4_group <= p_d[4];
        end
        else begin
            p_d4_group <= p_d[4] - p_d4_temp[d4_m];
        end
    end
    else begin
        p_d4_group <= p_d4_group;
    end
end
// //=========================================================calaulate gamma_d4=========================================================//
reg [width*2-1:0] phi_d4_norm;
reg [width*2-1:0] p_d4_sqr;
wire [width*2-1:0] phi_d4_norm_re;
wire [width*2-1:0] phi_d4_norm_im;
wire [width*2-1:0] p_d4_sqr_in;
reg d4_value_en; // tell gamma_d4 that p_d4 and phi_d4 is ready

// calaulate phi_d norm
assign phi_d4_norm_re = phi_d4_group_re;
assign phi_d4_norm_im = phi_d4_group_im;
always @(*) begin
        phi_d4_norm <= (phi_d4_norm_re * phi_d4_norm_re + phi_d4_norm_im * phi_d4_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d4_sqr_in = p_d4_group;
always @(*) begin
    p_d4_sqr <= (p_d4_sqr_in * p_d4_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d4_value_en <= 0;
    else
        d4_value_en <= (d4_group_en && d4_en)? d4_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[4] <= 0;
    end
    else begin
        if (d4_value_en) 
            gamma_d[4] <= (phi_d4_norm <<< scaling) / p_d4_sqr;
        else
            gamma_d[4] <= gamma_d[4];
    end
end

//=========================================================calaulate phi_d5=========================================================//

reg     signed  [width-1:0] phi_d5_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d5_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d5_group_re;
reg     signed  [width-1:0] phi_d5_group_im;
reg             [2:0]       d5_m;
reg             [1:0]       d5_group_num;
reg                         d5_group_en;
reg                         d5_en;



//calculate phi_d5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[5] <= 0;
        phi_d_im[5] <= 0;
    end
    else if ((counter >= 69 && counter <= 79) || (counter >= 0 && counter <= 4)) begin
        phi_d_re[5] <= phi_d_con_re + phi_d_re[5];
        phi_d_im[5] <= phi_d_con_im + phi_d_im[5];
    end
    else begin
        phi_d_re[5] <= phi_d_re[5];
        phi_d_im[5] <= phi_d_im[5];
    end
end
// flag when phi_d5[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d5_en <= 0;
    end
    else
        d5_en <= (counter == 4 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d5_m <= 0;
    end
    else begin
        if (d5_m == M-1) begin
            d5_m <= (d5_en)? 0 : d5_m;
        end
        else begin
           d5_m <= (d5_en)? d5_m + 1 : d5_m;
        end
    end
end
//record phi_d5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d5_re_temp[i] <= 0;
            phi_d5_im_temp[i] <= 0;
        end
    end
    else begin
        if (d5_en) begin
            if (d5_m == 0) begin
                phi_d5_re_temp[d5_m] <=  phi_d_re[1]; 
                phi_d5_im_temp[d5_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d5_re_temp[d5_m] <=  phi_d_re[1] - phi_d5_re_temp[d5_m - 1]; 
                phi_d5_im_temp[d5_m] <=  phi_d_im[1] - phi_d5_im_temp[d5_m - 1]; 
            end
        end
        else begin
            phi_d5_re_temp[d5_m] <= phi_d5_re_temp[d5_m];
            phi_d5_im_temp[d5_m] <= phi_d5_im_temp[d5_m];
        end
    end

end
// count group for phi_d5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d5_group_en <= 0;
    end
    else
        d5_group_en <= (d5_m == 4 && counter == 79)? 1'b1 : d5_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d5_group_num <= 0;
    end
    else begin
        if (d5_m == 4 && d5_en) 
            d5_group_num <= d5_group_num + 1; 
        else
            d5_group_num <= d5_group_num;
    end
end
// calculate next group phi_d5
always @(posedge clk) begin
    if (d5_group_en && d5_en) begin
        if (d5_group_num == 0) begin
            phi_d5_group_re <= phi_d_re[5];
            phi_d5_group_im <= phi_d_im[5];
        end
        else begin
            phi_d5_group_re <= phi_d_re[5] - phi_d5_re_temp[d5_m];
            phi_d5_group_im <= phi_d_im[5] - phi_d5_im_temp[d5_m];
        end
    end
    else begin
        phi_d5_group_re <= phi_d5_group_re;
        phi_d5_group_im <= phi_d5_group_im;
    end
end

//=========================================================calaulate p_d5=========================================================//
reg     [width-1:0] p_d5_temp [M-1:0];
reg     [width-1:0] p_d5_group;
//calculate p_d5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        p_d[5] <= 0;
    else begin
        if ((counter >= 69 && counter <= 79) || ((counter >= 0 && counter <= 4) && valid)) begin
            p_d[5] <= norm + p_d[5];
        end
        else begin
            p_d[5] <= p_d[5];
        end
    end
end
//record p_d5
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d5_temp[0] <= {width{1'b0}};
        p_d5_temp[1] <= {width{1'b0}};
        p_d5_temp[2] <= {width{1'b0}};
        p_d5_temp[3] <= {width{1'b0}};
        p_d5_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d5_en) begin
            if (d5_m == 0) begin
                p_d5_temp[d5_m] <=  p_d[5]; 
            end
            else begin
                p_d5_temp[d5_m] <=  p_d[5] - p_d5_temp[d5_m - 1]; 
            end
        end
        else begin
            p_d5_temp[d5_m] <= p_d5_temp[d5_m];
        end
    end
end

// calculate next group p_d5
always @(posedge clk) begin
    if (d5_group_en && d5_en) begin
        if (d5_group_num == 0) begin
            p_d5_group <= p_d[5];
        end
        else begin
            p_d5_group <= p_d[5] - p_d5_temp[d5_m];
        end
    end
    else begin
        p_d5_group <= p_d5_group;
    end
end
// //=========================================================calaulate gamma_d5=========================================================//
reg [width*2-1:0] phi_d5_norm;
reg [width*2-1:0] p_d5_sqr;
wire [width*2-1:0] phi_d5_norm_re;
wire [width*2-1:0] phi_d5_norm_im;
wire [width*2-1:0] p_d5_sqr_in;
reg d5_value_en; // tell gamma_d5 that p_d5 and phi_d5 is ready

// calaulate phi_d norm
assign phi_d5_norm_re = phi_d5_group_re;
assign phi_d5_norm_im = phi_d5_group_im;
always @(*) begin
        phi_d5_norm <= (phi_d5_norm_re * phi_d5_norm_re + phi_d5_norm_im * phi_d5_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d5_sqr_in = p_d5_group;
always @(*) begin
    p_d5_sqr <= (p_d5_sqr_in * p_d5_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d5_value_en <= 0;
    else
        d5_value_en <= (d5_group_en && d5_en)? d5_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[5] <= 0;
    end
    else begin
        if (d5_value_en) 
            gamma_d[5] <= (phi_d5_norm <<< scaling) / p_d5_sqr;
        else
            gamma_d[5] <= gamma_d[5];
    end
end

//=========================================================calaulate phi_d6=========================================================//

reg     signed  [width-1:0] phi_d6_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d6_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d6_group_re;
reg     signed  [width-1:0] phi_d6_group_im;
reg             [2:0]       d6_m;
reg             [1:0]       d6_group_num;
reg                         d6_group_en;
reg                         d6_en;



//calculate phi_d6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[6] <= 0;
        phi_d_im[6] <= 0;
    end
    else if ((counter >= 70 && counter <= 79) || (counter >= 0 && counter <= 5)) begin
        phi_d_re[6] <= phi_d_con_re + phi_d_re[6];
        phi_d_im[6] <= phi_d_con_im + phi_d_im[6];
    end
    else begin
        phi_d_re[6] <= phi_d_re[6];
        phi_d_im[6] <= phi_d_im[6];
    end
end
// flag when phi_d6[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d6_en <= 0;
    end
    else
        d6_en <= (counter == 5 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d6_m <= 0;
    end
    else begin
        if (d6_m == M-1) begin
            d6_m <= (d6_en)? 0 : d6_m;
        end
        else begin
           d6_m <= (d6_en)? d6_m + 1 : d6_m;
        end
    end
end
//record phi_d6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d6_re_temp[i] <= 0;
            phi_d6_im_temp[i] <= 0;
        end
    end
    else begin
        if (d6_en) begin
            if (d6_m == 0) begin
                phi_d6_re_temp[d6_m] <=  phi_d_re[1]; 
                phi_d6_im_temp[d6_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d6_re_temp[d6_m] <=  phi_d_re[1] - phi_d6_re_temp[d6_m - 1]; 
                phi_d6_im_temp[d6_m] <=  phi_d_im[1] - phi_d6_im_temp[d6_m - 1]; 
            end
        end
        else begin
            phi_d6_re_temp[d6_m] <= phi_d6_re_temp[d6_m];
            phi_d6_im_temp[d6_m] <= phi_d6_im_temp[d6_m];
        end
    end

end
// count group for phi_d6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d6_group_en <= 0;
    end
    else
        d6_group_en <= (d6_m == 4 && counter == 79)? 1'b1 : d6_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d6_group_num <= 0;
    end
    else begin
        if (d6_m == 4 && d6_en) 
            d6_group_num <= d6_group_num + 1; 
        else
            d6_group_num <= d6_group_num;
    end
end
// calculate next group phi_d6
always @(posedge clk) begin
    if (d6_group_en && d6_en) begin
        if (d6_group_num == 0) begin
            phi_d6_group_re <= phi_d_re[6];
            phi_d6_group_im <= phi_d_im[6];
        end
        else begin
            phi_d6_group_re <= phi_d_re[6] - phi_d6_re_temp[d6_m];
            phi_d6_group_im <= phi_d_im[6] - phi_d6_im_temp[d6_m];
        end
    end
    else begin
        phi_d6_group_re <= phi_d6_group_re;
        phi_d6_group_im <= phi_d6_group_im;
    end
end

//=========================================================calaulate p_d6=========================================================//
reg     [width-1:0] p_d6_temp [M-1:0];
reg     [width-1:0] p_d6_group;
//calculate p_d6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[6] <= 0;
    else begin
        if ((counter >= 70 && counter <= 79) || ((counter >= 0 && counter <= 5) && valid)) begin
             p_d[6] <= norm +  p_d[6];
        end
        else begin
             p_d[6] <=  p_d[6];
        end
    end
end
//record p_d6
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d6_temp[0] <= {width{1'b0}};
        p_d6_temp[1] <= {width{1'b0}};
        p_d6_temp[2] <= {width{1'b0}};
        p_d6_temp[3] <= {width{1'b0}};
        p_d6_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d6_en) begin
            if (d6_m == 0) begin
                p_d6_temp[d6_m] <=   p_d[6]; 
            end
            else begin
                p_d6_temp[d6_m] <=   p_d[6] - p_d6_temp[d6_m - 1]; 
            end
        end
        else begin
            p_d6_temp[d6_m] <= p_d6_temp[d6_m];
        end
    end
end

// calculate next group p_d6
always @(posedge clk) begin
    if (d6_group_en && d6_en) begin
        if (d6_group_num == 0) begin
            p_d6_group <=  p_d[6];
        end
        else begin
            p_d6_group <=  p_d[6] - p_d6_temp[d6_m];
        end
    end
    else begin
        p_d6_group <= p_d6_group;
    end
end
// //=========================================================calaulate gamma_d6=========================================================//
reg [width*2-1:0] phi_d6_norm;
reg [width*2-1:0] p_d6_sqr;
wire [width*2-1:0] phi_d6_norm_re;
wire [width*2-1:0] phi_d6_norm_im;
wire [width*2-1:0] p_d6_sqr_in;
reg d6_value_en; // tell gamma_d6 that p_d6 and phi_d6 is ready

// calaulate phi_d norm
assign phi_d6_norm_re = phi_d6_group_re;
assign phi_d6_norm_im = phi_d6_group_im;
always @(*) begin
        phi_d6_norm <= (phi_d6_norm_re * phi_d6_norm_re + phi_d6_norm_im * phi_d6_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d6_sqr_in = p_d6_group;
always @(*) begin
    p_d6_sqr <= (p_d6_sqr_in * p_d6_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d6_value_en <= 0;
    else
        d6_value_en <= (d6_group_en && d6_en)? d6_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[6] <= 0;
    end
    else begin
        if (d6_value_en) 
            gamma_d[6] <= (phi_d6_norm <<< scaling) / p_d6_sqr;
        else
            gamma_d[6] <= gamma_d[6];
    end
end

//=========================================================calaulate phi_d7=========================================================//

reg     signed  [width-1:0] phi_d7_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d7_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d7_group_re;
reg     signed  [width-1:0] phi_d7_group_im;
reg             [2:0]       d7_m;
reg             [1:0]       d7_group_num;
reg                         d7_group_en;
reg                         d7_en;



//calculate phi_d7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[7] <= 0;
        phi_d_im[7] <= 0;
    end
    else if ((counter >= 71 && counter <= 79) || (counter >= 0 && counter <= 6)) begin
        phi_d_re[7] <= phi_d_con_re + phi_d_re[7];
        phi_d_im[7] <= phi_d_con_im + phi_d_im[7];
    end
    else begin
        phi_d_re[7] <= phi_d_re[7];
        phi_d_im[7] <= phi_d_im[7];
    end
end
// flag when phi_d7[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d7_en <= 0;
    end
    else
        d7_en <= (counter == 6 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d7_m <= 0;
    end
    else begin
        if (d7_m == M-1) begin
            d7_m <= (d7_en)? 0 : d7_m;
        end
        else begin
           d7_m <= (d7_en)? d7_m + 1 : d7_m;
        end
    end
end
//record phi_d7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d7_re_temp[i] <= 0;
            phi_d7_im_temp[i] <= 0;
        end
    end
    else begin
        if (d7_en) begin
            if (d7_m == 0) begin
                phi_d7_re_temp[d7_m] <=  phi_d_re[1]; 
                phi_d7_im_temp[d7_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d7_re_temp[d7_m] <=  phi_d_re[1] - phi_d7_re_temp[d7_m - 1]; 
                phi_d7_im_temp[d7_m] <=  phi_d_im[1] - phi_d7_im_temp[d7_m - 1]; 
            end
        end
        else begin
            phi_d7_re_temp[d7_m] <= phi_d7_re_temp[d7_m];
            phi_d7_im_temp[d7_m] <= phi_d7_im_temp[d7_m];
        end
    end

end
// count group for phi_d7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d7_group_en <= 0;
    end
    else
        d7_group_en <= (d7_m == 4 && counter == 79)? 1'b1 : d7_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d7_group_num <= 0;
    end
    else begin
        if (d7_m == 4 && d7_en) 
            d7_group_num <= d7_group_num + 1; 
        else
            d7_group_num <= d7_group_num;
    end
end
// calculate next group phi_d7
always @(posedge clk) begin
    if (d7_group_en && d7_en) begin
        if (d7_group_num == 0) begin
            phi_d7_group_re <= phi_d_re[7];
            phi_d7_group_im <= phi_d_im[7];
        end
        else begin
            phi_d7_group_re <= phi_d_re[7] - phi_d7_re_temp[d7_m];
            phi_d7_group_im <= phi_d_im[7] - phi_d7_im_temp[d7_m];
        end
    end
    else begin
        phi_d7_group_re <= phi_d7_group_re;
        phi_d7_group_im <= phi_d7_group_im;
    end
end

//=========================================================calaulate p_d7=========================================================//
reg     [width-1:0] p_d7_temp [M-1:0];
reg     [width-1:0] p_d7_group;
//calculate p_d7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[7] <= 0;
    else begin
        if ((counter >= 71 && counter <= 79) || ((counter >= 0 && counter <= 6) && valid)) begin
             p_d[7] <= norm +  p_d[7];
        end
        else begin
             p_d[7] <=  p_d[7];
        end
    end
end
//record p_d7
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d7_temp[0] <= {width{1'b0}};
        p_d7_temp[1] <= {width{1'b0}};
        p_d7_temp[2] <= {width{1'b0}};
        p_d7_temp[3] <= {width{1'b0}};
        p_d7_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d7_en) begin
            if (d7_m == 0) begin
                p_d7_temp[d7_m] <=   p_d[7]; 
            end
            else begin
                p_d7_temp[d7_m] <=   p_d[7] - p_d7_temp[d7_m - 1]; 
            end
        end
        else begin
            p_d7_temp[d7_m] <= p_d7_temp[d7_m];
        end
    end
end

// calculate next group p_d7
always @(posedge clk) begin
    if (d7_group_en && d7_en) begin
        if (d7_group_num == 0) begin
            p_d7_group <=  p_d[7];
        end
        else begin
            p_d7_group <=  p_d[7] - p_d7_temp[d7_m];
        end
    end
    else begin
        p_d7_group <= p_d7_group;
    end
end
// //=========================================================calaulate gamma_d7=========================================================//
reg [width*2-1:0] phi_d7_norm;
reg [width*2-1:0] p_d7_sqr;
wire [width*2-1:0] phi_d7_norm_re;
wire [width*2-1:0] phi_d7_norm_im;
wire [width*2-1:0] p_d7_sqr_in;
reg d7_value_en; // tell gamma_d7 that p_d7 and phi_d7 is ready

// calaulate phi_d norm
assign phi_d7_norm_re = phi_d7_group_re;
assign phi_d7_norm_im = phi_d7_group_im;
always @(*) begin
        phi_d7_norm <= (phi_d7_norm_re * phi_d7_norm_re + phi_d7_norm_im * phi_d7_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d7_sqr_in = p_d7_group;
always @(*) begin
    p_d7_sqr <= (p_d7_sqr_in * p_d7_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d7_value_en <= 0;
    else
        d7_value_en <= (d7_group_en && d7_en)? d7_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[7] <= 0;
    end
    else begin
        if (d7_value_en) 
            gamma_d[7] <= (phi_d7_norm <<< scaling) / p_d7_sqr;
        else
            gamma_d[7] <= gamma_d[7];
    end
end

//=========================================================calaulate phi_d8=========================================================//

reg     signed  [width-1:0] phi_d8_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d8_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d8_group_re;
reg     signed  [width-1:0] phi_d8_group_im;
reg             [2:0]       d8_m;
reg             [1:0]       d8_group_num;
reg                         d8_group_en;
reg                         d8_en;



//calculate phi_d8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[8] <= 0;
        phi_d_im[8] <= 0;
    end
    else if ((counter >= 72 && counter <= 79) || (counter >= 0 && counter <= 7)) begin
        phi_d_re[8] <= phi_d_con_re + phi_d_re[8];
        phi_d_im[8] <= phi_d_con_im + phi_d_im[8];
    end
    else begin
        phi_d_re[8] <= phi_d_re[8];
        phi_d_im[8] <= phi_d_im[8];
    end
end
// flag when phi_d8[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d8_en <= 0;
    end
    else
        d8_en <= (counter == 7 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d8_m <= 0;
    end
    else begin
        if (d8_m == M-1) begin
            d8_m <= (d8_en)? 0 : d8_m;
        end
        else begin
           d8_m <= (d8_en)? d8_m + 1 : d8_m;
        end
    end
end
//record phi_d8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d8_re_temp[i] <= 0;
            phi_d8_im_temp[i] <= 0;
        end
    end
    else begin
        if (d8_en) begin
            if (d8_m == 0) begin
                phi_d8_re_temp[d8_m] <=  phi_d_re[1]; 
                phi_d8_im_temp[d8_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d8_re_temp[d8_m] <=  phi_d_re[1] - phi_d8_re_temp[d8_m - 1]; 
                phi_d8_im_temp[d8_m] <=  phi_d_im[1] - phi_d8_im_temp[d8_m - 1]; 
            end
        end
        else begin
            phi_d8_re_temp[d8_m] <= phi_d8_re_temp[d8_m];
            phi_d8_im_temp[d8_m] <= phi_d8_im_temp[d8_m];
        end
    end

end
// count group for phi_d8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d8_group_en <= 0;
    end
    else
        d8_group_en <= (d8_m == 4 && counter == 79)? 1'b1 : d8_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d8_group_num <= 0;
    end
    else begin
        if (d8_m == 4 && d8_en) 
            d8_group_num <= d8_group_num + 1; 
        else
            d8_group_num <= d8_group_num;
    end
end
// calculate next group phi_d8
always @(posedge clk) begin
    if (d8_group_en && d8_en) begin
        if (d8_group_num == 0) begin
            phi_d8_group_re <= phi_d_re[8];
            phi_d8_group_im <= phi_d_im[8];
        end
        else begin
            phi_d8_group_re <= phi_d_re[8] - phi_d8_re_temp[d8_m];
            phi_d8_group_im <= phi_d_im[8] - phi_d8_im_temp[d8_m];
        end
    end
    else begin
        phi_d8_group_re <= phi_d8_group_re;
        phi_d8_group_im <= phi_d8_group_im;
    end
end

//=========================================================calaulate p_d8=========================================================//
reg     [width-1:0] p_d8_temp [M-1:0];
reg     [width-1:0] p_d8_group;
//calculate p_d8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[8] <= 0;
    else begin
        if ((counter >= 72 && counter <= 79) || ((counter >= 0 && counter <= 7) && valid)) begin
             p_d[8] <= norm +  p_d[8];
        end
        else begin
             p_d[8] <=  p_d[8];
        end
    end
end
//record p_d8
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d8_temp[0] <= {width{1'b0}};
        p_d8_temp[1] <= {width{1'b0}};
        p_d8_temp[2] <= {width{1'b0}};
        p_d8_temp[3] <= {width{1'b0}};
        p_d8_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d8_en) begin
            if (d8_m == 0) begin
                p_d8_temp[d8_m] <=   p_d[8]; 
            end
            else begin
                p_d8_temp[d8_m] <=   p_d[8] - p_d8_temp[d8_m - 1]; 
            end
        end
        else begin
            p_d8_temp[d8_m] <= p_d8_temp[d8_m];
        end
    end
end

// calculate next group p_d8
always @(posedge clk) begin
    if (d8_group_en && d8_en) begin
        if (d8_group_num == 0) begin
            p_d8_group <=  p_d[8];
        end
        else begin
            p_d8_group <=  p_d[8] - p_d8_temp[d8_m];
        end
    end
    else begin
        p_d8_group <= p_d8_group;
    end
end
// //=========================================================calaulate gamma_d8=========================================================//
reg [width*2-1:0] phi_d8_norm;
reg [width*2-1:0] p_d8_sqr;
wire [width*2-1:0] phi_d8_norm_re;
wire [width*2-1:0] phi_d8_norm_im;
wire [width*2-1:0] p_d8_sqr_in;
reg d8_value_en; // tell gamma_d8 that p_d8 and phi_d8 is ready

// calaulate phi_d norm
assign phi_d8_norm_re = phi_d8_group_re;
assign phi_d8_norm_im = phi_d8_group_im;
always @(*) begin
        phi_d8_norm <= (phi_d8_norm_re * phi_d8_norm_re + phi_d8_norm_im * phi_d8_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d8_sqr_in = p_d8_group;
always @(*) begin
    p_d8_sqr <= (p_d8_sqr_in * p_d8_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d8_value_en <= 0;
    else
        d8_value_en <= (d8_group_en && d8_en)? d8_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[8] <= 0;
    end
    else begin
        if (d8_value_en) 
            gamma_d[8] <= (phi_d8_norm <<< scaling) / p_d8_sqr;
        else
            gamma_d[8] <= gamma_d[8];
    end
end

//=========================================================calaulate phi_d9=========================================================//

reg     signed  [width-1:0] phi_d9_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d9_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d9_group_re;
reg     signed  [width-1:0] phi_d9_group_im;
reg             [2:0]       d9_m;
reg             [1:0]       d9_group_num;
reg                         d9_group_en;
reg                         d9_en;



//calculate phi_d9
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[9] <= 0;
        phi_d_im[9] <= 0;
    end
    else if ((counter >= 73 && counter <= 79) || (counter >= 0 && counter <= 8)) begin
        phi_d_re[9] <= phi_d_con_re + phi_d_re[9];
        phi_d_im[9] <= phi_d_con_im + phi_d_im[9];
    end
    else begin
        phi_d_re[9] <= phi_d_re[9];
        phi_d_im[9] <= phi_d_im[9];
    end
end
// flag when phi_d9[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d9_en <= 0;
    end
    else
        d9_en <= (counter == 8 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d9_m <= 0;
    end
    else begin
        if (d9_m == M-1) begin
            d9_m <= (d9_en)? 0 : d9_m;
        end
        else begin
           d9_m <= (d9_en)? d9_m + 1 : d9_m;
        end
    end
end
//record phi_d9
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d9_re_temp[i] <= 0;
            phi_d9_im_temp[i] <= 0;
        end
    end
    else begin
        if (d9_en) begin
            if (d9_m == 0) begin
                phi_d9_re_temp[d9_m] <=  phi_d_re[1]; 
                phi_d9_im_temp[d9_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d9_re_temp[d9_m] <=  phi_d_re[1] - phi_d9_re_temp[d9_m - 1]; 
                phi_d9_im_temp[d9_m] <=  phi_d_im[1] - phi_d9_im_temp[d9_m - 1]; 
            end
        end
        else begin
            phi_d9_re_temp[d9_m] <= phi_d9_re_temp[d9_m];
            phi_d9_im_temp[d9_m] <= phi_d9_im_temp[d9_m];
        end
    end

end
// count group for phi_d9
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d9_group_en <= 0;
    end
    else
        d9_group_en <= (d9_m == 4 && counter == 79)? 1'b1 : d9_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d9_group_num <= 0;
    end
    else begin
        if (d9_m == 4 && d9_en) 
            d9_group_num <= d9_group_num + 1; 
        else
            d9_group_num <= d9_group_num;
    end
end
// calculate next group phi_d9
always @(posedge clk) begin
    if (d9_group_en && d9_en) begin
        if (d9_group_num == 0) begin
            phi_d9_group_re <= phi_d_re[9];
            phi_d9_group_im <= phi_d_im[9];
        end
        else begin
            phi_d9_group_re <= phi_d_re[9] - phi_d9_re_temp[d9_m];
            phi_d9_group_im <= phi_d_im[9] - phi_d9_im_temp[d9_m];
        end
    end
    else begin
        phi_d9_group_re <= phi_d9_group_re;
        phi_d9_group_im <= phi_d9_group_im;
    end
end

//=========================================================calaulate p_d9=========================================================//
reg     [width-1:0] p_d9_temp [M-1:0];
reg     [width-1:0] p_d9_group;
//calculate p_d9
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[9] <= 0;
    else begin
        if ((counter >= 73 && counter <= 79) || ((counter >= 0 && counter <= 8) && valid)) begin
             p_d[9] <= norm +  p_d[9];
        end
        else begin
             p_d[9] <=  p_d[9];
        end
    end
end
//record p_d9
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d9_temp[0] <= {width{1'b0}};
        p_d9_temp[1] <= {width{1'b0}};
        p_d9_temp[2] <= {width{1'b0}};
        p_d9_temp[3] <= {width{1'b0}};
        p_d9_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d9_en) begin
            if (d9_m == 0) begin
                p_d9_temp[d9_m] <=   p_d[9]; 
            end
            else begin
                p_d9_temp[d9_m] <=   p_d[9] - p_d9_temp[d9_m - 1]; 
            end
        end
        else begin
            p_d9_temp[d9_m] <= p_d9_temp[d9_m];
        end
    end
end

// calculate next group p_d9
always @(posedge clk) begin
    if (d9_group_en && d9_en) begin
        if (d9_group_num == 0) begin
            p_d9_group <=  p_d[9];
        end
        else begin
            p_d9_group <=  p_d[9] - p_d9_temp[d9_m];
        end
    end
    else begin
        p_d9_group <= p_d9_group;
    end
end
// //=========================================================calaulate gamma_d9=========================================================//
reg [width*2-1:0] phi_d9_norm;
reg [width*2-1:0] p_d9_sqr;
wire [width*2-1:0] phi_d9_norm_re;
wire [width*2-1:0] phi_d9_norm_im;
wire [width*2-1:0] p_d9_sqr_in;
reg d9_value_en; // tell gamma_d9 that p_d9 and phi_d9 is ready

// calaulate phi_d norm
assign phi_d9_norm_re = phi_d9_group_re;
assign phi_d9_norm_im = phi_d9_group_im;
always @(*) begin
        phi_d9_norm <= (phi_d9_norm_re * phi_d9_norm_re + phi_d9_norm_im * phi_d9_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d9_sqr_in = p_d9_group;
always @(*) begin
    p_d9_sqr <= (p_d9_sqr_in * p_d9_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d9_value_en <= 0;
    else
        d9_value_en <= (d9_group_en && d9_en)? d9_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[9] <= 0;
    end
    else begin
        if (d9_value_en) 
            gamma_d[9] <= (phi_d9_norm <<< scaling) / p_d9_sqr;
        else
            gamma_d[9] <= gamma_d[9];
    end
end

//=========================================================calaulate phi_d10=========================================================//

reg     signed  [width-1:0] phi_d10_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d10_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d10_group_re;
reg     signed  [width-1:0] phi_d10_group_im;
reg             [2:0]       d10_m;
reg             [1:0]       d10_group_num;
reg                         d10_group_en;
reg                         d10_en;



//calculate phi_d10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[10] <= 0;
        phi_d_im[10] <= 0;
    end
    else if ((counter >= 74 && counter <= 79) || (counter >= 0 && counter <= 9)) begin
        phi_d_re[10] <= phi_d_con_re + phi_d_re[10];
        phi_d_im[10] <= phi_d_con_im + phi_d_im[10];
    end
    else begin
        phi_d_re[10] <= phi_d_re[10];
        phi_d_im[10] <= phi_d_im[10];
    end
end
// flag when phi_d10[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d10_en <= 0;
    end
    else
        d10_en <= (counter == 9 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d10_m <= 0;
    end
    else begin
        if (d10_m == M-1) begin
            d10_m <= (d10_en)? 0 : d10_m;
        end
        else begin
           d10_m <= (d10_en)? d10_m + 1 : d10_m;
        end
    end
end
//record phi_d10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d10_re_temp[i] <= 0;
            phi_d10_im_temp[i] <= 0;
        end
    end
    else begin
        if (d10_en) begin
            if (d10_m == 0) begin
                phi_d10_re_temp[d10_m] <=  phi_d_re[1]; 
                phi_d10_im_temp[d10_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d10_re_temp[d10_m] <=  phi_d_re[1] - phi_d10_re_temp[d10_m - 1]; 
                phi_d10_im_temp[d10_m] <=  phi_d_im[1] - phi_d10_im_temp[d10_m - 1]; 
            end
        end
        else begin
            phi_d10_re_temp[d10_m] <= phi_d10_re_temp[d10_m];
            phi_d10_im_temp[d10_m] <= phi_d10_im_temp[d10_m];
        end
    end

end
// count group for phi_d10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d10_group_en <= 0;
    end
    else
        d10_group_en <= (d10_m == 4 && counter == 79)? 1'b1 : d10_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d10_group_num <= 0;
    end
    else begin
        if (d10_m == 4 && d10_en) 
            d10_group_num <= d10_group_num + 1; 
        else
            d10_group_num <= d10_group_num;
    end
end
// calculate next group phi_d10
always @(posedge clk) begin
    if (d10_group_en && d10_en) begin
        if (d10_group_num == 0) begin
            phi_d10_group_re <= phi_d_re[10];
            phi_d10_group_im <= phi_d_im[10];
        end
        else begin
            phi_d10_group_re <= phi_d_re[10] - phi_d10_re_temp[d10_m];
            phi_d10_group_im <= phi_d_im[10] - phi_d10_im_temp[d10_m];
        end
    end
    else begin
        phi_d10_group_re <= phi_d10_group_re;
        phi_d10_group_im <= phi_d10_group_im;
    end
end

//=========================================================calaulate p_d10=========================================================//
reg     [width-1:0] p_d10_temp [M-1:0];
reg     [width-1:0] p_d10_group;
//calculate p_d10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[10] <= 0;
    else begin
        if ((counter >= 74 && counter <= 79) || ((counter >= 0 && counter <= 9) && valid)) begin
             p_d[10] <= norm +  p_d[10];
        end
        else begin
             p_d[10] <=  p_d[10];
        end
    end
end
//record p_d10
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d10_temp[0] <= {width{1'b0}};
        p_d10_temp[1] <= {width{1'b0}};
        p_d10_temp[2] <= {width{1'b0}};
        p_d10_temp[3] <= {width{1'b0}};
        p_d10_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d10_en) begin
            if (d10_m == 0) begin
                p_d10_temp[d10_m] <=   p_d[10]; 
            end
            else begin
                p_d10_temp[d10_m] <=   p_d[10] - p_d10_temp[d10_m - 1]; 
            end
        end
        else begin
            p_d10_temp[d10_m] <= p_d10_temp[d10_m];
        end
    end
end

// calculate next group p_d10
always @(posedge clk) begin
    if (d10_group_en && d10_en) begin
        if (d10_group_num == 0) begin
            p_d10_group <=  p_d[10];
        end
        else begin
            p_d10_group <=  p_d[10] - p_d10_temp[d10_m];
        end
    end
    else begin
        p_d10_group <= p_d10_group;
    end
end
// //=========================================================calaulate gamma_d10=========================================================//
reg [width*2-1:0] phi_d10_norm;
reg [width*2-1:0] p_d10_sqr;
wire [width*2-1:0] phi_d10_norm_re;
wire [width*2-1:0] phi_d10_norm_im;
wire [width*2-1:0] p_d10_sqr_in;
reg d10_value_en; // tell gamma_d10 that p_d10 and phi_d10 is ready

// calaulate phi_d norm
assign phi_d10_norm_re = phi_d10_group_re;
assign phi_d10_norm_im = phi_d10_group_im;
always @(*) begin
        phi_d10_norm <= (phi_d10_norm_re * phi_d10_norm_re + phi_d10_norm_im * phi_d10_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d10_sqr_in = p_d10_group;
always @(*) begin
    p_d10_sqr <= (p_d10_sqr_in * p_d10_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d10_value_en <= 0;
    else
        d10_value_en <= (d10_group_en && d10_en)? d10_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[10] <= 0;
    end
    else begin
        if (d10_value_en) 
            gamma_d[10] <= (phi_d10_norm <<< scaling) / p_d10_sqr;
        else
            gamma_d[10] <= gamma_d[10];
    end
end

//=========================================================calaulate phi_d11=========================================================//

reg     signed  [width-1:0] phi_d11_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d11_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d11_group_re;
reg     signed  [width-1:0] phi_d11_group_im;
reg             [2:0]       d11_m;
reg             [1:0]       d11_group_num;
reg                         d11_group_en;
reg                         d11_en;



//calculate phi_d11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[11] <= 0;
        phi_d_im[11] <= 0;
    end
    else if ((counter >= 75 && counter <= 79) || (counter >= 0 && counter <= 10)) begin
        phi_d_re[11] <= phi_d_con_re + phi_d_re[11];
        phi_d_im[11] <= phi_d_con_im + phi_d_im[11];
    end
    else begin
        phi_d_re[11] <= phi_d_re[11];
        phi_d_im[11] <= phi_d_im[11];
    end
end
// flag when phi_d11[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d11_en <= 0;
    end
    else
        d11_en <= (counter == 10 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d11_m <= 0;
    end
    else begin
        if (d11_m == M-1) begin
            d11_m <= (d11_en)? 0 : d11_m;
        end
        else begin
           d11_m <= (d11_en)? d11_m + 1 : d11_m;
        end
    end
end
//record phi_d11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d11_re_temp[i] <= 0;
            phi_d11_im_temp[i] <= 0;
        end
    end
    else begin
        if (d11_en) begin
            if (d11_m == 0) begin
                phi_d11_re_temp[d11_m] <=  phi_d_re[1]; 
                phi_d11_im_temp[d11_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d11_re_temp[d11_m] <=  phi_d_re[1] - phi_d11_re_temp[d11_m - 1]; 
                phi_d11_im_temp[d11_m] <=  phi_d_im[1] - phi_d11_im_temp[d11_m - 1]; 
            end
        end
        else begin
            phi_d11_re_temp[d11_m] <= phi_d11_re_temp[d11_m];
            phi_d11_im_temp[d11_m] <= phi_d11_im_temp[d11_m];
        end
    end

end
// count group for phi_d11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d11_group_en <= 0;
    end
    else
        d11_group_en <= (d11_m == 4 && counter == 79)? 1'b1 : d11_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d11_group_num <= 0;
    end
    else begin
        if (d11_m == 4 && d11_en) 
            d11_group_num <= d11_group_num + 1; 
        else
            d11_group_num <= d11_group_num;
    end
end
// calculate next group phi_d11
always @(posedge clk) begin
    if (d11_group_en && d11_en) begin
        if (d11_group_num == 0) begin
            phi_d11_group_re <= phi_d_re[11];
            phi_d11_group_im <= phi_d_im[11];
        end
        else begin
            phi_d11_group_re <= phi_d_re[11] - phi_d11_re_temp[d11_m];
            phi_d11_group_im <= phi_d_im[11] - phi_d11_im_temp[d11_m];
        end
    end
    else begin
        phi_d11_group_re <= phi_d11_group_re;
        phi_d11_group_im <= phi_d11_group_im;
    end
end

//=========================================================calaulate p_d11=========================================================//
reg     [width-1:0] p_d11_temp [M-1:0];
reg     [width-1:0] p_d11_group;
//calculate p_d11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[11] <= 0;
    else begin
        if ((counter >= 75 && counter <= 79) ||((counter >= 0 && counter <= 10) && valid)) begin
             p_d[11] <= norm +  p_d[11];
        end
        else begin
             p_d[11] <=  p_d[11];
        end
    end
end
//record p_d11
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d11_temp[0] <= {width{1'b0}};
        p_d11_temp[1] <= {width{1'b0}};
        p_d11_temp[2] <= {width{1'b0}};
        p_d11_temp[3] <= {width{1'b0}};
        p_d11_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d11_en) begin
            if (d11_m == 0) begin
                p_d11_temp[d11_m] <=   p_d[11]; 
            end
            else begin
                p_d11_temp[d11_m] <=   p_d[11] - p_d11_temp[d11_m - 1]; 
            end
        end
        else begin
            p_d11_temp[d11_m] <= p_d11_temp[d11_m];
        end
    end
end

// calculate next group p_d11
always @(posedge clk) begin
    if (d11_group_en && d11_en) begin
        if (d11_group_num == 0) begin
            p_d11_group <=  p_d[11];
        end
        else begin
            p_d11_group <=  p_d[11] - p_d11_temp[d11_m];
        end
    end
    else begin
        p_d11_group <= p_d11_group;
    end
end
// //=========================================================calaulate gamma_d11=========================================================//
reg [width*2-1:0] phi_d11_norm;
reg [width*2-1:0] p_d11_sqr;
wire [width*2-1:0] phi_d11_norm_re;
wire [width*2-1:0] phi_d11_norm_im;
wire [width*2-1:0] p_d11_sqr_in;
reg d11_value_en; // tell gamma_d11 that p_d11 and phi_d11 is ready

// calaulate phi_d norm
assign phi_d11_norm_re = phi_d11_group_re;
assign phi_d11_norm_im = phi_d11_group_im;
always @(*) begin
        phi_d11_norm <= (phi_d11_norm_re * phi_d11_norm_re + phi_d11_norm_im * phi_d11_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d11_sqr_in = p_d11_group;
always @(*) begin
    p_d11_sqr <= (p_d11_sqr_in * p_d11_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d11_value_en <= 0;
    else
        d11_value_en <= (d11_group_en && d11_en)? d11_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[11] <= 0;
    end
    else begin
        if (d11_value_en) 
            gamma_d[11] <= (phi_d11_norm <<< scaling) / p_d11_sqr;
        else
            gamma_d[11] <= gamma_d[11];
    end
end

//=========================================================calaulate phi_d12=========================================================//

reg     signed  [width-1:0] phi_d12_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d12_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d12_group_re;
reg     signed  [width-1:0] phi_d12_group_im;
reg             [2:0]       d12_m;
reg             [1:0]       d12_group_num;
reg                         d12_group_en;
reg                         d12_en;



//calculate phi_d12
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[12] <= 0;
        phi_d_im[12] <= 0;
    end
    else if ((counter >= 76 && counter <= 79) || (counter >= 0 && counter <= 11)) begin
        phi_d_re[12] <= phi_d_con_re + phi_d_re[12];
        phi_d_im[12] <= phi_d_con_im + phi_d_im[12];
    end
    else begin
        phi_d_re[12] <= phi_d_re[12];
        phi_d_im[12] <= phi_d_im[12];
    end
end
// flag when phi_d12[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d12_en <= 0;
    end
    else
        d12_en <= (counter == 11 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d12_m <= 0;
    end
    else begin
        if (d12_m == M-1) begin
            d12_m <= (d12_en)? 0 : d12_m;
        end
        else begin
           d12_m <= (d12_en)? d12_m + 1 : d12_m;
        end
    end
end
//record phi_d12
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d12_re_temp[i] <= 0;
            phi_d12_im_temp[i] <= 0;
        end
    end
    else begin
        if (d12_en) begin
            if (d12_m == 0) begin
                phi_d12_re_temp[d12_m] <=  phi_d_re[1]; 
                phi_d12_im_temp[d12_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d12_re_temp[d12_m] <=  phi_d_re[1] - phi_d12_re_temp[d12_m - 1]; 
                phi_d12_im_temp[d12_m] <=  phi_d_im[1] - phi_d12_im_temp[d12_m - 1]; 
            end
        end
        else begin
            phi_d12_re_temp[d12_m] <= phi_d12_re_temp[d12_m];
            phi_d12_im_temp[d12_m] <= phi_d12_im_temp[d12_m];
        end
    end

end
// count group for phi_d12
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d12_group_en <= 0;
    end
    else
        d12_group_en <= (d12_m == 4 && counter == 79)? 1'b1 : d12_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d12_group_num <= 0;
    end
    else begin
        if (d12_m == 4 && d12_en) 
            d12_group_num <= d12_group_num + 1; 
        else
            d12_group_num <= d12_group_num;
    end
end
// calculate next group phi_d12
always @(posedge clk) begin
    if (d12_group_en && d12_en) begin
        if (d12_group_num == 0) begin
            phi_d12_group_re <= phi_d_re[12];
            phi_d12_group_im <= phi_d_im[12];
        end
        else begin
            phi_d12_group_re <= phi_d_re[12] - phi_d12_re_temp[d12_m];
            phi_d12_group_im <= phi_d_im[12] - phi_d12_im_temp[d12_m];
        end
    end
    else begin
        phi_d12_group_re <= phi_d12_group_re;
        phi_d12_group_im <= phi_d12_group_im;
    end
end

//=========================================================calaulate p_d12=========================================================//
reg     [width-1:0] p_d12_temp [M-1:0];
reg     [width-1:0] p_d12_group;
//calculate p_d12
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[12] <= 0;
    else begin
        if ((counter >= 76 && counter <= 79) || ((counter >= 0 && counter <= 11) && valid)) begin
             p_d[12] <= norm +  p_d[12];
        end
        else begin
             p_d[12] <=  p_d[12];
        end
    end
end
//record p_d12
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d12_temp[0] <= {width{1'b0}};
        p_d12_temp[1] <= {width{1'b0}};
        p_d12_temp[2] <= {width{1'b0}};
        p_d12_temp[3] <= {width{1'b0}};
        p_d12_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d12_en) begin
            if (d12_m == 0) begin
                p_d12_temp[d12_m] <=   p_d[12]; 
            end
            else begin
                p_d12_temp[d12_m] <=   p_d[12] - p_d12_temp[d12_m - 1]; 
            end
        end
        else begin
            p_d12_temp[d12_m] <= p_d12_temp[d12_m];
        end
    end
end

// calculate next group p_d12
always @(posedge clk) begin
    if (d12_group_en && d12_en) begin
        if (d12_group_num == 0) begin
            p_d12_group <=  p_d[12];
        end
        else begin
            p_d12_group <=  p_d[12] - p_d12_temp[d12_m];
        end
    end
    else begin
        p_d12_group <= p_d12_group;
    end
end
// //=========================================================calaulate gamma_d12=========================================================//
reg [width*2-1:0] phi_d12_norm;
reg [width*2-1:0] p_d12_sqr;
wire [width*2-1:0] phi_d12_norm_re;
wire [width*2-1:0] phi_d12_norm_im;
wire [width*2-1:0] p_d12_sqr_in;
reg d12_value_en; // tell gamma_d12 that p_d12 and phi_d12 is ready

// calaulate phi_d norm
assign phi_d12_norm_re = phi_d12_group_re;
assign phi_d12_norm_im = phi_d12_group_im;
always @(*) begin
        phi_d12_norm <= (phi_d12_norm_re * phi_d12_norm_re + phi_d12_norm_im * phi_d12_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d12_sqr_in = p_d12_group;
always @(*) begin
    p_d12_sqr <= (p_d12_sqr_in * p_d12_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d12_value_en <= 0;
    else
        d12_value_en <= (d12_group_en && d12_en)? d12_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[12] <= 0;
    end
    else begin
        if (d12_value_en) 
            gamma_d[12] <= (phi_d12_norm <<< scaling) / p_d12_sqr;
        else
            gamma_d[12] <= gamma_d[12];
    end
end

//=========================================================calaulate phi_d13=========================================================//

reg     signed  [width-1:0] phi_d13_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d13_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d13_group_re;
reg     signed  [width-1:0] phi_d13_group_im;
reg             [2:0]       d13_m;
reg             [1:0]       d13_group_num;
reg                         d13_group_en;
reg                         d13_en;



//calculate phi_d13
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[13] <= 0;
        phi_d_im[13] <= 0;
    end
    else if ((counter >= 77 && counter <= 79) || (counter >= 0 && counter <= 12)) begin
        phi_d_re[13] <= phi_d_con_re + phi_d_re[13];
        phi_d_im[13] <= phi_d_con_im + phi_d_im[13];
    end
    else begin
        phi_d_re[13] <= phi_d_re[13];
        phi_d_im[13] <= phi_d_im[13];
    end
end
// flag when phi_d13[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d13_en <= 0;
    end
    else
        d13_en <= (counter == 12 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d13_m <= 0;
    end
    else begin
        if (d13_m == M-1) begin
            d13_m <= (d13_en)? 0 : d13_m;
        end
        else begin
           d13_m <= (d13_en)? d13_m + 1 : d13_m;
        end
    end
end
//record phi_d13
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d13_re_temp[i] <= 0;
            phi_d13_im_temp[i] <= 0;
        end
    end
    else begin
        if (d13_en) begin
            if (d13_m == 0) begin
                phi_d13_re_temp[d13_m] <=  phi_d_re[1]; 
                phi_d13_im_temp[d13_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d13_re_temp[d13_m] <=  phi_d_re[1] - phi_d13_re_temp[d13_m - 1]; 
                phi_d13_im_temp[d13_m] <=  phi_d_im[1] - phi_d13_im_temp[d13_m - 1]; 
            end
        end
        else begin
            phi_d13_re_temp[d13_m] <= phi_d13_re_temp[d13_m];
            phi_d13_im_temp[d13_m] <= phi_d13_im_temp[d13_m];
        end
    end

end
// count group for phi_d13
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d13_group_en <= 0;
    end
    else
        d13_group_en <= (d13_m == 4 && counter == 79)? 1'b1 : d13_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d13_group_num <= 0;
    end
    else begin
        if (d13_m == 4 && d13_en) 
            d13_group_num <= d13_group_num + 1; 
        else
            d13_group_num <= d13_group_num;
    end
end
// calculate next group phi_d13
always @(posedge clk) begin
    if (d13_group_en && d13_en) begin
        if (d13_group_num == 0) begin
            phi_d13_group_re <= phi_d_re[13];
            phi_d13_group_im <= phi_d_im[13];
        end
        else begin
            phi_d13_group_re <= phi_d_re[13] - phi_d13_re_temp[d13_m];
            phi_d13_group_im <= phi_d_im[13] - phi_d13_im_temp[d13_m];
        end
    end
    else begin
        phi_d13_group_re <= phi_d13_group_re;
        phi_d13_group_im <= phi_d13_group_im;
    end
end

//=========================================================calaulate p_d13=========================================================//
reg     [width-1:0] p_d13_temp [M-1:0];
reg     [width-1:0] p_d13_group;
//calculate p_d13
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[13] <= 0;
    else begin
        if ((counter >= 77 && counter <= 79) || ((counter >= 0 && counter <= 12) && valid)) begin
             p_d[13] <= norm +  p_d[13];
        end
        else begin
             p_d[13] <=  p_d[13];
        end
    end
end
//record p_d13
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d13_temp[0] <= {width{1'b0}};
        p_d13_temp[1] <= {width{1'b0}};
        p_d13_temp[2] <= {width{1'b0}};
        p_d13_temp[3] <= {width{1'b0}};
        p_d13_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d13_en) begin
            if (d13_m == 0) begin
                p_d13_temp[d13_m] <=   p_d[13]; 
            end
            else begin
                p_d13_temp[d13_m] <=   p_d[13] - p_d13_temp[d13_m - 1]; 
            end
        end
        else begin
            p_d13_temp[d13_m] <= p_d13_temp[d13_m];
        end
    end
end

// calculate next group p_d13
always @(posedge clk) begin
    if (d13_group_en && d13_en) begin
        if (d13_group_num == 0) begin
            p_d13_group <=  p_d[13];
        end
        else begin
            p_d13_group <=  p_d[13] - p_d13_temp[d13_m];
        end
    end
    else begin
        p_d13_group <= p_d13_group;
    end
end
// //=========================================================calaulate gamma_d13=========================================================//
reg [width*2-1:0] phi_d13_norm;
reg [width*2-1:0] p_d13_sqr;
wire [width*2-1:0] phi_d13_norm_re;
wire [width*2-1:0] phi_d13_norm_im;
wire [width*2-1:0] p_d13_sqr_in;
reg d13_value_en; // tell gamma_d13 that p_d13 and phi_d13 is ready

// calaulate phi_d norm
assign phi_d13_norm_re = phi_d13_group_re;
assign phi_d13_norm_im = phi_d13_group_im;
always @(*) begin
        phi_d13_norm <= (phi_d13_norm_re * phi_d13_norm_re + phi_d13_norm_im * phi_d13_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d13_sqr_in = p_d13_group;
always @(*) begin
    p_d13_sqr <= (p_d13_sqr_in * p_d13_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d13_value_en <= 0;
    else
        d13_value_en <= (d13_group_en && d13_en)? d13_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[13] <= 0;
    end
    else begin
        if (d13_value_en) 
            gamma_d[13] <= (phi_d13_norm <<< scaling) / p_d13_sqr;
        else
            gamma_d[13] <= gamma_d[13];
    end
end

//=========================================================calaulate phi_d14=========================================================//

reg     signed  [width-1:0] phi_d14_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d14_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d14_group_re;
reg     signed  [width-1:0] phi_d14_group_im;
reg             [2:0]       d14_m;
reg             [1:0]       d14_group_num;
reg                         d14_group_en;
reg                         d14_en;



//calculate phi_d14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[14] <= 0;
        phi_d_im[14] <= 0;
    end
    else if ((counter == 78) || (counter == 79) || (counter >= 0 && counter <= 13)) begin
        phi_d_re[14] <= phi_d_con_re + phi_d_re[14];
        phi_d_im[14] <= phi_d_con_im + phi_d_im[14];
    end
    else begin
        phi_d_re[14] <= phi_d_re[14];
        phi_d_im[14] <= phi_d_im[14];
    end
end
// flag when phi_d14[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d14_en <= 0;
    end
    else
        d14_en <= (counter == 13 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d14_m <= 0;
    end
    else begin
        if (d14_m == M-1) begin
            d14_m <= (d14_en)? 0 : d14_m;
        end
        else begin
           d14_m <= (d14_en)? d14_m + 1 : d14_m;
        end
    end
end
//record phi_d14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d14_re_temp[i] <= 0;
            phi_d14_im_temp[i] <= 0;
        end
    end
    else begin
        if (d14_en) begin
            if (d14_m == 0) begin
                phi_d14_re_temp[d14_m] <=  phi_d_re[1]; 
                phi_d14_im_temp[d14_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d14_re_temp[d14_m] <=  phi_d_re[1] - phi_d14_re_temp[d14_m - 1]; 
                phi_d14_im_temp[d14_m] <=  phi_d_im[1] - phi_d14_im_temp[d14_m - 1]; 
            end
        end
        else begin
            phi_d14_re_temp[d14_m] <= phi_d14_re_temp[d14_m];
            phi_d14_im_temp[d14_m] <= phi_d14_im_temp[d14_m];
        end
    end

end
// count group for phi_d14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d14_group_en <= 0;
    end
    else
        d14_group_en <= (d14_m == 4 && counter == 79)? 1'b1 : d14_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d14_group_num <= 0;
    end
    else begin
        if (d14_m == 4 && d14_en) 
            d14_group_num <= d14_group_num + 1; 
        else
            d14_group_num <= d14_group_num;
    end
end
// calculate next group phi_d14
always @(posedge clk) begin
    if (d14_group_en && d14_en) begin
        if (d14_group_num == 0) begin
            phi_d14_group_re <= phi_d_re[14];
            phi_d14_group_im <= phi_d_im[14];
        end
        else begin
            phi_d14_group_re <= phi_d_re[14] - phi_d14_re_temp[d14_m];
            phi_d14_group_im <= phi_d_im[14] - phi_d14_im_temp[d14_m];
        end
    end
    else begin
        phi_d14_group_re <= phi_d14_group_re;
        phi_d14_group_im <= phi_d14_group_im;
    end
end

//=========================================================calaulate p_d14=========================================================//
reg     [width-1:0] p_d14_temp [M-1:0];
reg     [width-1:0] p_d14_group;
//calculate p_d14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[14] <= 0;
    else begin
        if ((counter == 78) || (counter == 79) || ((counter >= 0 && counter <= 13) && valid)) begin
             p_d[14] <= norm +  p_d[14];
        end
        else begin
             p_d[14] <=  p_d[14];
        end
    end
end
//record p_d14
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d14_temp[0] <= {width{1'b0}};
        p_d14_temp[1] <= {width{1'b0}};
        p_d14_temp[2] <= {width{1'b0}};
        p_d14_temp[3] <= {width{1'b0}};
        p_d14_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d14_en) begin
            if (d14_m == 0) begin
                p_d14_temp[d14_m] <=   p_d[14]; 
            end
            else begin
                p_d14_temp[d14_m] <=   p_d[14] - p_d14_temp[d14_m - 1]; 
            end
        end
        else begin
            p_d14_temp[d14_m] <= p_d14_temp[d14_m];
        end
    end
end

// calculate next group p_d14
always @(posedge clk) begin
    if (d14_group_en && d14_en) begin
        if (d14_group_num == 0) begin
            p_d14_group <=  p_d[14];
        end
        else begin
            p_d14_group <=  p_d[14] - p_d14_temp[d14_m];
        end
    end
    else begin
        p_d14_group <= p_d14_group;
    end
end
// //=========================================================calaulate gamma_d14=========================================================//
reg [width*2-1:0] phi_d14_norm;
reg [width*2-1:0] p_d14_sqr;
wire [width*2-1:0] phi_d14_norm_re;
wire [width*2-1:0] phi_d14_norm_im;
wire [width*2-1:0] p_d14_sqr_in;
reg d14_value_en; // tell gamma_d14 that p_d14 and phi_d14 is ready

// calaulate phi_d norm
assign phi_d14_norm_re = phi_d14_group_re;
assign phi_d14_norm_im = phi_d14_group_im;
always @(*) begin
        phi_d14_norm <= (phi_d14_norm_re * phi_d14_norm_re + phi_d14_norm_im * phi_d14_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d14_sqr_in = p_d14_group;
always @(*) begin
    p_d14_sqr <= (p_d14_sqr_in * p_d14_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d14_value_en <= 0;
    else
        d14_value_en <= (d14_group_en && d14_en)? d14_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[14] <= 0;
    end
    else begin
        if (d14_value_en) 
            gamma_d[14] <= (phi_d14_norm <<< scaling) / p_d14_sqr;
        else
            gamma_d[14] <= gamma_d[14];
    end
end

//=========================================================calaulate phi_d15=========================================================//

reg     signed  [width-1:0] phi_d15_re_temp [M-1:0];
reg     signed  [width-1:0] phi_d15_im_temp [M-1:0];
reg     signed  [width-1:0] phi_d15_group_re;
reg     signed  [width-1:0] phi_d15_group_im;
reg             [2:0]       d15_m;
reg             [1:0]       d15_group_num;
reg                         d15_group_en;
reg                         d15_en;



//calculate phi_d15
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        phi_d_re[15] <= 0;
        phi_d_im[15] <= 0;
    end
    else if ((counter == 79) || (counter >= 0 && counter <= 14)) begin
        phi_d_re[15] <= phi_d_con_re + phi_d_re[15];
        phi_d_im[15] <= phi_d_con_im + phi_d_im[15];
    end
    else begin
        phi_d_re[15] <= phi_d_re[15];
        phi_d_im[15] <= phi_d_im[15];
    end
end
// flag when phi_d15[m] is done
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d15_en <= 0;
    end
    else
        d15_en <= (counter == 14 && valid)? 1'b1 : 1'b0; 
end
// record m
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d15_m <= 0;
    end
    else begin
        if (d15_m == M-1) begin
            d15_m <= (d15_en)? 0 : d15_m;
        end
        else begin
           d15_m <= (d15_en)? d15_m + 1 : d15_m;
        end
    end
end
//record phi_d15
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(i = 0; i < 5; i = i + 1) begin
            phi_d15_re_temp[i] <= 0;
            phi_d15_im_temp[i] <= 0;
        end
    end
    else begin
        if (d15_en) begin
            if (d15_m == 0) begin
                phi_d15_re_temp[d15_m] <=  phi_d_re[1]; 
                phi_d15_im_temp[d15_m] <=  phi_d_im[1]; 
            end
            else begin
                phi_d15_re_temp[d15_m] <=  phi_d_re[1] - phi_d15_re_temp[d15_m - 1]; 
                phi_d15_im_temp[d15_m] <=  phi_d_im[1] - phi_d15_im_temp[d15_m - 1]; 
            end
        end
        else begin
            phi_d15_re_temp[d15_m] <= phi_d15_re_temp[d15_m];
            phi_d15_im_temp[d15_m] <= phi_d15_im_temp[d15_m];
        end
    end

end
// count group for phi_d15
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d15_group_en <= 0;
    end
    else
        d15_group_en <= (d15_m == 4 && counter == 79)? 1'b1 : d15_group_en;
end
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d15_group_num <= 0;
    end
    else begin
        if (d15_m == 4 && d15_en) 
            d15_group_num <= d15_group_num + 1; 
        else
            d15_group_num <= d15_group_num;
    end
end
// calculate next group phi_d15
always @(posedge clk) begin
    if (d15_group_en && d15_en) begin
        if (d15_group_num == 0) begin
            phi_d15_group_re <= phi_d_re[15];
            phi_d15_group_im <= phi_d_im[15];
        end
        else begin
            phi_d15_group_re <= phi_d_re[15] - phi_d15_re_temp[d15_m];
            phi_d15_group_im <= phi_d_im[15] - phi_d15_im_temp[d15_m];
        end
    end
    else begin
        phi_d15_group_re <= phi_d15_group_re;
        phi_d15_group_im <= phi_d15_group_im;
    end
end

//=========================================================calaulate p_d15=========================================================//
reg     [width-1:0] p_d15_temp [M-1:0];
reg     [width-1:0] p_d15_group;
//calculate p_d15
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
         p_d[15] <= 0;
    else begin
        if ((counter == 79) || ((counter >= 0 && counter <= 14) && valid)) begin
             p_d[15] <= norm +  p_d[15];
        end
        else begin
             p_d[15] <=  p_d[15];
        end
    end
end
//record p_d15
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        p_d15_temp[0] <= {width{1'b0}};
        p_d15_temp[1] <= {width{1'b0}};
        p_d15_temp[2] <= {width{1'b0}};
        p_d15_temp[3] <= {width{1'b0}};
        p_d15_temp[4] <= {width{1'b0}};
    end
    else begin
        if (d15_en) begin
            if (d15_m == 0) begin
                p_d15_temp[d15_m] <=   p_d[15]; 
            end
            else begin
                p_d15_temp[d15_m] <=   p_d[15] - p_d15_temp[d15_m - 1]; 
            end
        end
        else begin
            p_d15_temp[d15_m] <= p_d15_temp[d15_m];
        end
    end
end

// calculate next group p_d15
always @(posedge clk) begin
    if (d15_group_en && d15_en) begin
        if (d15_group_num == 0) begin
            p_d15_group <=  p_d[15];
        end
        else begin
            p_d15_group <=  p_d[15] - p_d15_temp[d15_m];
        end
    end
    else begin
        p_d15_group <= p_d15_group;
    end
end
// //=========================================================calaulate gamma_d15=========================================================//
reg [width*2-1:0] phi_d15_norm;
reg [width*2-1:0] p_d15_sqr;
wire [width*2-1:0] phi_d15_norm_re;
wire [width*2-1:0] phi_d15_norm_im;
wire [width*2-1:0] p_d15_sqr_in;
reg d15_value_en; // tell gamma_d15 that p_d15 and phi_d15 is ready

// calaulate phi_d norm
assign phi_d15_norm_re = phi_d15_group_re;
assign phi_d15_norm_im = phi_d15_group_im;
always @(*) begin
        phi_d15_norm <= (phi_d15_norm_re * phi_d15_norm_re + phi_d15_norm_im * phi_d15_norm_im) >>> scaling;        
end
//calculate p_d sqr
assign p_d15_sqr_in = p_d15_group;
always @(*) begin
    p_d15_sqr <= (p_d15_sqr_in * p_d15_sqr_in) >>> scaling;
end
// gamma calculation data_en
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        d15_value_en <= 0;
    else
        d15_value_en <= (d15_group_en && d15_en)? d15_en : 1'b0;
end
// calculate gamma
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        gamma_d[15] <= 0;
    end
    else begin
        if (d15_value_en) 
            gamma_d[15] <= (phi_d15_norm <<< scaling) / p_d15_sqr;
        else
            gamma_d[15] <= gamma_d[15];
    end
end

//======================================find peak point=================================================//
reg                 compare_en; // compare enable
reg                 delay;      // delay for complete compare
reg     [3:0]       compare_count; // count for gamma0 ~ gamma15
reg     [width-1:0] max_value;
reg                 remove_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        delay <= 0;
    else
        delay <= d15_value_en;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        compare_en <= 0;
    else if (d0_value_en)
        compare_en <= 1;
    else if (delay)
        compare_en <= 0;
    else
        compare_en <= compare_en ;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        compare_count <= 4'b0;
    else begin
        if (compare_en)
            compare_count <= compare_count + 1;
        else
            compare_count <= 4'b0; 
    end
end
// find the peak point and max gamma
always@(posedge clk) begin
    if (compare_en ) begin
        if (gamma_d[compare_count] > max_value) begin
            max_value = gamma_d[compare_count];
            peak_point = compare_count;
        end
        else begin
            max_value = max_value;
            peak_point = peak_point;
        end
    end
    else begin
        max_value = 0;
        peak_point = 0;
    end
end
//comparison finish
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        finish <= 1'b0;
    else begin
        if (compare_count == 15)
            finish <= 1'b1;
        else
            finish <= 0;
    end
end
// calculate boundary
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        boundary <= 0;
    else begin
        if (finish)
            boundary <= peak_point + 16;
        else
            boundary <= boundary; 
    end
end
// remove cp enable
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        remove_valid <= 0;
    else begin
        if (finish)
            remove_valid <= 1;
        else
            remove_valid <= remove_valid; 
    end
end
//=============================== remove cp ====================================//
reg [width-1:0] data_re_mem [0:(M+1)*80-1];
reg [width-1:0] data_im_mem [0:(M+1)*80-1];
reg [5:0]       out_counter;
reg [2:0]       num;
reg [2:0]       out_num;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        num <= 0;
    else begin
        if (data_en) begin
            if (counter == 79) begin
                if (num == 5)
                    num <= 0;
                else
                    num <= num + 1;
            end
            else
                num <= num;
        end
        else
            num <= 0;
    end
end
// save data
always@(posedge clk) begin
    if(data_en) begin
        data_re_mem[counter + num * 80] <= data_re;
        data_im_mem[counter + num * 80] <= data_im;
    end
    else begin
        data_re_mem[counter + num * 80] <= data_re_mem[counter + num * 80];
        data_im_mem[counter + num * 80] <= data_im_mem[counter + num * 80];
    end
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out_counter <= 0;
    end
    else begin
        out_counter <= (remove_valid)? out_counter + 1 : out_counter;
    end    
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        out_num <= 0;
    else begin
        if (remove_valid) begin
                if (out_counter == 63) begin
                    if (out_num == 5)
                        out_num <= 0;
                    else
                        out_num <= out_num + 1;
                end
                else
                    out_num <= out_num; 
        end
        else
            out_num <= 0;
    end
end

always @(*) begin
    if (remove_valid) begin
        data_out_en <= 1;
        data_out_re <= data_re_mem[(out_counter + boundary) + out_num * 80];
        data_out_im <= data_im_mem[(out_counter + boundary) + out_num * 80];
    end
    else begin
        data_out_en <= 0;
        data_out_re <= {width{1'bX}};
        data_out_im <= {width{1'bX}};       
    end
end

endmodule