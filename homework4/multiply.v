module multiply#(
    parameter width = 16,
              scaling = 8
) (
    input signed [width-1:0] a_re,
    input signed [width-1:0] a_img,
    input signed [width-1:0] b_re,
    input signed [width-1:0] b_img,
    output signed [width-1:0] c_re,
    output signed [width-1:0] c_img
);
wire signed [width*2-1:0] temp1, temp2, temp3, temp4; 
wire signed [width-1:0] sc_temp1, sc_temp2, sc_temp3, sc_temp4;

//multiplication(32bit)
assign temp1 = a_re * b_re;
assign temp2 = a_img * b_img;
assign temp3 = a_re * b_img;
assign temp4 = a_img * b_re;

//resizing to 16 bit
assign sc_temp1 = temp1 >>> scaling;
assign sc_temp2 = temp2 >>> scaling;
assign sc_temp3 = temp3 >>> scaling;
assign sc_temp4 = temp4 >>> scaling;


//final result
assign c_re = sc_temp1 - sc_temp2;
assign c_img = sc_temp3 + sc_temp4;

// //multiplication(32bit)
// assign temp1 = a_re * b_re;
// assign temp2 = a_img * b_img;
// assign temp3 = a_re * b_img;
// assign temp4 = a_img * b_re;

// //resizing to 16 bit
// assign sc_temp1 = temp1 - temp2;
// assign sc_temp2 = temp3 + temp4;


// //final result
// assign c_re = sc_temp1 >>> scaling;
// assign c_img = sc_temp2 >>> scaling;
endmodule