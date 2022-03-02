// state define
`define IDLE		0
`define READ		1
`define SET_X		2
`define WAIT_CYCLE	3
`define COMPUTE_X0	4
`define COMPUTE_X1	5
`define COMPUTE_X2	6
`define COMPUTE_X3	7
`define COMPUTE_X4	8
`define COMPUTE_X5	9
`define COMPUTE_X6	10
`define COMPUTE_X7	11
`define COMPUTE_X8	12
`define COMPUTE_X9	13
`define COMPUTE_X10	14
`define COMPUTE_X11	15
`define COMPUTE_X12	16
`define COMPUTE_X13	17
`define COMPUTE_X14	18
`define COMPUTE_X15	19
`define STORE_DATA1	20
`define STORE_DATA2	21

module GSIM (                       //Don't modify interface
	input          i_clk,
	input          i_reset,
	input          i_module_en,
	input  [  4:0] i_matrix_num,
	output         o_proc_done,

	// matrix memory
	output         o_mem_rreq,
	output [  9:0] o_mem_addr,
	input          i_mem_rrdy,
	input  [255:0] i_mem_dout,
	input          i_mem_dout_vld,
	
	// output result
	output 	       o_x_wen,
	output reg [  8:0] o_x_addr,
	output reg [ 31:0] o_x_data  
);
//----------------------------- Reg And Wire -------------------------------------//
reg  [255:0]	Matrix_Data [15:0];		// B is in Matrix_Data[16]
reg  signed[31:0]	X_Data [15:0];
reg  signed[255:0]	B_Data;
reg [4:0]			curr_state, next_state;
reg [9:0]			o_mem_addr_r;
wire				read_finish;
reg [4:0]			index;
wire signed[31:0]	low;
wire signed[31:0]	high;
reg	 signed[47:0] 	AX;
reg  signed[31:0]	aX_1, aX_2, aX_3, aX_4, aX_5, aX_6, aX_7, aX_8, aX_9, aX_10, aX_11, aX_12, aX_13, aX_14, aX_15;
reg  signed[35:0]	B_minus;	// b1 - a12 * x2 - ... - a1,16 * x16
reg  signed[31:0]	b_minus;	// B_minus after integer asymmetric saturation.	
reg  signed[15:0]	B_factor;	// b1, b2, b3, .... , b16. change every cycle
reg [3:0]			counter;
reg [4:0]			counter2;	
wire signed[31:0]	B_factor_16;	
wire [4:0]			matrix_num;
reg	 [5:0]			count_matrix;
//-------------------------------- Reg  ----------------------------------------//
reg signed [15:0]	A;
reg signed [31:0]	X;
reg signed [31:0]	set_X;
reg signed [15:0]	aX_X;	
//-------------------------------- Reg  ----------------------------------------//
reg signed [15:0]	a16_1, a15_1, a14_1, a13_1, a12_1, a11_1, a10_1, a9_1, a8_1, a7_1, a6_1, a5_1, a4_1, a3_1, a2_1, a1_1;
reg signed [15:0]	a16_2, a15_2, a14_2, a13_2, a12_2, a11_2, a10_2, a9_2, a8_2, a7_2, a6_2, a5_2, a4_2, a3_2, a2_2, a1_2;
reg signed [15:0]	a16_3, a15_3, a14_3, a13_3, a12_3, a11_3, a10_3, a9_3, a8_3, a7_3, a6_3, a5_3, a4_3, a3_3, a2_3, a1_3;
reg signed [15:0]	a16_4, a15_4, a14_4, a13_4, a12_4, a11_4, a10_4, a9_4, a8_4, a7_4, a6_4, a5_4, a4_4, a3_4, a2_4, a1_4;
reg signed [15:0]	a16_5, a15_5, a14_5, a13_5, a12_5, a11_5, a10_5, a9_5, a8_5, a7_5, a6_5, a5_5, a4_5, a3_5, a2_5, a1_5;
reg signed [15:0]	a16_6, a15_6, a14_6, a13_6, a12_6, a11_6, a10_6, a9_6, a8_6, a7_6, a6_6, a5_6, a4_6, a3_6, a2_6, a1_6;
reg signed [15:0]	a16_7, a15_7, a14_7, a13_7, a12_7, a11_7, a10_7, a9_7, a8_7, a7_7, a6_7, a5_7, a4_7, a3_7, a2_7, a1_7;
reg signed [15:0]	a16_8, a15_8, a14_8, a13_8, a12_8, a11_8, a10_8, a9_8, a8_8, a7_8, a6_8, a5_8, a4_8, a3_8, a2_8, a1_8;
reg signed [15:0]	a16_9, a15_9, a14_9, a13_9, a12_9, a11_9, a10_9, a9_9, a8_9, a7_9, a6_9, a5_9, a4_9, a3_9, a2_9, a1_9;
reg signed [15:0]	a16_10, a15_10, a14_10, a13_10, a12_10, a11_10, a10_10, a9_10, a8_10, a7_10, a6_10, a5_10, a4_10, a3_10, a2_10, a1_10;
reg signed [15:0]	a16_11, a15_11, a14_11, a13_11, a12_11, a11_11, a10_11, a9_11, a8_11, a7_11, a6_11, a5_11, a4_11, a3_11, a2_11, a1_11;
reg signed [15:0]	a16_12, a15_12, a14_12, a13_12, a12_12, a11_12, a10_12, a9_12, a8_12, a7_12, a6_12, a5_12, a4_12, a3_12, a2_12, a1_12;
reg signed [15:0]	a16_13, a15_13, a14_13, a13_13, a12_13, a11_13, a10_13, a9_13, a8_13, a7_13, a6_13, a5_13, a4_13, a3_13, a2_13, a1_13;
reg signed [15:0]	a16_14, a15_14, a14_14, a13_14, a12_14, a11_14, a10_14, a9_14, a8_14, a7_14, a6_14, a5_14, a4_14, a3_14, a2_14, a1_14;
reg signed [15:0]	a16_15, a15_15, a14_15, a13_15, a12_15, a11_15, a10_15, a9_15, a8_15, a7_15, a6_15, a5_15, a4_15, a3_15, a2_15, a1_15;
reg signed [15:0]	a16_16, a15_16, a14_16, a13_16, a12_16, a11_16, a10_16, a9_16, a8_16, a7_16, a6_16, a5_16, a4_16, a3_16, a2_16, a1_16;
reg signed [15:0]	b16, b15, b14, b13, b12, b11, b10, b9, b8, b7, b6, b5, b4, b3, b2, b1;
//-------------------------------------------------------------------------------------//
//--------------------------------------------------------------------------------//
//------------------------ Combinational Circuit --------------------------------//
assign	o_mem_rreq  = 	(curr_state == `READ & index != 5'd16)? 1 : 0;
assign	o_mem_addr  = 	o_mem_addr_r;
assign	read_finish	=	(index == 5'd16)?	1 : 0;	// if index == 16, read finish and reset index.
assign	low			=	32'b1000_0000_0000_0000_0000_0000_0000_0000;	// low	-> the position of 30 is 1 which represent the smallest negative number.
assign	high		=	32'b0111_1111_1111_1111_1111_1111_1111_1111;	// high -> 29 * 1
assign	B_factor_16	=	(B_factor << 16);
assign	matrix_num	=	i_matrix_num;
assign	o_proc_done =	(count_matrix != matrix_num)? 0 : (i_module_en)? 1 : 0;
assign	o_x_wen		=	(curr_state == `STORE_DATA1 || curr_state == `STORE_DATA2)? 1 : 0;
//------------------------ Combinational Circuit --------------------------------//
//--------------------------------- Read Data -----------------------------------------//

always@(*) begin
    a16_1	=	Matrix_Data[0][255:240];
    a15_1	=	Matrix_Data[0][239:224];
    a14_1	=	Matrix_Data[0][223:208];
    a13_1	=	Matrix_Data[0][207:192];
    a12_1	=	Matrix_Data[0][191:176];
    a11_1	=	Matrix_Data[0][175:160];
    a10_1	=	Matrix_Data[0][159:144];
    a9_1	=	Matrix_Data[0][143:128];
    a8_1	=	Matrix_Data[0][127:112];
    a7_1	=	Matrix_Data[0][111:96];
    a6_1	=	Matrix_Data[0][95:80];
    a5_1	=	Matrix_Data[0][79:64];
    a4_1	=	Matrix_Data[0][63:48];
    a3_1	=	Matrix_Data[0][47:32];
    a2_1	=	Matrix_Data[0][31:16];
    a1_1	=	Matrix_Data[0][15:0];
    a16_2	=	Matrix_Data[1][255:240];
    a15_2	=	Matrix_Data[1][239:224];
    a14_2	=	Matrix_Data[1][223:208];
    a13_2	=	Matrix_Data[1][207:192];
    a12_2	=	Matrix_Data[1][191:176];
    a11_2	=	Matrix_Data[1][175:160];
    a10_2	=	Matrix_Data[1][159:144];
    a9_2	=	Matrix_Data[1][143:128];
    a8_2	=	Matrix_Data[1][127:112];
    a7_2	=	Matrix_Data[1][111:96];
    a6_2	=	Matrix_Data[1][95:80];
    a5_2	=	Matrix_Data[1][79:64];
    a4_2	=	Matrix_Data[1][63:48];
    a3_2	=	Matrix_Data[1][47:32];
    a2_2	=	Matrix_Data[1][31:16];
    a1_2	=	Matrix_Data[1][15:0];
    a16_3	=	Matrix_Data[2][255:240];
    a15_3	=	Matrix_Data[2][239:224];
    a14_3	=	Matrix_Data[2][223:208];
    a13_3	=	Matrix_Data[2][207:192];
    a12_3	=	Matrix_Data[2][191:176];
    a11_3	=	Matrix_Data[2][175:160];
    a10_3	=	Matrix_Data[2][159:144];
    a9_3	=	Matrix_Data[2][143:128];
    a8_3	=	Matrix_Data[2][127:112];
    a7_3	=	Matrix_Data[2][111:96];
    a6_3	=	Matrix_Data[2][95:80];
    a5_3	=	Matrix_Data[2][79:64];
    a4_3	=	Matrix_Data[2][63:48];
    a3_3	=	Matrix_Data[2][47:32];
    a2_3	=	Matrix_Data[2][31:16];
    a1_3	=	Matrix_Data[2][15:0];
    a16_4	=	Matrix_Data[3][255:240];
    a15_4	=	Matrix_Data[3][239:224];
    a14_4	=	Matrix_Data[3][223:208];
    a13_4	=	Matrix_Data[3][207:192];
    a12_4	=	Matrix_Data[3][191:176];
    a11_4	=	Matrix_Data[3][175:160];
    a10_4	=	Matrix_Data[3][159:144];
    a9_4	=	Matrix_Data[3][143:128];
    a8_4	=	Matrix_Data[3][127:112];
    a7_4	=	Matrix_Data[3][111:96];
    a6_4	=	Matrix_Data[3][95:80];
    a5_4	=	Matrix_Data[3][79:64];
    a4_4	=	Matrix_Data[3][63:48];
    a3_4	=	Matrix_Data[3][47:32];
    a2_4	=	Matrix_Data[3][31:16];
    a1_4	=	Matrix_Data[3][15:0];
    a16_5	=	Matrix_Data[4][255:240];
    a15_5	=	Matrix_Data[4][239:224];
    a14_5	=	Matrix_Data[4][223:208];
    a13_5	=	Matrix_Data[4][207:192];
    a12_5	=	Matrix_Data[4][191:176];
    a11_5	=	Matrix_Data[4][175:160];
    a10_5	=	Matrix_Data[4][159:144];
    a9_5	=	Matrix_Data[4][143:128];
    a8_5	=	Matrix_Data[4][127:112];
    a7_5	=	Matrix_Data[4][111:96];
    a6_5	=	Matrix_Data[4][95:80];
    a5_5	=	Matrix_Data[4][79:64];
    a4_5	=	Matrix_Data[4][63:48];
    a3_5	=	Matrix_Data[4][47:32];
    a2_5	=	Matrix_Data[4][31:16];
    a1_5	=	Matrix_Data[4][15:0];
    a16_6	=	Matrix_Data[5][255:240];
    a15_6	=	Matrix_Data[5][239:224];
    a14_6	=	Matrix_Data[5][223:208];
    a13_6	=	Matrix_Data[5][207:192];
    a12_6	=	Matrix_Data[5][191:176];
    a11_6	=	Matrix_Data[5][175:160];
    a10_6	=	Matrix_Data[5][159:144];
    a9_6	=	Matrix_Data[5][143:128];
    a8_6	=	Matrix_Data[5][127:112];
    a7_6	=	Matrix_Data[5][111:96];
    a6_6	=	Matrix_Data[5][95:80];
    a5_6	=	Matrix_Data[5][79:64];
    a4_6	=	Matrix_Data[5][63:48];
    a3_6	=	Matrix_Data[5][47:32];
    a2_6	=	Matrix_Data[5][31:16];
    a1_6	=	Matrix_Data[5][15:0];
    a16_7	=	Matrix_Data[6][255:240];
    a15_7	=	Matrix_Data[6][239:224];
    a14_7	=	Matrix_Data[6][223:208];
    a13_7	=	Matrix_Data[6][207:192];
    a12_7	=	Matrix_Data[6][191:176];
    a11_7	=	Matrix_Data[6][175:160];
    a10_7	=	Matrix_Data[6][159:144];
    a9_7	=	Matrix_Data[6][143:128];
    a8_7	=	Matrix_Data[6][127:112];
    a7_7	=	Matrix_Data[6][111:96];
    a6_7	=	Matrix_Data[6][95:80];
    a5_7	=	Matrix_Data[6][79:64];
    a4_7	=	Matrix_Data[6][63:48];
    a3_7	=	Matrix_Data[6][47:32];
    a2_7	=	Matrix_Data[6][31:16];
    a1_7	=	Matrix_Data[6][15:0];
    a16_8	=	Matrix_Data[7][255:240];
    a15_8	=	Matrix_Data[7][239:224];
    a14_8	=	Matrix_Data[7][223:208];
    a13_8	=	Matrix_Data[7][207:192];
    a12_8	=	Matrix_Data[7][191:176];
    a11_8	=	Matrix_Data[7][175:160];
    a10_8	=	Matrix_Data[7][159:144];
    a9_8	=	Matrix_Data[7][143:128];
    a8_8	=	Matrix_Data[7][127:112];
    a7_8	=	Matrix_Data[7][111:96];
    a6_8	=	Matrix_Data[7][95:80];
    a5_8	=	Matrix_Data[7][79:64];
    a4_8	=	Matrix_Data[7][63:48];
    a3_8	=	Matrix_Data[7][47:32];
    a2_8	=	Matrix_Data[7][31:16];
    a1_8	=	Matrix_Data[7][15:0];
    a16_9	=	Matrix_Data[8][255:240];
    a15_9	=	Matrix_Data[8][239:224];
    a14_9	=	Matrix_Data[8][223:208];
    a13_9	=	Matrix_Data[8][207:192];
    a12_9	=	Matrix_Data[8][191:176];
    a11_9	=	Matrix_Data[8][175:160];
    a10_9	=	Matrix_Data[8][159:144];
    a9_9	=	Matrix_Data[8][143:128];
    a8_9	=	Matrix_Data[8][127:112];
    a7_9	=	Matrix_Data[8][111:96];
    a6_9	=	Matrix_Data[8][95:80];
    a5_9	=	Matrix_Data[8][79:64];
    a4_9	=	Matrix_Data[8][63:48];
    a3_9	=	Matrix_Data[8][47:32];
    a2_9	=	Matrix_Data[8][31:16];
    a1_9	=	Matrix_Data[8][15:0];
    a16_10	=	Matrix_Data[9][255:240];
    a15_10	=	Matrix_Data[9][239:224];
    a14_10	=	Matrix_Data[9][223:208];
    a13_10	=	Matrix_Data[9][207:192];
    a12_10	=	Matrix_Data[9][191:176];
    a11_10	=	Matrix_Data[9][175:160];
    a10_10	=	Matrix_Data[9][159:144];
    a9_10	=	Matrix_Data[9][143:128];
    a8_10	=	Matrix_Data[9][127:112];
    a7_10	=	Matrix_Data[9][111:96];
    a6_10	=	Matrix_Data[9][95:80];
    a5_10	=	Matrix_Data[9][79:64];
    a4_10	=	Matrix_Data[9][63:48];
    a3_10	=	Matrix_Data[9][47:32];
    a2_10	=	Matrix_Data[9][31:16];
    a1_10	=	Matrix_Data[9][15:0];
    a16_11	=	Matrix_Data[10][255:240];
    a15_11	=	Matrix_Data[10][239:224];
    a14_11	=	Matrix_Data[10][223:208];
    a13_11	=	Matrix_Data[10][207:192];
    a12_11	=	Matrix_Data[10][191:176];
    a11_11	=	Matrix_Data[10][175:160];
    a10_11	=	Matrix_Data[10][159:144];
    a9_11	=	Matrix_Data[10][143:128];
    a8_11	=	Matrix_Data[10][127:112];
    a7_11	=	Matrix_Data[10][111:96];
    a6_11	=	Matrix_Data[10][95:80];
    a5_11	=	Matrix_Data[10][79:64];
    a4_11	=	Matrix_Data[10][63:48];
    a3_11	=	Matrix_Data[10][47:32];
    a2_11	=	Matrix_Data[10][31:16];
    a1_11	=	Matrix_Data[10][15:0];
    a16_12	=	Matrix_Data[11][255:240];
    a15_12	=	Matrix_Data[11][239:224];
    a14_12	=	Matrix_Data[11][223:208];
    a13_12	=	Matrix_Data[11][207:192];
    a12_12	=	Matrix_Data[11][191:176];
    a11_12	=	Matrix_Data[11][175:160];
    a10_12	=	Matrix_Data[11][159:144];
    a9_12	=	Matrix_Data[11][143:128];
    a8_12	=	Matrix_Data[11][127:112];
    a7_12	=	Matrix_Data[11][111:96];
    a6_12	=	Matrix_Data[11][95:80];
    a5_12	=	Matrix_Data[11][79:64];
    a4_12	=	Matrix_Data[11][63:48];
    a3_12	=	Matrix_Data[11][47:32];
    a2_12	=	Matrix_Data[11][31:16];
    a1_12	=	Matrix_Data[11][15:0];
    a16_13	=	Matrix_Data[12][255:240];
    a15_13	=	Matrix_Data[12][239:224];
    a14_13	=	Matrix_Data[12][223:208];
    a13_13	=	Matrix_Data[12][207:192];
    a12_13	=	Matrix_Data[12][191:176];
    a11_13	=	Matrix_Data[12][175:160];
    a10_13	=	Matrix_Data[12][159:144];
    a9_13	=	Matrix_Data[12][143:128];
    a8_13	=	Matrix_Data[12][127:112];
    a7_13	=	Matrix_Data[12][111:96];
    a6_13	=	Matrix_Data[12][95:80];
    a5_13	=	Matrix_Data[12][79:64];
    a4_13	=	Matrix_Data[12][63:48];
    a3_13	=	Matrix_Data[12][47:32];
    a2_13	=	Matrix_Data[12][31:16];
    a1_13	=	Matrix_Data[12][15:0];
    a16_14	=	Matrix_Data[13][255:240];
    a15_14	=	Matrix_Data[13][239:224];
    a14_14	=	Matrix_Data[13][223:208];
    a13_14	=	Matrix_Data[13][207:192];
    a12_14	=	Matrix_Data[13][191:176];
    a11_14	=	Matrix_Data[13][175:160];
    a10_14	=	Matrix_Data[13][159:144];
    a9_14	=	Matrix_Data[13][143:128];
    a8_14	=	Matrix_Data[13][127:112];
    a7_14	=	Matrix_Data[13][111:96];
    a6_14	=	Matrix_Data[13][95:80];
    a5_14	=	Matrix_Data[13][79:64];
    a4_14	=	Matrix_Data[13][63:48];
    a3_14	=	Matrix_Data[13][47:32];
    a2_14	=	Matrix_Data[13][31:16];
    a1_14	=	Matrix_Data[13][15:0];
    a16_15	=	Matrix_Data[14][255:240];
    a15_15	=	Matrix_Data[14][239:224];
    a14_15	=	Matrix_Data[14][223:208];
    a13_15	=	Matrix_Data[14][207:192];
    a12_15	=	Matrix_Data[14][191:176];
    a11_15	=	Matrix_Data[14][175:160];
    a10_15	=	Matrix_Data[14][159:144];
    a9_15	=	Matrix_Data[14][143:128];
    a8_15	=	Matrix_Data[14][127:112];
    a7_15	=	Matrix_Data[14][111:96];
    a6_15	=	Matrix_Data[14][95:80];
    a5_15	=	Matrix_Data[14][79:64];
    a4_15	=	Matrix_Data[14][63:48];
    a3_15	=	Matrix_Data[14][47:32];
    a2_15	=	Matrix_Data[14][31:16];
    a1_15	=	Matrix_Data[14][15:0];
    a16_16	=	Matrix_Data[15][255:240];
    a15_16	=	Matrix_Data[15][239:224];
    a14_16	=	Matrix_Data[15][223:208];
    a13_16	=	Matrix_Data[15][207:192];
    a12_16	=	Matrix_Data[15][191:176];
    a11_16	=	Matrix_Data[15][175:160];
    a10_16	=	Matrix_Data[15][159:144];
    a9_16	=	Matrix_Data[15][143:128];
    a8_16	=	Matrix_Data[15][127:112];
    a7_16	=	Matrix_Data[15][111:96];
    a6_16	=	Matrix_Data[15][95:80];
    a5_16	=	Matrix_Data[15][79:64];
    a4_16	=	Matrix_Data[15][63:48];
    a3_16	=	Matrix_Data[15][47:32];
    a2_16	=	Matrix_Data[15][31:16];
    a1_16	=	Matrix_Data[15][15:0];
end

always@(*) begin
    b16		=	B_Data[255:240];
    b15		=	B_Data[239:224];
    b14		=	B_Data[223:208];
    b13		=	B_Data[207:192];
    b12		=	B_Data[191:176];
    b11		=	B_Data[175:160];
    b10 	=	B_Data[159:144];
    b9 		=	B_Data[143:128];
    b8 		=	B_Data[127:112];
    b7 		=	B_Data[111:96];
    b6 		=	B_Data[95:80];
    b5 		=	B_Data[79:64];
    b4		=	B_Data[63:48];
    b3		=	B_Data[47:32];
    b2		=	B_Data[31:16];
    b1		=	B_Data[15:0];
end

//-------------------------------------------------------------------------------------//
// Next state logic
always@(*) begin
	case(curr_state)
		`IDLE		:	next_state = (i_module_en)? `READ : `IDLE;
		`READ		:	next_state = (read_finish)? `SET_X	: `READ;
		`SET_X		:	next_state = (counter == 4'd15)? `WAIT_CYCLE : `SET_X;
		`WAIT_CYCLE	:	next_state = `COMPUTE_X0;
		`COMPUTE_X0	:	next_state = (counter2 != 5'd17)? `COMPUTE_X0 : `COMPUTE_X1;
		`COMPUTE_X1 :	next_state = (counter2 != 5'd17)? `COMPUTE_X1 : `COMPUTE_X2;
		`COMPUTE_X2 :	next_state = (counter2 != 5'd17)? `COMPUTE_X2 : `COMPUTE_X3;
		`COMPUTE_X3 :	next_state = (counter2 != 5'd17)? `COMPUTE_X3 : `COMPUTE_X4;
		`COMPUTE_X4 :	next_state = (counter2 != 5'd17)? `COMPUTE_X4 : `COMPUTE_X5;
		`COMPUTE_X5 :	next_state = (counter2 != 5'd17)? `COMPUTE_X5 : `COMPUTE_X6;
		`COMPUTE_X6 :	next_state = (counter2 != 5'd17)? `COMPUTE_X6 : `COMPUTE_X7;
		`COMPUTE_X7 :	next_state = (counter2 != 5'd17)? `COMPUTE_X7 : `COMPUTE_X8;
		`COMPUTE_X8 :	next_state = (counter2 != 5'd17)? `COMPUTE_X8 : `COMPUTE_X9;
		`COMPUTE_X9 :	next_state = (counter2 != 5'd17)? `COMPUTE_X9 : `COMPUTE_X10;
		`COMPUTE_X10:	next_state = (counter2 != 5'd17)? `COMPUTE_X10: `COMPUTE_X11;
		`COMPUTE_X11:	next_state = (counter2 != 5'd17)? `COMPUTE_X11: `COMPUTE_X12;
		`COMPUTE_X12:	next_state = (counter2 != 5'd17)? `COMPUTE_X12: `COMPUTE_X13;
		`COMPUTE_X13:	next_state = (counter2 != 5'd17)? `COMPUTE_X13: `COMPUTE_X14;
		`COMPUTE_X14:	next_state = (counter2 != 5'd17)? `COMPUTE_X14: `COMPUTE_X15;
		`COMPUTE_X15:	next_state = (counter2 != 5'd17)? `COMPUTE_X15: (counter == 0)? `STORE_DATA1 : `COMPUTE_X0;		// compute 16 times then goto store_data.
		`STORE_DATA1 :	next_state = `STORE_DATA2; // store_data need 16 cycle to finish.
		`STORE_DATA2 :	next_state = (counter == 4'd15)? `IDLE		 : `STORE_DATA2; // store_data need 16 cycle to finish.
		default		:	next_state = `IDLE;
	endcase
end

// Control address and data wanted to store into Solution Memory.

always@(*) begin
	if(curr_state == `STORE_DATA1 | curr_state == `STORE_DATA2)
		o_x_data		=	X_Data[counter];
	else 
		o_x_data		=	0;
end

// To initial X_value
always@(*) begin
	if(curr_state == `SET_X) 
		set_X	=	B_factor * aX_X;
	else 
		set_X	=	0;
end

always@(*)begin
	B_minus	= (counter2 != 5'd15)? 0 : B_factor_16 - ((((aX_1 + aX_2) + (aX_3 + aX_4)) + ((aX_5 + aX_6) + (aX_7 + aX_8))) + ((aX_9 + (aX_10 + aX_11)) + ((aX_12 + aX_13) + (aX_14 + aX_15))));
end


always@(*) begin
	case(curr_state)
		`SET_X	: begin
			case(counter)
			0		:	aX_X = 	a1_1;
			1		:	aX_X = 	a2_2;
			2		:	aX_X = 	a3_3;
			3		:	aX_X = 	a4_4;
			4		:	aX_X = 	a5_5;
			5		:	aX_X = 	a6_6;
			6		:	aX_X = 	a7_7;
			7		:	aX_X = 	a8_8;
			8		:	aX_X = 	a9_9;
			9		:	aX_X = 	a10_10;
			10		:	aX_X = 	a11_11;
			11		:	aX_X = 	a12_12;
			12		:	aX_X = 	a13_13;
			13		:	aX_X = 	a14_14;
			14		:	aX_X = 	a15_15;
			15		:	aX_X = 	a16_16;
			endcase
		end
		`COMPUTE_X0	:	aX_X =	a1_1;
		`COMPUTE_X1	:	aX_X =	a2_2;
		`COMPUTE_X2	:	aX_X =	a3_3;
		`COMPUTE_X3	:	aX_X =	a4_4;
		`COMPUTE_X4	:	aX_X =	a5_5;
		`COMPUTE_X5	:	aX_X =	a6_6;
		`COMPUTE_X6	:	aX_X =	a7_7;
		`COMPUTE_X7	:	aX_X =	a8_8;
		`COMPUTE_X8	:	aX_X =	a9_9;
		`COMPUTE_X9	:	aX_X =	a10_10;
		`COMPUTE_X10:	aX_X =	a11_11;
		`COMPUTE_X11:	aX_X =	a12_12;
		`COMPUTE_X12:	aX_X =	a13_13;
		`COMPUTE_X13:	aX_X =	a14_14;
		`COMPUTE_X14:	aX_X =	a15_15;
		`COMPUTE_X15:	aX_X =	a16_16;
		default		:	aX_X =	0;
	endcase
end
//	a * X in every cycle
always@(*) begin
	if(counter2 != 5'd16)
		AX		=	A * X;
	else
		AX		=	A * b_minus;
end

//----------------------------------------------------------------------------// 
//------------------------ Sequential Circuit --------------------------------//
//----------------------------------------------------------------------------//
always@(posedge i_clk or posedge i_reset) begin
	if(i_reset)	begin
		aX_1  <=  0;  aX_2  <=  0;  aX_3  <=  0;  aX_4  <=  0;  aX_5  <=  0;  aX_6  <=  0;  
		aX_7  <=  0;  aX_8  <=  0;  aX_9  <=  0;  aX_10 <=  0;  aX_11 <=  0;  aX_12 <=  0;
		aX_13 <=  0;  aX_14 <=  0;  aX_15 <=  0;  b_minus <=  0;
	end
	else if(i_module_en) begin
		case(counter2)
		5'd0	:	aX_1 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd1	:	aX_2 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd2	:	aX_3 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd3	:	aX_4 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd4	:	aX_5 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd5	:	aX_6 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd6	:	aX_7 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd7	:	aX_8 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd8	:	aX_9 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd9	:	aX_10 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd10	:	aX_11 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd11	:	aX_12 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd12	:	aX_13 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd13	:	aX_14 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd14	:	aX_15 <= ((AX[47:31] == {17{1'b1}}) || (AX[47:31] == {17{1'b0}}))? $signed(AX[31:0]) : (AX[47])? low : high;
		5'd15	:	b_minus <=	((B_minus[35:31] == {5{1'b1}}) || (B_minus[35:31] == {5{1'b0}}))? $signed(B_minus[31:0]) : (B_minus[35])? low : high;
		default : 	begin end
		endcase
	end
	else begin
		aX_1  <=  aX_1;  aX_2  <=  aX_2;  aX_3  <=  aX_3;  aX_4  <=  aX_4;  aX_5  <=  aX_5;  aX_6  <=  aX_6;  
		aX_7  <=  aX_7;  aX_8  <=  aX_8;  aX_9  <=  aX_9;  aX_10 <=  aX_10;  aX_11 <=  aX_11;  aX_12 <=  aX_12;
		aX_13 <=  aX_13;  aX_14 <=  aX_14;  aX_15 <=  aX_15;  b_minus <=  b_minus;
	end
end

always@(posedge i_clk or posedge i_reset) begin
	if(i_reset) begin
		counter2	<=	0;
	end
	else if(i_module_en) begin
		case(curr_state)
		4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19: counter2	<=	(counter2 != 5'd17)? counter2 + 1 : 5'd0;
		default: begin	end
		endcase
	end
	else begin
		counter2	<=	counter2;
	end
end


always@(posedge i_clk or posedge i_reset) begin
	if(i_reset) begin
		A	<=	0;	X	<=	0;
	end
	else if(i_module_en) begin
		case(curr_state)
		`WAIT_CYCLE: begin
			A	<=	a1_2;	X	<=	X_Data[1];
		end
		`COMPUTE_X0 : begin
			case(counter2)
			0:  begin	A <= a1_3;  X <= X_Data[2]; end
			1:  begin	A <= a1_4;  X <= X_Data[3]; end
			2:  begin	A <= a1_5;  X <= X_Data[4]; end
			3:  begin	A <= a1_6;  X <= X_Data[5]; end
			4:  begin	A <= a1_7;  X <= X_Data[6]; end
			5:  begin	A <= a1_8;  X <= X_Data[7]; end
			6:  begin	A <= a1_9;  X <= X_Data[8]; end
			7:  begin	A <= a1_10; X <= X_Data[9]; end
			8:  begin	A <= a1_11; X <= X_Data[10]; end
			9:  begin	A <= a1_12; X <= X_Data[11]; end
			10: begin	A <= a1_13; X <= X_Data[12]; end
			11: begin	A <= a1_14; X <= X_Data[13]; end
			12: begin	A <= a1_15; X <= X_Data[14]; end
			13: begin	A <= a1_16; X <= X_Data[15]; end
			15: begin	A <= a1_1;	end
			17: begin	A <= a2_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X1 : begin
			case(counter2)
			0:  begin	A <= a2_3;  X <= X_Data[2]; end
			1:  begin	A <= a2_4;  X <= X_Data[3]; end
			2:  begin	A <= a2_5;  X <= X_Data[4]; end
			3:  begin	A <= a2_6;  X <= X_Data[5]; end
			4:  begin	A <= a2_7;  X <= X_Data[6]; end
			5:  begin	A <= a2_8;  X <= X_Data[7]; end
			6:  begin	A <= a2_9;  X <= X_Data[8]; end
			7:  begin	A <= a2_10; X <= X_Data[9]; end
			8:  begin	A <= a2_11; X <= X_Data[10]; end
			9:  begin	A <= a2_12; X <= X_Data[11]; end
			10: begin	A <= a2_13; X <= X_Data[12]; end
			11: begin	A <= a2_14; X <= X_Data[13]; end
			12: begin	A <= a2_15; X <= X_Data[14]; end
			13: begin	A <= a2_16; X <= X_Data[15]; end
			15: begin	A <= a2_2;	end
			17: begin	A <= a3_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X2 : begin
			case(counter2)
			0:  begin	A <= a3_2;  X <= X_Data[1]; end
			1:  begin	A <= a3_4;  X <= X_Data[3]; end
			2:  begin	A <= a3_5;  X <= X_Data[4]; end
			3:  begin	A <= a3_6;  X <= X_Data[5]; end
			4:  begin	A <= a3_7;  X <= X_Data[6]; end
			5:  begin	A <= a3_8;  X <= X_Data[7]; end
			6:  begin	A <= a3_9;  X <= X_Data[8]; end
			7:  begin	A <= a3_10; X <= X_Data[9]; end
			8:  begin	A <= a3_11; X <= X_Data[10]; end
			9:  begin	A <= a3_12; X <= X_Data[11]; end
			10: begin	A <= a3_13; X <= X_Data[12]; end
			11: begin	A <= a3_14; X <= X_Data[13]; end
			12: begin	A <= a3_15; X <= X_Data[14]; end
			13: begin	A <= a3_16; X <= X_Data[15]; end
			15: begin	A <= a3_3;	end
			17: begin	A <= a4_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X3 : begin
			case(counter2)
			0:  begin	A <= a4_2;  X <= X_Data[1]; end
			1:  begin	A <= a4_3;  X <= X_Data[2]; end
			2:  begin	A <= a4_5;  X <= X_Data[4]; end
			3:  begin	A <= a4_6;  X <= X_Data[5]; end
			4:  begin	A <= a4_7;  X <= X_Data[6]; end
			5:  begin	A <= a4_8;  X <= X_Data[7]; end
			6:  begin	A <= a4_9;  X <= X_Data[8]; end
			7:  begin	A <= a4_10; X <= X_Data[9]; end
			8:  begin	A <= a4_11; X <= X_Data[10]; end
			9:  begin	A <= a4_12; X <= X_Data[11]; end
			10: begin	A <= a4_13; X <= X_Data[12]; end
			11: begin	A <= a4_14; X <= X_Data[13]; end
			12: begin	A <= a4_15; X <= X_Data[14]; end
			13: begin	A <= a4_16; X <= X_Data[15]; end
			15: begin	A <= a4_4;	end
			17: begin	A <= a5_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X4 : begin
			case(counter2)
			0:  begin	A <= a5_2;  X <= X_Data[1]; end
			1:  begin	A <= a5_3;  X <= X_Data[2]; end
			2:  begin	A <= a5_4;  X <= X_Data[3]; end
			3:  begin	A <= a5_6;  X <= X_Data[5]; end
			4:  begin	A <= a5_7;  X <= X_Data[6]; end
			5:  begin	A <= a5_8;  X <= X_Data[7]; end
			6:  begin	A <= a5_9;  X <= X_Data[8]; end
			7:  begin	A <= a5_10; X <= X_Data[9]; end
			8:  begin	A <= a5_11; X <= X_Data[10]; end
			9:  begin	A <= a5_12; X <= X_Data[11]; end
			10: begin	A <= a5_13; X <= X_Data[12]; end
			11: begin	A <= a5_14; X <= X_Data[13]; end
			12: begin	A <= a5_15; X <= X_Data[14]; end
			13: begin	A <= a5_16; X <= X_Data[15]; end
			15: begin	A <= a5_5;	end
			17: begin	A <= a6_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X5 : begin
			case(counter2)
			0:  begin	A <= a6_2;  X <= X_Data[1]; end
			1:  begin	A <= a6_3;  X <= X_Data[2]; end
			2:  begin	A <= a6_4;  X <= X_Data[3]; end
			3:  begin	A <= a6_5;  X <= X_Data[4]; end
			4:  begin	A <= a6_7;  X <= X_Data[6]; end
			5:  begin	A <= a6_8;  X <= X_Data[7]; end
			6:  begin	A <= a6_9;  X <= X_Data[8]; end
			7:  begin	A <= a6_10; X <= X_Data[9]; end
			8:  begin	A <= a6_11; X <= X_Data[10]; end
			9:  begin	A <= a6_12; X <= X_Data[11]; end
			10: begin	A <= a6_13; X <= X_Data[12]; end
			11: begin	A <= a6_14; X <= X_Data[13]; end
			12: begin	A <= a6_15; X <= X_Data[14]; end
			13: begin	A <= a6_16; X <= X_Data[15]; end
			15: begin	A <= a6_6;	end
			17: begin	A <= a7_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X6 : begin
			case(counter2)
			0:  begin	A <= a7_2;  X <= X_Data[1]; end
			1:  begin	A <= a7_3;  X <= X_Data[2]; end
			2:  begin	A <= a7_4;  X <= X_Data[3]; end
			3:  begin	A <= a7_5;  X <= X_Data[4]; end
			4:  begin	A <= a7_6;  X <= X_Data[5]; end
			5:  begin	A <= a7_8;  X <= X_Data[7]; end
			6:  begin	A <= a7_9;  X <= X_Data[8]; end
			7:  begin	A <= a7_10; X <= X_Data[9]; end
			8:  begin	A <= a7_11; X <= X_Data[10]; end
			9:  begin	A <= a7_12; X <= X_Data[11]; end
			10: begin	A <= a7_13; X <= X_Data[12]; end
			11: begin	A <= a7_14; X <= X_Data[13]; end
			12: begin	A <= a7_15; X <= X_Data[14]; end
			13: begin	A <= a7_16; X <= X_Data[15]; end
			15: begin	A <= a7_7;	end
			17: begin	A <= a8_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X7 : begin
			case(counter2)
			0:  begin	A <= a8_2;  X <= X_Data[1]; end
			1:  begin	A <= a8_3;  X <= X_Data[2]; end
			2:  begin	A <= a8_4;  X <= X_Data[3]; end
			3:  begin	A <= a8_5;  X <= X_Data[4]; end
			4:  begin	A <= a8_6;  X <= X_Data[5]; end
			5:  begin	A <= a8_7;  X <= X_Data[6]; end
			6:  begin	A <= a8_9;  X <= X_Data[8]; end
			7:  begin	A <= a8_10; X <= X_Data[9]; end
			8:  begin	A <= a8_11; X <= X_Data[10]; end
			9:  begin	A <= a8_12; X <= X_Data[11]; end
			10: begin	A <= a8_13; X <= X_Data[12]; end
			11: begin	A <= a8_14; X <= X_Data[13]; end
			12: begin	A <= a8_15; X <= X_Data[14]; end
			13: begin	A <= a8_16; X <= X_Data[15]; end
			15: begin	A <= a8_8;	end
			17: begin	A <= a9_1;  X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X8 : begin
			case(counter2)
			0:  begin	A <= a9_2;  X <= X_Data[1]; end
			1:  begin	A <= a9_3;  X <= X_Data[2]; end
			2:  begin	A <= a9_4;  X <= X_Data[3]; end
			3:  begin	A <= a9_5;  X <= X_Data[4]; end
			4:  begin	A <= a9_6;  X <= X_Data[5]; end
			5:  begin	A <= a9_7;  X <= X_Data[6]; end
			6:  begin	A <= a9_8;  X <= X_Data[7]; end
			7:  begin	A <= a9_10; X <= X_Data[9]; end
			8:  begin	A <= a9_11; X <= X_Data[10]; end
			9:  begin	A <= a9_12; X <= X_Data[11]; end
			10: begin	A <= a9_13; X <= X_Data[12]; end
			11: begin	A <= a9_14; X <= X_Data[13]; end
			12: begin	A <= a9_15; X <= X_Data[14]; end
			13: begin	A <= a9_16; X <= X_Data[15]; end
			15: begin	A <= a9_9;	end
			17: begin	A <= a10_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X9 : begin
			case(counter2)
			0:  begin	A <= a10_2;  X <= X_Data[1]; end
			1:  begin	A <= a10_3;  X <= X_Data[2]; end
			2:  begin	A <= a10_4;  X <= X_Data[3]; end
			3:  begin	A <= a10_5;  X <= X_Data[4]; end
			4:  begin	A <= a10_6;  X <= X_Data[5]; end
			5:  begin	A <= a10_7;  X <= X_Data[6]; end
			6:  begin	A <= a10_8;  X <= X_Data[7]; end
			7:  begin	A <= a10_9;  X <= X_Data[8]; end
			8:  begin	A <= a10_11; X <= X_Data[10]; end
			9:  begin	A <= a10_12; X <= X_Data[11]; end
			10: begin	A <= a10_13; X <= X_Data[12]; end
			11: begin	A <= a10_14; X <= X_Data[13]; end
			12: begin	A <= a10_15; X <= X_Data[14]; end
			13: begin	A <= a10_16; X <= X_Data[15]; end
			15: begin	A <= a10_10;	end
			17: begin	A <= a11_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X10 : begin
			case(counter2)
			0:  begin	A <= a11_2;  X <= X_Data[1]; end
			1:  begin	A <= a11_3;  X <= X_Data[2]; end
			2:  begin	A <= a11_4;  X <= X_Data[3]; end
			3:  begin	A <= a11_5;  X <= X_Data[4]; end
			4:  begin	A <= a11_6;  X <= X_Data[5]; end
			5:  begin	A <= a11_7;  X <= X_Data[6]; end
			6:  begin	A <= a11_8;  X <= X_Data[7]; end
			7:  begin	A <= a11_9;  X <= X_Data[8]; end
			8:  begin	A <= a11_10; X <= X_Data[9]; end
			9:  begin	A <= a11_12; X <= X_Data[11]; end
			10: begin	A <= a11_13; X <= X_Data[12]; end
			11: begin	A <= a11_14; X <= X_Data[13]; end
			12: begin	A <= a11_15; X <= X_Data[14]; end
			13: begin	A <= a11_16; X <= X_Data[15]; end
			15: begin	A <= a11_11;	end
			17: begin	A <= a12_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X11 : begin
			case(counter2)
			0:  begin	A <= a12_2;  X <= X_Data[1]; end
			1:  begin	A <= a12_3;  X <= X_Data[2]; end
			2:  begin	A <= a12_4;  X <= X_Data[3]; end
			3:  begin	A <= a12_5;  X <= X_Data[4]; end
			4:  begin	A <= a12_6;  X <= X_Data[5]; end
			5:  begin	A <= a12_7;  X <= X_Data[6]; end
			6:  begin	A <= a12_8;  X <= X_Data[7]; end
			7:  begin	A <= a12_9;  X <= X_Data[8]; end
			8:  begin	A <= a12_10; X <= X_Data[9]; end
			9:  begin	A <= a12_11; X <= X_Data[10]; end
			10: begin	A <= a12_13; X <= X_Data[12]; end
			11: begin	A <= a12_14; X <= X_Data[13]; end
			12: begin	A <= a12_15; X <= X_Data[14]; end
			13: begin	A <= a12_16; X <= X_Data[15]; end
			15: begin	A <= a12_12;	end
			17: begin	A <= a13_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X12 : begin
			case(counter2)
			0:  begin	A <= a13_2;  X <= X_Data[1]; end
			1:  begin	A <= a13_3;  X <= X_Data[2]; end
			2:  begin	A <= a13_4;  X <= X_Data[3]; end
			3:  begin	A <= a13_5;  X <= X_Data[4]; end
			4:  begin	A <= a13_6;  X <= X_Data[5]; end
			5:  begin	A <= a13_7;  X <= X_Data[6]; end
			6:  begin	A <= a13_8;  X <= X_Data[7]; end
			7:  begin	A <= a13_9;  X <= X_Data[8]; end
			8:  begin	A <= a13_10; X <= X_Data[9]; end
			9:  begin	A <= a13_11; X <= X_Data[10]; end
			10: begin	A <= a13_12; X <= X_Data[11]; end
			11: begin	A <= a13_14; X <= X_Data[13]; end
			12: begin	A <= a13_15; X <= X_Data[14]; end
			13: begin	A <= a13_16; X <= X_Data[15]; end
			15: begin	A <= a13_13;	end
			17: begin	A <= a14_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X13 : begin
			case(counter2)
			0:  begin	A <= a14_2;  X <= X_Data[1]; end
			1:  begin	A <= a14_3;  X <= X_Data[2]; end
			2:  begin	A <= a14_4;  X <= X_Data[3]; end
			3:  begin	A <= a14_5;  X <= X_Data[4]; end
			4:  begin	A <= a14_6;  X <= X_Data[5]; end
			5:  begin	A <= a14_7;  X <= X_Data[6]; end
			6:  begin	A <= a14_8;  X <= X_Data[7]; end
			7:  begin	A <= a14_9;  X <= X_Data[8]; end
			8:  begin	A <= a14_10; X <= X_Data[9]; end
			9:  begin	A <= a14_11; X <= X_Data[10]; end
			10: begin	A <= a14_12; X <= X_Data[11]; end
			11: begin	A <= a14_13; X <= X_Data[12]; end
			12: begin	A <= a14_15; X <= X_Data[14]; end
			13: begin	A <= a14_16; X <= X_Data[15]; end
			15: begin	A <= a14_14;	end
			17: begin	A <= a15_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X14 : begin
			case(counter2)
			0:  begin	A <= a15_2;  X <= X_Data[1]; end
			1:  begin	A <= a15_3;  X <= X_Data[2]; end
			2:  begin	A <= a15_4;  X <= X_Data[3]; end
			3:  begin	A <= a15_5;  X <= X_Data[4]; end
			4:  begin	A <= a15_6;  X <= X_Data[5]; end
			5:  begin	A <= a15_7;  X <= X_Data[6]; end
			6:  begin	A <= a15_8;  X <= X_Data[7]; end
			7:  begin	A <= a15_9;  X <= X_Data[8]; end
			8:  begin	A <= a15_10; X <= X_Data[9]; end
			9:  begin	A <= a15_11; X <= X_Data[10]; end
			10: begin	A <= a15_12; X <= X_Data[11]; end
			11: begin	A <= a15_13; X <= X_Data[12]; end
			12: begin	A <= a15_14; X <= X_Data[13]; end
			13: begin	A <= a15_16; X <= X_Data[15]; end
			15: begin	A <= a15_15;	end
			17: begin	A <= a16_1; X <= X_Data[0]; end
			default: begin	end
			endcase
		end
		`COMPUTE_X15 : begin
			case(counter2)
			0:  begin	A <= a16_2;  X <= X_Data[1]; end
			1:  begin	A <= a16_3;  X <= X_Data[2]; end
			2:  begin	A <= a16_4;  X <= X_Data[3]; end
			3:  begin	A <= a16_5;  X <= X_Data[4]; end
			4:  begin	A <= a16_6;  X <= X_Data[5]; end
			5:  begin	A <= a16_7;  X <= X_Data[6]; end
			6:  begin	A <= a16_8;  X <= X_Data[7]; end
			7:  begin	A <= a16_9;  X <= X_Data[8]; end
			8:  begin	A <= a16_10; X <= X_Data[9]; end
			9:  begin	A <= a16_11; X <= X_Data[10]; end
			10: begin	A <= a16_12; X <= X_Data[11]; end
			11: begin	A <= a16_13; X <= X_Data[12]; end
			12: begin	A <= a16_14; X <= X_Data[13]; end
			13: begin	A <= a16_15; X <= X_Data[14]; end
			15: begin	A <= a16_16;	end
			17: begin	A <= a1_2; X <= X_Data[1]; end
			default: begin	end
			endcase
		end
		default: begin end

		endcase
	end
	else begin
		A	<=	A;	X	<=	X;
	end
end

//integer j;
always@(posedge i_clk or posedge i_reset) begin
	if(i_reset) begin
		B_factor		<=	0;
		counter			<=	0;
		count_matrix	<=	6'b111111;
		X_Data[0]		<=	0;	X_Data[1]		<=	0;	X_Data[2]		<=	0;
		X_Data[3]		<=	0;	X_Data[4]		<=	0;	X_Data[5]		<=	0;
		X_Data[6]		<=	0;	X_Data[7]		<=	0;	X_Data[8]		<=	0;
		X_Data[9]		<=	0;	X_Data[10]		<=	0;	X_Data[11]		<=	0;
		X_Data[12]		<=	0;	X_Data[13]		<=	0;	X_Data[14]		<=	0;
		X_Data[15]		<=	0;
	end	
	else if(i_module_en) begin
		case(curr_state)
		`READ	: begin
			B_factor	<=	b1;
		end
		`SET_X		: begin
			counter		<=	counter	+ 1;
			case(counter)
			0 : begin 
				X_Data[0]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b2;
			end
			1 : begin
				X_Data[1]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b3;
			end
			2 : begin
				X_Data[2]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b4;
			end
			3 : begin
				X_Data[3]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b5;
			end
			4 : begin
				X_Data[4]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b6;
			end
			5 : begin
				X_Data[5]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b7;
			end
			6 : begin
				X_Data[6]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b8;
			end
			7 : begin
				X_Data[7]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b9;
			end
			8 : begin
				X_Data[8]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b10;
			end
			9 : begin
				X_Data[9]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b11;
			end
			10: begin
				X_Data[10]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b12;
			end
			11: begin
				X_Data[11]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b13;
			end
			12: begin
				X_Data[12]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b14;
			end
			13: begin
				X_Data[13]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b15;
			end
			14: begin
				X_Data[14]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b16;
			end
			15: begin
				X_Data[15]	<=	(set_X[31:29] == {3{1'b1}} || set_X[31:29] == {3{1'b0}})? $signed({set_X[29:0], {2{1'b0}}}) : (set_X[31])? low : high;
				B_factor	<=	b1;
			end
			default: begin	end
			endcase
			//$display("---------------------------------------------------");
		end
		`WAIT_CYCLE : begin
			count_matrix	<=	count_matrix + 1;
		end
		`COMPUTE_X0	: begin
			if(counter2 == 5'd16) begin
				X_Data[0] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b2;
			end
		end
		`COMPUTE_X1	: begin
			if(counter2 == 5'd16) begin
				X_Data[1] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b3;
			end
		end
		`COMPUTE_X2	: begin
			if(counter2 == 5'd16) begin
				X_Data[2] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b4;
			end
		end
		`COMPUTE_X3	: begin
			if(counter2 == 5'd16) begin
				X_Data[3] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b5;
			end
		end
		`COMPUTE_X4	: begin
			if(counter2 == 5'd16) begin
				X_Data[4] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b6;
			end
		end
		`COMPUTE_X5	: begin
			if(counter2 == 5'd16) begin
				X_Data[5] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b7;
			end
		end
		`COMPUTE_X6	: begin
			if(counter2 == 5'd16) begin
				X_Data[6] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b8;
			end
		end
		`COMPUTE_X7	: begin
			if(counter2 == 5'd16) begin
				X_Data[7] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b9;
			end
		end
		`COMPUTE_X8	: begin
			if(counter2 == 5'd16) begin
				X_Data[8] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b10;
			end
		end
		`COMPUTE_X9	: begin
			if(counter2 == 5'd16) begin
				X_Data[9] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b11;
			end
		end
		`COMPUTE_X10	: begin
			if(counter2 == 5'd16) begin
				X_Data[10] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b12;
			end
		end
		`COMPUTE_X11	: begin	
			if(counter2 == 5'd16) begin
				X_Data[11] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b13;
			end
		end
		`COMPUTE_X12	: begin
			if(counter2 == 5'd16) begin
				X_Data[12] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b14;
			end
		end
		`COMPUTE_X13	: begin	
			if(counter2 == 5'd16) begin
				X_Data[13] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b15;
			end
		end
		`COMPUTE_X14	: begin	
			if(counter2 == 5'd16) begin
				X_Data[14] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b16;
				counter		<=	counter + 1;
			end
		end
		`COMPUTE_X15	: begin
			if(counter2 == 5'd16) begin
				X_Data[15] <=  ((AX[47:45] == {3{1'b1}}) || (AX[47:45] == {3{1'b0}}))? $signed(AX[45:14]) : (AX[47])? low : high;
				B_factor 	<=	b1;
			end
		end
		`STORE_DATA1, `STORE_DATA2: begin
			counter		<=	counter + 1;
		end
		default			: begin
			B_factor		<=	B_factor;
		end
		endcase
	end

	else begin
		B_factor		<=	B_factor;
		counter			<=	counter;
		count_matrix	<=	count_matrix;
		X_Data[0]	<=	X_Data[0];	X_Data[1]	<=	X_Data[1];	X_Data[2]	<=	X_Data[2];
		X_Data[3]	<=	X_Data[3];	X_Data[4]	<=	X_Data[4];	X_Data[5]	<=	X_Data[5];
		X_Data[6]	<=	X_Data[6];	X_Data[7]	<=	X_Data[7];	X_Data[8]	<=	X_Data[8];
		X_Data[9]	<=	X_Data[9];	X_Data[10]	<=	X_Data[10];	X_Data[11]	<=	X_Data[11];
		X_Data[12]	<=	X_Data[12];	X_Data[13]	<=	X_Data[13];	X_Data[14]	<=	X_Data[14];
		X_Data[15]	<=	X_Data[15];
	end
end


// Control index
always@(posedge i_clk or posedge i_reset) begin
	if(i_reset)	begin
		index			<=	5'b11111;
		o_mem_addr_r	<=	0;
	end
	else if(i_module_en) begin
		if(i_mem_dout_vld) begin
			if(index != 5'd16)
				Matrix_Data[index]	<=	i_mem_dout;
			else
				B_Data				<=	i_mem_dout;
		end
		if(i_mem_rrdy & o_mem_rreq) begin
			index				<=	(index == 5'd16)? 5'b11111 : index + 1;	// if index = 16, read_finish and reset it as 0.
			o_mem_addr_r		<=	o_mem_addr_r + 1;
		end
		else if(curr_state	==	`SET_X) begin
			index				<=	5'b11111;
		end
	end
	else begin
		index			<=	index;
		o_mem_addr_r	<=	o_mem_addr_r;
	end
end

//	Control output
always@(posedge i_clk or posedge i_reset) begin
	if(i_reset)	
		o_x_addr	<=	0;
	else if(i_module_en) begin
		if(curr_state == `STORE_DATA1 | curr_state == `STORE_DATA2)
			o_x_addr	<=	o_x_addr + 1;
	end
	else begin
		o_x_addr	<=	o_x_addr;
	end
end

// Normal Sequential Circuit
always@(posedge i_clk or posedge i_reset) begin
	if(i_reset) 
		curr_state		<=	`IDLE;
	else if(i_module_en) begin
		curr_state		<=	next_state;
		//if(o_x_wen)	$display("Output = %d, %h", o_x_data, o_x_data);
	end
	else begin
		curr_state		<=	curr_state;
	end
end


endmodule
