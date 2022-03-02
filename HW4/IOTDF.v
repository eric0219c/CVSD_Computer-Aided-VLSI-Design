`timescale 1ns/10ps

// Function define
`define Max             1
`define Min             2
`define Avg             3
`define Extract         4
`define Exclude         5
`define PeakMax         6
`define PeakMin         7

module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output reg     valid;
output reg [127:0] iot_out;
//-------------------------------------------------------------------------------//
reg [127:0]     MIN_data;
reg [7:0]       reg1 [15:0];      // 0-15, 16-32, .... 1520-1535.
reg [3:0]       index;    // 0 - 16
reg [6:0]       counter;  // 0 - 95
reg [130:0]     total;
reg [127:0]     total_M;
//-------------------------------------------------------------------------------//
assign busy     = (rst)? 1 : 0;
//-------------------------------------------------------------------------------//
integer i;

always@(posedge clk) begin
    if(rst) begin
        index           <= 0;
        counter         <= 7'b111_1111;
        valid           <= 0;
        iot_out         <= 0;
        total           <= 0;
        total_M         <= (fn_sel == `PeakMin)? {128{1'b1}} : 0;
        MIN_data        <= (fn_sel == `Min | fn_sel == `PeakMin)? {128{1'b1}} : 0;
        for(i = 0; i < 16; i = i + 1)
            reg1[i]     <= 0;
    end 

    else begin
        if(in_en) begin
            reg1[index]     <= iot_in;
            index           <= index + 1;
            counter         <= (index[3:0] == 0)? counter + 1 : counter; // index -> multiple of 16
        end

        if(index == 0 & counter != 7'b111_1111) begin// every 16 8-bit data to accumulate
            case(fn_sel)
            `Min, `PeakMin: begin
                if(reg1[0][7:2] < MIN_data[127:122]) 
                    MIN_data    <= {reg1[0], reg1[1], reg1[2], reg1[3], reg1[4], reg1[5], reg1[6], reg1[7], reg1[8], reg1[9], reg1[10], reg1[11], reg1[12], reg1[13], reg1[14], reg1[15]};
            end
            `Max, `PeakMax: begin
                if(reg1[0][7:2] > MIN_data[127:122])
                    MIN_data    <= {reg1[0], reg1[1], reg1[2], reg1[3], reg1[4], reg1[5], reg1[6], reg1[7], reg1[8], reg1[9], reg1[10], reg1[11], reg1[12], reg1[13], reg1[14], reg1[15]};
            end
            `Avg: begin
                total <= total + {reg1[0], reg1[1], reg1[2],  reg1[3],  reg1[4],  reg1[5],  reg1[6],  reg1[7], reg1[8], reg1[9], reg1[10], reg1[11], reg1[12], reg1[13], reg1[14], reg1[15]};
            end
            `Extract : begin        // if {Reg[0] ~ Reg[3]} == 7, 8, 9, A.
                if((!reg1[0][7] & reg1[0][6] & reg1[0][5] & reg1[0][4])  | (reg1[0][7] & !reg1[0][6] & !reg1[0][5] & !reg1[0][4]) | (reg1[0][7] & !reg1[0][6] & !reg1[0][5] & reg1[0][4]) | (reg1[0][7] & !reg1[0][6] & reg1[0][5] & !reg1[0][4])) begin
                    valid     <= 1;
                    iot_out   <= {reg1[0], reg1[1], reg1[2],  reg1[3],  reg1[4],  reg1[5],  reg1[6],  reg1[7], reg1[8], reg1[9], reg1[10], reg1[11], reg1[12], reg1[13], reg1[14], reg1[15]};
                end
            end
            `Exclude : begin        // if {Reg[0] ~ Reg[3]} != 8, 9, A, B 
                if(!(reg1[0][7] & !reg1[0][6])) begin
                    valid     <= 1;
                    iot_out   <= {reg1[0], reg1[1], reg1[2],  reg1[3],  reg1[4],  reg1[5],  reg1[6],  reg1[7], reg1[8], reg1[9], reg1[10], reg1[11], reg1[12], reg1[13], reg1[14], reg1[15]};
                end
            end
            default : begin 
                valid     <= 0;
            end
            endcase
        end
        
        // After 8 data and delay 1 cycle to set valid.
        else if(counter[2:0] == 0 & counter > 0 & index == 4'd1) begin
            case(fn_sel)
            `Max : begin
                iot_out   <= MIN_data;
                valid     <= 1;
                MIN_data    <= 0;
            end
            `Min : begin
                iot_out   <= MIN_data;
                valid     <= 1;
                MIN_data    <= {128{1'b1}};
            end
            `Avg    : begin
                iot_out   <= (total >> 3);  
                valid     <= 1;
                total       <= 0; 
            end
            `PeakMax : begin
                MIN_data    <= 0;
                if(MIN_data > total_M) begin
                    total_M   <= MIN_data;
                    valid     <= 1;
                    iot_out   <= MIN_data;
                end
            end
            `PeakMin : begin
                MIN_data    <= {128{1'b1}};
                if(MIN_data < total_M) begin
                    total_M   <= MIN_data;
                    valid     <= 1;
                    iot_out   <= MIN_data;
                end
            end
            default : begin
                valid     <= 0;
            end
            endcase
        end
        else
            valid     <= 0;
    end
end
endmodule
// ncverilog testfixture.v IOTDF.v +access+r -clean +define+F7
// ncverilog -f rtl_03.f +ncmaxdelays +access+r +define+SDF+F1
// 