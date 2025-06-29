module remove_cp #(
    parameter width = 16,
              M     = 5
) (
    input               enable,
    input   [width-1:0] data_re,
    input   [width-1:0] data_im,
    input   [width-1:0] peak_point,
    output              out_valid,
    output  [width-1:0] data_out_re,
    output  [width-1:0] data_out_im

);
reg [width-1:0] data_re_mem [(M+1)*80-1:0];
reg [width-1:0] data_im_mem [(M+1)*80-1:0];
reg [2:0]       num;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        num <= 0;
    else begin
        if (data_en) begin
            if (counter == 79)
                num <= num + 1;
            else
                num <= num;
        end
        else
            num <= 0;
    end
end

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
endmodule


//======================
//   Output remove CP
//======================
assign out_valid = (ofdm_counter >= 11) ? 1 : 0;

integer s;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal0_re[s] <= 0;
            awgn_cp_signal0_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 0) begin
            awgn_cp_signal0_re[counter-1] <= reg_in_re;
            awgn_cp_signal0_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal0_re[s] <= awgn_cp_signal0_re[s];
                awgn_cp_signal0_im[s] <= awgn_cp_signal0_im[s];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal1_re[s] <= 0;
            awgn_cp_signal1_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 1) begin
            awgn_cp_signal1_re[counter-1] <= reg_in_re;
            awgn_cp_signal1_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal1_re[s] <= awgn_cp_signal1_re[s];
                awgn_cp_signal1_im[s] <= awgn_cp_signal1_im[s];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal2_re[s] <= 0;
            awgn_cp_signal2_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 2) begin
            awgn_cp_signal2_re[counter-1] <= reg_in_re;
            awgn_cp_signal2_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal2_re[s] <= awgn_cp_signal2_re[s];
                awgn_cp_signal2_im[s] <= awgn_cp_signal2_im[s];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal3_re[s] <= 0;
            awgn_cp_signal3_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 3) begin
            awgn_cp_signal3_re[counter-1] <= reg_in_re;
            awgn_cp_signal3_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal3_re[s] <= awgn_cp_signal3_re[s];
                awgn_cp_signal3_im[s] <= awgn_cp_signal3_im[s];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal4_re[s] <= 0;
            awgn_cp_signal4_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 4) begin
            awgn_cp_signal4_re[counter-1] <= reg_in_re;
            awgn_cp_signal4_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal4_re[s] <= awgn_cp_signal4_re[s];
                awgn_cp_signal4_im[s] <= awgn_cp_signal4_im[s];
            end
        end
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(s = 0; s < 80; s = s + 1) begin
            awgn_cp_signal5_re[s] <= 0;
            awgn_cp_signal5_im[s] <= 0;
        end
    end
    else begin
        if(ofdm_counter == 5) begin
            awgn_cp_signal5_re[counter-1] <= reg_in_re;
            awgn_cp_signal5_im[counter-1] <= reg_in_im;
        end
        else begin
            for(s = 0; s < 80; s = s + 1) begin
                awgn_cp_signal5_re[s] <= awgn_cp_signal5_re[s];
                awgn_cp_signal5_im[s] <= awgn_cp_signal5_im[s];
            end
        end
    end
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_counter <= 0;
    else if(out_valid) begin
        if(output_counter == 63) output_counter <= 0;
        else output_counter <= output_counter + 1;
    end
    else output_counter <= 0;
end

reg [6:0] output_ofdm_num;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) output_ofdm_num <= 0;
    else begin
        if(output_counter == 63) output_ofdm_num <= output_ofdm_num + 1;
        else output_ofdm_num <= output_ofdm_num;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cp_remove_signal_re <= 0;
    end
    else if(out_valid) begin
        case(output_ofdm_num)
            0 : cp_remove_signal_re <= awgn_cp_signal0_re[boundary + 16 + output_counter];
            1 : cp_remove_signal_re <= awgn_cp_signal1_re[boundary + 16 + output_counter];
            2 : cp_remove_signal_re <= awgn_cp_signal2_re[boundary + 16 + output_counter];
            3 : cp_remove_signal_re <= awgn_cp_signal3_re[boundary + 16 + output_counter];
            4 : cp_remove_signal_re <= awgn_cp_signal4_re[boundary + 16 + output_counter];
            5 : cp_remove_signal_re <= awgn_cp_signal5_re[boundary + 16 + output_counter];
            default: cp_remove_signal_re <= 16'bx;
        endcase
    end
    else begin
        cp_remove_signal_re <= 16'bx;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cp_remove_signal_im <= 0;
    end
    else if(out_valid) begin
        case(output_ofdm_num)
            0 : cp_remove_signal_im <= awgn_cp_signal0_im[boundary + 16 + output_counter];
            1 : cp_remove_signal_im <= awgn_cp_signal1_im[boundary + 16 + output_counter];
            2 : cp_remove_signal_im <= awgn_cp_signal2_im[boundary + 16 + output_counter];
            3 : cp_remove_signal_im <= awgn_cp_signal3_im[boundary + 16 + output_counter];
            4 : cp_remove_signal_im <= awgn_cp_signal4_im[boundary + 16 + output_counter];
            5 : cp_remove_signal_im <= awgn_cp_signal5_im[boundary + 16 + output_counter];
            default: cp_remove_signal_im <= 16'bx;
        endcase
    end
    else begin
        cp_remove_signal_im <= 16'bx;
    end
end