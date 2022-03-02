// opcode definition
`define OP_Load			0
`define OP_Right		4
`define OP_Left			5
`define OP_Up			6
`define OP_Down			7
`define OP_Scale_Down	8
`define OP_Scale_Up		9
`define OP_Median_F		12
`define OP_YCbCr		13
`define OP_Census		14

// state define
`define START			0
`define OpReady			1
`define IDLE			2
`define LOAD			3
`define RIGHT			4
`define LEFT			5
`define UP				6
`define DOWN			7
`define SCALE_DOWN		8
`define SCALE_UP		9
`define MEDIAN_F1		10
`define MEDIAN_F2		11
`define MEDIAN_F3		12		// c
`define MEDIAN_F4		13		// d
`define MEDIAN_F5		14		// e
`define MEDIAN_F6		15		// f
`define MEDIAN_F7		16		// 10
//`define MEDIAN_F8		17
`define YCBCR			18
`define YCBCR_2			19
`define CENSUS_1		20
`define CENSUS_2		21
`define CENSUS_3		22
`define CENSUS_4		23
//`define CENSUS_5		31
`define WAIT_CYCLE1		24			// wait a cycle before display.
`define WAIT_CYCLE2		25			// wait a cycle before display.
`define DISPLAY_1		26			// Normal Display mode
`define DISPLAY_2		27			// wait a cycle after read_finish
`define Y_DISPLAY1		28
`define Y_DISPLAY2		29

`define FINISH			30


module ipdc (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [23:0] i_in_data,		// [23:16] -> R, [15:8] -> G, [7:0] -> B
	output        o_in_ready,
	output        o_out_valid,
	output [23:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

wire 		CEN_R, CEN_G, CEN_B;	// control signal for sram
wire		WEN_R, WEN_G, WEN_B; 	// control signal for sram
wire[7:0]	i_sram_R, i_sram_G, i_sram_B;	// input signal for Sram.
wire[7:0]	o_sram_R, o_sram_G, o_sram_B;	// output signal for Sram.
reg [7:0]	A;

reg [7:0]	origin;
reg [8:0]	right_plus1, right_plus2, right_plus3, right_plus4;
reg [8:0]	left_minus1, left_minus2, left_minus3;
reg [8:0]	Median_plus1, Median_plus2, Median_plus3, Median_plus4;
reg [8:0]	Median_minus1, Median_minus2, Median_minus3;

wire[7:0]	Addr_Load, Addr_Read, Addr_Display;
reg [23:0] 	register [36:0];		// register
reg [5:0] 	curr_state, next_state; // execute state
reg 		o_op_ready_w, o_op_ready_r;
reg [1:0]	image_size;				// 0 -> 16x16, 1 -> 8x8, 2 -> 4x4
reg 		load_enable, read_enable, shift_enable, origin_enable;
reg 		Up_enable, Down_enable, YCBCR_enable, Median_read_enable;
wire 		load_finish, read_finish;
reg 		o_out_valid_r, o_out_valid_w;
reg 		o_in_ready_r, o_in_ready_w;
reg [23:0]	o_out_data_r;
reg [23:0]	o_out_data_w;
reg [1:0]	shift_direction;				// 0->right, 1->left, 2->up, 3->down.
reg [10:0]	X1, X2, X3;
reg [7:0]	Y, Cb, Cr;

reg [5:0]	M11, M12, M13, M21, M22, M23, M31, M32, M33;
reg [7:0]	Median_origin;
wire[7:0]	Max1_R, Med1_R, Min1_R, Max2_R, Med2_R, Min2_R, Max3_R, Med3_R, Min3_R;
wire[7:0]	Max_of_Min_R, Med_of_Med_R, Min_of_Max_R;
wire[7:0]	Median_out_Data_R;
wire[7:0]	Max1_G, Med1_G, Min1_G, Max2_G, Med2_G, Min2_G, Max3_G, Med3_G, Min3_G;
wire[7:0]	Max_of_Min_G, Med_of_Med_G, Min_of_Max_G;
wire[7:0]	Median_out_Data_G;
wire[7:0]	Max1_B, Med1_B, Min1_B, Max2_B, Med2_B, Min2_B, Max3_B, Med3_B, Min3_B;
wire[7:0]	Max_of_Min_B, Med_of_Med_B, Min_of_Max_B;
wire[7:0]	Median_out_Data_B;

reg 		Census_enable;
reg [7:0]	Census_out_Data_R, Census_out_Data_G, Census_out_Data_B;
reg			Median_finish, Census_finish;
reg [7:0]	Census_origin;
reg [1:0]	counter;

reg			Median_loadReg_enable;
wire		Median_loadReg_finish;
wire[8:0]	Median_loadReg_Addr;

Median_LoadReg Median_Load(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.Median_loadReg_enable(Median_loadReg_enable),
	.origin_enable(origin_enable),
	.image_size(image_size),
	.origin(origin),
	.Addr_Read(Median_loadReg_Addr),
	.loadReg_finish(Median_loadReg_finish) 
);

reg			Census_loadReg_enable;
wire		Census_loadReg_finish;
wire[8:0]	Census_loadReg_Addr;

Median_LoadReg Census_Load(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.Median_loadReg_enable(Census_loadReg_enable),
	.origin_enable(origin_enable),
	.image_size(image_size),
	.origin(origin),
	.Addr_Read(Census_loadReg_Addr),
	.loadReg_finish(Census_loadReg_finish) 
);


// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

assign o_op_ready = o_op_ready_r;
assign {i_sram_R, i_sram_G, i_sram_B} = i_in_data;
assign o_in_ready = 1;										// may need to revise.
assign o_out_valid = o_out_valid_r;
assign o_out_data = o_out_data_r;
//assign o_out_data_w = (YCBCR_enable)? {Y, Cb, Cr} : {o_sram_R, o_sram_G, o_sram_B};

always@(*) begin
	if(Median_read_enable)
		o_out_data_w = {Median_out_Data_R, Median_out_Data_G, Median_out_Data_B};
	else if(YCBCR_enable)
		o_out_data_w = {Y, Cb, Cr};
	else if(Census_enable)
		o_out_data_w = {Census_out_Data_R, Census_out_Data_G, Census_out_Data_B};
	else
		o_out_data_w = {o_sram_R, o_sram_G, o_sram_B};
end

assign CEN_R = 0;
assign CEN_G = 0;
assign CEN_B = 0;

assign WEN_R = ((curr_state == `LOAD) & (!load_finish))?  0 : 1;
assign WEN_G = ((curr_state == `LOAD) & (!load_finish))?  0 : 1;
assign WEN_B = ((curr_state == `LOAD) & (!load_finish))?  0 : 1;


// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

// Census_origin
always@(*) begin
	case(image_size)
	2'd0: Census_origin = (counter == 0)? Median_origin - 8'd13 : Median_origin - 8'd1;
	2'd1: Census_origin = (counter == 0)? Median_origin - 8'd30 : Median_origin - 8'd2;
	2'd2: Census_origin = Median_origin - 8'd4;
	default: Census_origin = 0;
	endcase
end

// Census_out_Data_R, Census_out_Data_G, Census_out_Data_B;
always@(*) begin
	
	Census_out_Data_R[7] = (register[M11][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[6] = (register[M12][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[5] = (register[M13][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[4] = (register[M21][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[3] = (register[M23][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[2] = (register[M31][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[1] = (register[M32][23:16] > register[M22][23:16])? 1 : 0;
	Census_out_Data_R[0] = (register[M33][23:16] > register[M22][23:16])? 1 : 0;

	Census_out_Data_G[7] = (register[M11][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[6] = (register[M12][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[5] = (register[M13][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[4] = (register[M21][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[3] = (register[M23][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[2] = (register[M31][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[1] = (register[M32][15:8] > register[M22][15:8])? 1 : 0;
	Census_out_Data_G[0] = (register[M33][15:8] > register[M22][15:8])? 1 : 0;

	Census_out_Data_B[7] = (register[M11][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[6] = (register[M12][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[5] = (register[M13][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[4] = (register[M21][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[3] = (register[M23][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[2] = (register[M31][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[1] = (register[M32][7:0] > register[M22][7:0])? 1 : 0;
	Census_out_Data_B[0] = (register[M33][7:0] > register[M22][7:0])? 1 : 0;
end

// Control Address of A
always@(*) begin
	if(load_enable)
		A = Addr_Load;
	else if(read_enable)
		A = Addr_Read;
	else if(Median_loadReg_enable)
		A = Median_loadReg_Addr;
	else if(Census_loadReg_enable)
		A = Census_loadReg_Addr;
	else
		A = 0;
end

// Compute YCBCR Display
always@(*) begin
	X1 	= (o_sram_R << 1) + o_sram_G + (o_sram_G << 2);
	X2	= ( (o_sram_B << 2) - (o_sram_G << 1) ) + (11'd1024 - o_sram_R);
	X3	= (((o_sram_R << 2) - (o_sram_B) + 11'd1024) - (o_sram_G + (o_sram_G << 1)));

	Y 	= (X1[2])?	(X1 >> 3) + 8'd1 : (X1 >> 3);
	Cb	= (X2[2])?	(X2 >> 3) + 8'd1 : (X2 >> 3);
	Cr	= (X3[2])?	(X3 >> 3) + 8'd1 : (X3 >> 3);
end
// next state logic
always@(*) begin
	case(curr_state)
		`START			: next_state = `OpReady;
		`OpReady		: next_state = `IDLE;
		`IDLE: begin
			if(i_op_valid) begin
				case(i_op_mode)
					`OP_Load		:	next_state = `LOAD;
					`OP_Right		:	next_state = `RIGHT;
					`OP_Left		:	next_state = `LEFT;
					`OP_Up			:	next_state = `UP;
					`OP_Down		:	next_state = `DOWN;
					`OP_Scale_Down	:	next_state = `SCALE_DOWN;	 
					`OP_Scale_Up	:	next_state = `SCALE_UP;
					`OP_Median_F	:	next_state = `MEDIAN_F1;
					`OP_YCbCr		:	next_state = `YCBCR;
					`OP_Census		:	next_state = `CENSUS_1;
					default			:	next_state = `IDLE;
				endcase
			end
			else 
				next_state = `IDLE;
		end

		`LOAD		: next_state = (load_finish)? `FINISH : `LOAD;
		`RIGHT		: next_state = `WAIT_CYCLE1;
		`LEFT		: next_state = `WAIT_CYCLE1;
		`UP			: next_state = `WAIT_CYCLE1;
		`DOWN		: next_state = `WAIT_CYCLE1;
		`WAIT_CYCLE1: next_state = `WAIT_CYCLE2;			// temporary.
		`WAIT_CYCLE2: next_state = `DISPLAY_1;

		`SCALE_DOWN	: next_state = `WAIT_CYCLE1;
		`SCALE_UP	: next_state = `WAIT_CYCLE1;
		`MEDIAN_F1	: next_state = `MEDIAN_F2;
		`MEDIAN_F2	: next_state = (Median_loadReg_finish)? `MEDIAN_F3 : `MEDIAN_F2;
		`MEDIAN_F3	: next_state = `MEDIAN_F4;
		`MEDIAN_F4	: next_state = `MEDIAN_F5;
		`MEDIAN_F5	: next_state = `MEDIAN_F6;
		`MEDIAN_F6	: next_state = (image_size == 2)? `FINISH : `MEDIAN_F7;
		`MEDIAN_F7	: next_state = (Median_finish)? `FINISH : `MEDIAN_F7;
		`YCBCR		: next_state = `YCBCR_2;
		`YCBCR_2	: next_state = `Y_DISPLAY1;
		`CENSUS_1	: next_state = `CENSUS_2;
		`CENSUS_2	: next_state = (Census_loadReg_finish)? `CENSUS_3 : `CENSUS_2;
		`CENSUS_3	: next_state = `CENSUS_4;
		`CENSUS_4	: next_state = (Census_finish)? `FINISH : `CENSUS_4;
		`DISPLAY_1	: next_state = (read_finish)? `DISPLAY_2  : `DISPLAY_1;
		`DISPLAY_2	: next_state = `FINISH;
		`Y_DISPLAY1	: next_state = (read_finish)? `Y_DISPLAY2 : `Y_DISPLAY1;
		`Y_DISPLAY2	: next_state = `FINISH;
		`FINISH		: next_state = `OpReady;
		default		: next_state = `OpReady;

	endcase
end

// boundary and control signal
always@(*) begin
	// boundary
	right_plus1	= origin + 9'd1;
	right_plus2	= origin + 9'd2;
	right_plus3	= origin + 9'd3;
	right_plus4	= origin + 9'd4;
	left_minus1 = origin - 9'd1;
	left_minus2 = origin - 9'd2;
	left_minus3 = origin - 9'd3;

	Median_plus1  = Median_origin + 9'd1;
	Median_plus2  = Median_origin + 9'd2;
	Median_plus3  = Median_origin + 9'd3;
	Median_plus4  = Median_origin + 9'd4;
	Median_minus1 = Median_origin - 9'd1;
	Median_minus2 = Median_origin - 9'd2;
	Median_minus3 = Median_origin - 9'd3;

	// other control signal
	o_op_ready_w = (curr_state == `OpReady)?	1 : 0;
end

// shift direction
always@(*) begin
	case(curr_state)
		`RIGHT	: shift_direction = 2'd0;	// 0->right, 1->left, 2->up, 3->down.
		`LEFT	: shift_direction = 2'd1;	// 0->right, 1->left, 2->up, 3->down.
		`UP		: shift_direction = 2'd2;	// 0->right, 1->left, 2->up, 3->down.
		`DOWN	: shift_direction = 2'd3;	// 0->right, 1->left, 2->up, 3->down.
		default : shift_direction = 2'd0;
	endcase
end

// control Median_finish
always@(*) begin
	case(image_size)
		2'd0 : Median_finish = (Median_origin == origin + 8'd66)? 1 : 0;
		2'd1 : Median_finish = (Median_origin == origin + 8'd96)? 1 : 0;
		2'd2 : Median_finish = (curr_state == `MEDIAN_F7)	? 1 : 0;
		default : Median_finish = 0;
	endcase
end

always@(*) begin
	case(image_size)
		2'd0 : Census_finish = (Median_origin == origin + 8'd51)? 1 : 0;
		2'd1 : Census_finish = (Median_origin == origin + 8'd34)? 1 : 0;
		2'd2 : Census_finish = (Median_origin == origin)?		  1 : 0;
		default : Census_finish = 0;
	endcase
end
// state output
always@(*) begin
	case(curr_state)
		`START		: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end	
		`OpReady	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`IDLE		: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`LOAD		: begin
			if(!load_finish) begin
				shift_enable = 0; 	read_enable = 0;
				o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
				YCBCR_enable = 0;	Down_enable = 0;	load_enable = 1;
				Median_read_enable 	= 0;	 Census_enable = 0;
				Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
			end
			else begin
				shift_enable = 0; 	read_enable = 0;
				o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
				YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
				Median_read_enable 	= 0;	 Census_enable = 0;
				Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
			end
		end
		`RIGHT		: begin
			shift_enable = 1; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;	
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;	
		end
		`LEFT		: 	begin
			shift_enable = 1; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;	
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;		
		end
		`UP			: 	begin
			shift_enable = 1; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;	
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;			
		end
		`DOWN		: begin
			shift_enable = 1; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;	
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;			
		end
		
		`WAIT_CYCLE1: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 1; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`WAIT_CYCLE2: begin
			shift_enable = 0; 	read_enable = 1;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`SCALE_DOWN	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 1;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`SCALE_UP	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 1;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`MEDIAN_F1	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 1; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`MEDIAN_F2	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 1;	 Census_loadReg_enable = 0;	// start load SramData to Reg until loadReg_finish
		end
		
		`MEDIAN_F3	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 1;	 Census_enable = 0;
			Median_loadReg_enable = 0;	 Census_loadReg_enable = 0;	// start load SramData to Reg until loadReg_finish
		end
		`MEDIAN_F4	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 1;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`MEDIAN_F5	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 1;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`MEDIAN_F6	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 1;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 1;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`MEDIAN_F7	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 1;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 1;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		
		`YCBCR		: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 1; 	
			YCBCR_enable = 1;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`YCBCR_2	: begin
			shift_enable = 0; 	read_enable = 1;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 1;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`CENSUS_1	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 1; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`CENSUS_2	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 1;
		end
		`CENSUS_3	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 1;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 1;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`CENSUS_4	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = (image_size != 2'd2)? 1 : 0;	
			Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 1;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end

		`DISPLAY_1	: begin
			shift_enable = 0; 	read_enable = 1;
			o_out_valid_w = 1;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`DISPLAY_2	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = (image_size != 2'd2)? 1 : 0;	
			Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`Y_DISPLAY1	: begin
			shift_enable = 0; 	read_enable = 1;
			o_out_valid_w = 1;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 1;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	 Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`Y_DISPLAY2	: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = (image_size != 2'd2)? 1 : 0;
			Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 1;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		`FINISH		: 	begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
		default		: begin
			shift_enable = 0; 	read_enable = 0;
			o_out_valid_w = 0;	Up_enable = 0;		origin_enable = 0; 	
			YCBCR_enable = 0;	Down_enable = 0;	load_enable = 0;
			Median_read_enable 	= 0;	Census_enable = 0;
			Median_loadReg_enable = 0; 	 Census_loadReg_enable = 0;
		end
	endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

// shift to next_address logic
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		origin		<= 0;
	end
	else if(shift_enable) begin
		case(image_size)
		2'd0 : begin		// 4 X 4
			case(shift_direction)		// 0->right, 1->left, 2->up, 3->down.
				2'd0 : origin	<= (right_plus4[3:0] == 0)? origin : origin + 8'd1;	// right
				2'd1 : origin	<= (origin[3:0] == 0)? origin : origin - 8'd1;	// left
				2'd2 : origin	<= (origin < 8'd16) ? origin : origin - 8'd16;	// up
				2'd3 : origin	<= (origin >= 8'd192) ? origin : origin + 8'd16;	// down
			endcase
		end
		2'd1 : begin		// 2 X 2
			case(shift_direction)		// 0->right, 1->left, 2->up, 3->down.
				2'd0 : origin	<= ((right_plus3[3:0] == 0) | (right_plus4[3:0] == 0))? origin : origin + 8'd2;	// right
				2'd1 : origin	<= ((origin[3:0] == 0) | (left_minus1[3:0] == 0))? origin : origin - 8'd2;	// left
				2'd2 : origin	<= (origin < 8'd32) ? origin : origin - 8'd32;	// up
				2'd3 : origin	<= (origin >= 8'd192) ? origin : origin + 8'd32;	// down
			endcase
		end
		2'd2 : begin		// 1 X 1
			case(shift_direction)		// 0->right, 1->left, 2->up, 3->down.
				2'd0 : origin	<= (((right_plus1[3:0] == 0) | (right_plus2[3:0] == 0)) | ((right_plus3[3:0] == 0) | (right_plus4[3:0] == 0)))? origin : origin + 8'd4;	// right
				2'd1 : origin	<= (((origin[3:0] == 0) | (left_minus1[3:0] == 0)) | ((left_minus2[3:0] == 0) | (left_minus3[3:0] == 0)))? origin : origin - 8'd4;	// left
				2'd2 : origin	<= (origin < 8'd64) ? origin : origin - 8'd64;	// up
				2'd3 : origin	<= (origin >= 8'd192) ? origin : origin + 8'd64;	// down
			endcase
		end
		default : origin <= origin;
		endcase
	end
	else begin
		origin		<= origin;
	end
end

// image_size
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n)			image_size <= 0;
	else if(Up_enable)		image_size <= (image_size == 2'd2)?	2'd1 : 2'd0;	// 0 -> 16x16, 1 -> 8x8, 2 -> 4x4
	else if(Down_enable)	image_size <= (image_size == 2'd0)?	2'd1 : 2'd2;	// 0 -> 16x16, 1 -> 8x8, 2 -> 4x4
	else					image_size <= image_size;
end


integer 	i;
reg [5:0]	j;
reg [8:0]	M_loadReg_Addr_D;
reg [8:0]	C_loadReg_Addr_D;

// control signal
always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		j	<= 0;
		M_loadReg_Addr_D	<= 0;
		C_loadReg_Addr_D	<= 0;
		for(i = 0; i <= 36; i = i+1)
			register[i] <= 24'd0;
	end
	else if(origin_enable) begin
		j					<= 6'b111111;
		M_loadReg_Addr_D	<= Median_loadReg_Addr;
		C_loadReg_Addr_D	<= Census_loadReg_Addr;
		register[36]		<= 24'd0;
	end
	else begin
		register[36]	<= 24'd0;
		M_loadReg_Addr_D	<= Median_loadReg_Addr;		// Delay 1 cycle to check ADDR
		C_loadReg_Addr_D	<= Census_loadReg_Addr;
		/*
		if(Census_loadReg_finish) begin
			$display("Reg1 = %h, Reg2 = %h, Reg3 = %h", register[0], register[1], register[2]);
			$display("Reg4 = %h, Reg5 = %h, Reg6 = %h", register[6], register[7], register[8]);
			$display("Reg7 = %h, Reg8 = %h, Reg9 = %h", register[12], register[13], register[14]);
		end*/
	case(image_size)
	2'd0: begin		// 4 X 4
		if(Median_loadReg_enable | Census_loadReg_enable) begin
			j <= j + 1;
			if(Median_loadReg_enable & ((j < 0) | (M_loadReg_Addr_D == 9'd256)) | (Census_loadReg_enable & ((j < 0 | C_loadReg_Addr_D == 9'd256))))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd0 | j == 6'd6  | j == 6'd12 | j == 6'd18 | j == 6'd24 | j == 6'd30) & (Median_loadReg_Addr[3:0] == 0) | 
					Census_loadReg_enable & (j == 6'd0 | j == 6'd6  | j == 6'd12 | j == 6'd18 | j == 6'd24 | j == 6'd30) & (Census_loadReg_Addr[3:0] == 0))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd5 | j == 6'd11 | j == 6'd17 | j == 6'd23 | j == 6'd29 | j == 6'd35) & (M_loadReg_Addr_D[3:0] == 0) | 
					Census_loadReg_enable & (j == 6'd5 | j == 6'd11 | j == 6'd17 | j == 6'd23 | j == 6'd29 | j == 6'd35) & (C_loadReg_Addr_D[3:0] == 0))
				register[j]	<= 0;
			else 
				register[j]	<= {o_sram_R, o_sram_G, o_sram_B};
		end
	end
	2'd1: begin		// 2 X 2
		if(Median_loadReg_enable | Census_loadReg_enable) begin
			j <= j + 1;
			if(Median_loadReg_enable & ((j < 0) | (M_loadReg_Addr_D == 9'd256)) | (Census_loadReg_enable & ((j < 0 | C_loadReg_Addr_D == 9'd256))))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd0 | j == 6'd4 | j == 6'd8  | j == 6'd12) & (Median_loadReg_Addr[3:0] == 0) | 
					Census_loadReg_enable & (j == 6'd0 | j == 6'd4 | j == 6'd8  | j == 6'd12) & (Census_loadReg_Addr[3:0] == 0))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd3 | j == 6'd7 | j == 6'd11 | j == 6'd15) & (M_loadReg_Addr_D[3:0] == 0) | 
					Census_loadReg_enable & (j == 6'd3 | j == 6'd7 | j == 6'd11 | j == 6'd15) & (C_loadReg_Addr_D[3:0] == 0))
				register[j]	<= 0;
			else 
				register[j]	<= {o_sram_R, o_sram_G, o_sram_B};
		end
	end
	2'd2: begin
		if(Median_loadReg_enable | Census_loadReg_enable) begin
			j <= j + 1;
			if(Median_loadReg_enable & ((j < 0) | (M_loadReg_Addr_D == 9'd256)) | (Census_loadReg_enable & ((j < 0 | C_loadReg_Addr_D == 9'd256))))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd0 | j == 6'd3 | j == 6'd6) & (Median_loadReg_Addr[3:0] == 0) |
					Census_loadReg_enable & (j == 6'd0 | j == 6'd3 | j == 6'd6) & (Census_loadReg_Addr[3:0] == 0))
				register[j]	<= 0;
			else if(Median_loadReg_enable & (j == 6'd2 | j == 6'd5 | j == 6'd8) & (M_loadReg_Addr_D[3:0] == 0) | 
					Census_loadReg_enable & (j == 6'd2 | j == 6'd5 | j == 6'd8) & (C_loadReg_Addr_D[3:0] == 0))
				register[j]	<= 0;
			else if(M_loadReg_Addr_D == 9'h61 | M_loadReg_Addr_D == 9'ha1 | M_loadReg_Addr_D == 9'he1)
				register[j] <= 0;
			else 
				register[j]	<= {o_sram_R, o_sram_G, o_sram_B};
		end
	end
	default: begin
	end
	endcase
	end
end

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		o_op_ready_r 	<= 0;
		curr_state		<= `START;
		o_out_valid_r 	<= 0;
		o_in_ready_r	<= 0;
		o_out_data_r	<= 0;
	end
	else begin
		o_op_ready_r	<= o_op_ready_w;
		curr_state		<= next_state;
		o_out_valid_r 	<= o_out_valid_w;
		o_in_ready_r	<= o_in_ready_w;
		o_out_data_r	<= o_out_data_w;
	end
end

// control M address

always@(posedge i_clk or negedge i_rst_n) begin
	if(!i_rst_n) begin
		M11 <= 0; M12 <= 0; M13 <= 0;
		M21 <= 0; M22 <= 0; M23 <= 0;
		M31 <= 0; M32 <= 0; M33 <= 0;
		counter <= 0;
		Median_origin 	<= 0;
	end
	else if(origin_enable) begin
		counter	<= 0;
		Median_origin 	<= origin;

		case(image_size)
		2'd0: begin		// 4 X 4
			M11 <= 6'd0; 	M12 <= 6'd1; 	M13 <= 6'd2;
			M21 <= 6'd6; 	M22 <= 6'd7; 	M23 <= 6'd8;
			M31 <= 6'd12; 	M32 <= 6'd13; 	M33 <= 6'd14;
		end
		2'd1: begin		// 2 X 2
			M11 <= 6'd0; 	M12 <= 6'd1; 	M13 <= 6'd2;
			M21 <= 6'd4; 	M22 <= 6'd5; 	M23 <= 6'd6;
			M31 <= 6'd8;	M32 <= 6'd9; 	M33 <= 6'd10;
		end
		2'd2: begin
			M11 <= 6'd0; 	M12 <= 6'd1; 	M13 <= 6'd2;
			M21 <= 6'd3; 	M22 <= 6'd4; 	M23 <= 6'd5;
			M31 <= 6'd6;	M32 <= 6'd7; 	M33 <= 6'd8;
		end
		default:begin
			
		end
		endcase
	end
	else if(Median_read_enable | Census_enable) begin
		case(image_size)
		2'd0: begin		// 4 X 4	
			if(counter != 3) begin
				M11 <= M11 + 1;	M12 <= M12 + 1;	M13 <= M13 + 1;
				M21 <= M21 + 1;	M22 <= M22 + 1;	M23 <= M23 + 1;
				M31 <= M31 + 1;	M32 <= M32 + 1;	M33 <= M33 + 1;
				Median_origin 	<= Median_origin + 8'd1;
				counter		<= counter + 1;
			end

			else begin
				M11 <= M11 + 6'd3;	M12 <= M12 + 6'd3;	M13 <= M13 + 6'd3;
				M21 <= M21 + 6'd3;	M22 <= M22 + 6'd3;	M23 <= M23 + 6'd3;
				M31 <= M31 + 6'd3;	M32 <= M32 + 6'd3;	M33 <= M33 + 6'd3;
				Median_origin 	<= Median_origin + 8'd13;
				counter		<= 0;
			end

		end
		
		2'd1: begin		// 2 X 2
			if(counter != 1) begin
				M11 <= M11 + 1;	M12 <= M12 + 1;	M13 <= M13 + 1;
				M21 <= M21 + 1;	M22 <= M22 + 1;	M23 <= M23 + 1;
				M31 <= M31 + 1;	M32 <= M32 + 1;	M33 <= M33 + 1;
				Median_origin 	<= Median_origin + 8'd2;
				counter		<= counter + 1;
			end
			
			else begin
				M11 <= M11 + 6'd3;	M12 <= M12 + 6'd3;	M13 <= M13 + 6'd3;
				M21 <= M21 + 6'd3;	M22 <= M22 + 6'd3;	M23 <= M23 + 6'd3;
				M31 <= M31 + 6'd3;	M32 <= M32 + 6'd3;	M33 <= M33 + 6'd3;
				Median_origin 	<= Median_origin + 8'd30;
				counter		<= 0;
			end
		end
		
		2'd2: begin	
			Median_origin	<= Median_origin + 8'd3;
		end
		
		default: begin
			Median_origin	<= Median_origin;
		end
		endcase
	end
	else begin
		Median_origin 	<= Median_origin;
		counter			<= 0 ;
	end

end

sram_256x8 sram_R (
	.Q(o_sram_R),					// Output from Sram
	.CLK(i_clk),					// 
	.CEN(CEN_R),					// Set High if StandBy, Low if Write or Read
	.WEN(WEN_R),					// Set High if Write, Low if read
	.A(A),							// Input address to Sram
	.D(i_sram_R)					// Input to Sram
);

sram_256x8 sram_G (
	.Q(o_sram_G),
	.CLK(i_clk),
	.CEN(CEN_G),
	.WEN(WEN_G),
	.A(A),
	.D(i_sram_G)
);

sram_256x8 sram_B (
	.Q(o_sram_B),
	.CLK(i_clk),
	.CEN(CEN_B),
	.WEN(WEN_B),
	.A(A),
	.D(i_sram_B)
);

Addr_Sram_LoadImage LoadImage (
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.load_enable(load_enable),
	.Addr_Load(Addr_Load),
	.load_finish(load_finish)
);

Addr_Sram_ReadImage ReadImage (
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.read_enable(read_enable),
	.origin_enable(origin_enable),
	.image_size(image_size),
	.origin(origin),
	.Addr_Read(Addr_Read),
	.read_finish(read_finish)
);

// ----------------------------- R ------------------------------//

Sort3 Sort1R_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M11][23:16]),
	.input2(register[M12][23:16]),
	.input3(register[M13][23:16]),
	.Max(Max1_R),
	.Med(Med1_R),
	.Min(Min1_R)
);

Sort3 Sort1R_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M21][23:16]),
	.input2(register[M22][23:16]),
	.input3(register[M23][23:16]),
	.Max(Max2_R),
	.Med(Med2_R),
	.Min(Min2_R)
);

Sort3 Sort1R_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M31][23:16]),
	.input2(register[M32][23:16]),
	.input3(register[M33][23:16]),
	.Max(Max3_R),
	.Med(Med3_R),
	.Min(Min3_R)
);

Sort3 Sort2R_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Min1_R),
	.input2(Min2_R),
	.input3(Min3_R),
	.Max(Max_of_Min_R),
	.Med(),
	.Min()
);
Sort3 Sort2R_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Med1_R),
	.input2(Med2_R),
	.input3(Med3_R),
	.Max(),
	.Med(Med_of_Med_R),
	.Min()
);

Sort3 Sort2R_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max1_R),
	.input2(Max2_R),
	.input3(Max3_R),
	.Max(),
	.Med(),
	.Min(Min_of_Max_R)
);

Sort3 Sort3R_Final(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max_of_Min_R),
	.input2(Med_of_Med_R),
	.input3(Min_of_Max_R),
	.Max(),
	.Med(Median_out_Data_R),
	.Min()
);
// ----------------------------- G ------------------------------//

Sort3 Sort1G_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M11][15:8]),
	.input2(register[M12][15:8]),
	.input3(register[M13][15:8]),
	.Max(Max1_G),
	.Med(Med1_G),
	.Min(Min1_G)
);

Sort3 Sort1G_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M21][15:8]),
	.input2(register[M22][15:8]),
	.input3(register[M23][15:8]),
	.Max(Max2_G),
	.Med(Med2_G),
	.Min(Min2_G)
);

Sort3 Sort1G_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M31][15:8]),
	.input2(register[M32][15:8]),
	.input3(register[M33][15:8]),
	.Max(Max3_G),
	.Med(Med3_G),
	.Min(Min3_G)
);

Sort3 Sort2G_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Min1_G),
	.input2(Min2_G),
	.input3(Min3_G),
	.Max(Max_of_Min_G),
	.Med(),
	.Min()
);
Sort3 Sort2G_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Med1_G),
	.input2(Med2_G),
	.input3(Med3_G),
	.Max(),
	.Med(Med_of_Med_G),
	.Min()
);

Sort3 Sort2G_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max1_G),
	.input2(Max2_G),
	.input3(Max3_G),
	.Max(),
	.Med(),
	.Min(Min_of_Max_G)
);

Sort3 Sort3G_Final(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max_of_Min_G),
	.input2(Med_of_Med_G),
	.input3(Min_of_Max_G),
	.Max(),
	.Med(Median_out_Data_G),
	.Min()
);

// ----------------------------- B ------------------------------//

Sort3 Sort1B_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M11][7:0]),
	.input2(register[M12][7:0]),
	.input3(register[M13][7:0]),
	.Max(Max1_B),
	.Med(Med1_B),
	.Min(Min1_B)
);

Sort3 Sort1B_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M21][7:0]),
	.input2(register[M22][7:0]),
	.input3(register[M23][7:0]),
	.Max(Max2_B),
	.Med(Med2_B),
	.Min(Min2_B)
);

Sort3 Sort1B_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(register[M31][7:0]),
	.input2(register[M32][7:0]),
	.input3(register[M33][7:0]),
	.Max(Max3_B),
	.Med(Med3_B),
	.Min(Min3_B)
);

Sort3 Sort2B_1(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Min1_B),
	.input2(Min2_B),
	.input3(Min3_B),
	.Max(Max_of_Min_B),
	.Med(),
	.Min()
);
Sort3 Sort2B_2(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Med1_B),
	.input2(Med2_B),
	.input3(Med3_B),
	.Max(),
	.Med(Med_of_Med_B),
	.Min()
);

Sort3 Sort2B_3(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max1_B),
	.input2(Max2_B),
	.input3(Max3_B),
	.Max(),
	.Med(),
	.Min(Min_of_Max_B)
);

Sort3 Sort3B_Final(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.input1(Max_of_Min_B),
	.input2(Med_of_Med_B),
	.input3(Min_of_Max_B),
	.Max(),
	.Med(Median_out_Data_B),
	.Min()
);

endmodule





















// 1. compute Sram Load Address.
// 2. Load initial 4x4 image into register
module Addr_Sram_LoadImage(
	input			i_clk,
	input			i_rst_n,
	input			load_enable,
	output reg[7:0]	Addr_Load,
	output 			load_finish
);
	reg 	over_flow;

	assign load_finish = (over_flow == 1)?	1 : 0;	// may have problem.

	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			Addr_Load 		<= 8'b0000_0000;
			over_flow		<= 0;
		end
		else if(load_enable) begin
			{over_flow, Addr_Load} 	<= Addr_Load + 8'd1;			// may have problem.
		end
		else begin
			Addr_Load 		<= 8'b0000_0000;
		end
	end

endmodule

module Addr_Sram_ReadImage(
	input			i_clk,
	input			i_rst_n,
	input			read_enable,
	input			origin_enable,
	input [1:0]		image_size,
	input [7:0]		origin,
	output reg[7:0]	Addr_Read,
	output			read_finish 
);

	reg [1:0] 	counter;				// count every four add.
	reg [3:0]	total_count;			// count total 16 times add.
	reg [5:0]	count_16;

	assign read_finish = (total_count == 4'd15)? 1 : 0;	// may need to revise.

	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			Addr_Read 	<= 8'b0000_0000;	// may need to revise 8'b1111_1111
			counter   	<= 0;	total_count <= 0;
			count_16	<= 0;
		end

		else begin
			if(read_finish) begin
				total_count <= 0;	counter 	<= 0;
				count_16 <= 0;
			end
			else if(origin_enable) begin
				Addr_Read	<= origin;
			end
			else if(read_enable) begin
				case(image_size)
				2'd0: begin		// 4 X 4
					if(counter == 2'd3) begin
						Addr_Read 	<= origin + counter + 8'd13 + (count_16 << 4);
						counter 	<= 0;
						count_16	<= count_16 + 1;
					end
					else begin
						Addr_Read 	<= origin + counter + 8'd1 + (count_16 << 4);
						counter 	<= counter + 1;
					end
					total_count <= total_count + 4'd1;
				end
				2'd1: begin		// 2 X 2
					if(counter == 2'd1) begin
						Addr_Read 	<= origin + counter + 8'd31;
						counter 	<= 0;
						count_16	<= count_16 + 1;
					end
					else begin
						Addr_Read 	<= origin + 8'd2 + (count_16 << 5);
						counter 	<= counter + 1;
					end
					total_count <= total_count + 4'd5;
				end
				2'd2: begin		// 1 X 1
					total_count <= total_count + 4'd15;
				end
				default: counter <= 0;
				endcase
			end
			else begin
				Addr_Read <= Addr_Read;
			end	
		end
	end

endmodule

module Median_LoadReg(
	input			i_clk,
	input			i_rst_n,
	input			Median_loadReg_enable,
	input			origin_enable,
	input [1:0]		image_size,
	input [7:0]		origin,
	output reg[8:0]	Addr_Read,
	output			loadReg_finish 
);

	reg [3:0] 	counter;				// count every four add.
	reg [5:0]	total_count;			// count total 16 times add.
	reg [7:0]	count16;
	reg [8:0]	origin_E;				

	assign loadReg_finish = (total_count == 6'd36)? 1 : 0;	// may need to revise.

	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			Addr_Read 	<= 8'b0000_0000;
			counter   	<= 0;	total_count <= 0;
			count16		<= 0;	origin_E	<= 0;
		end

		else begin
			if(loadReg_finish) begin
				total_count <= 0;	counter 	<= 0;
				count16		<= 0;
			end
			else if(origin_enable) begin
				origin_E	<= origin;	count16		<= 0;
				total_count <= 0;	counter 	<= 0;
				case(image_size)
				2'd0: Addr_Read	<= (origin <= 8'd16)? 9'd256 : origin - 8'd17;
				2'd1: begin
					Addr_Read 	<= (origin <= 8'd33)? 9'd256 : origin - 8'd34;
					total_count	<= 6'd20;
				end
				2'd2: begin
					Addr_Read 	<= (origin <= 8'd67)? 9'd256 : origin - 8'd68;
					total_count <= 6'd27;
				end
				default:begin
					
				end
				endcase
			end
			else if(Median_loadReg_enable) begin
				case(image_size)
				2'd0: begin		// 4 x 4
					if(counter != 4'd5) begin
						if(((origin_E + counter + count16) < 8'd16) | ((origin_E + counter + count16) >= 9'd272))
							Addr_Read	<= 9'd256;
						else
							Addr_Read	<= origin - 8'd16 + counter + count16;
						counter 	<= counter + 1;
					end
					else begin
						if(((origin_E + count16) < 8'd1) | ((origin_E + count16) >= 9'd257))
							Addr_Read	<= 9'd256;
						else
							Addr_Read	<= origin - 8'd1 + count16;
						counter 	<= 0;
						count16		<= count16 + 8'd16;
					end
					total_count <= total_count + 6'd1;
				end
				
				2'd1: begin		// 2 X 2
					if(counter != 4'd6) begin
						if(((origin_E + counter + count16) < 8'd32) | ((origin_E + counter + count16) >= 9'd288))
							Addr_Read	<= 9'd256;
						else
							Addr_Read	<= origin - 8'd32 + counter + count16;
						counter 	<= counter + 2;
					end
					else begin
						if(((origin_E + count16) < 8'd2) | ((origin_E + count16) >= 9'd258))
							Addr_Read	<= 9'd256;
						else
							Addr_Read 	<= origin - 8'd2 + count16;
						counter 	<= 0;
						count16		<= count16 + 8'd32;
					end
					total_count <= total_count + 6'd1;
				end
				
				2'd2: begin		// 1 X 1  - count16 bit may not be enough
					if(counter != 4'd8) begin
						if(((origin_E + counter + count16) < 8'd64) | ((origin_E + counter + count16) >= 9'd320))
							Addr_Read	<= 9'd256;
						else
							Addr_Read	<= origin - 8'd64 + counter + count16;
						counter 	<= counter + 4;
					end
					else begin
						if(((origin_E + count16) < 8'd4) | ((origin_E + count16) >= 9'd260))
							Addr_Read	<= 9'd256;
						else
							Addr_Read 	<= origin - 8'd4 + count16;
						counter 	<= 0;
						count16		<= count16 + 8'd64;
					end
					total_count <= total_count + 6'd1;
				end

				default: counter <= 0;
				endcase
			end
			else begin
				Addr_Read <= Addr_Read;
			end	
		end
	end
endmodule


module Sort3(
	input			i_clk,
	input			i_rst_n,
	input [7:0]		input1,
	input [7:0]		input2,
	input [7:0]		input3,
	output reg[7:0]	Max,
	output reg[7:0]	Med,
	output reg[7:0]	Min
);

	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			Max		<= 0;
			Med		<= 0;
			Min		<= 0;
		end
		else begin
			if(input1 >= input2 & input2 >= input3) begin
				Max <= input1;
				Med <= input2;
				Min <= input3;
			end
			else if(input1 >= input3 & input3 >= input2) begin
				Max <= input1;
				Med <= input3;
				Min <= input2;
			end
			else if(input2 >= input1 & input1 >= input3) begin
				Max <= input2;
				Med <= input1;
				Min <= input3;
			end
			else if(input2 >= input3 & input3 >= input1) begin
				Max <= input2;
				Med <= input3;
				Min <= input1;
			end
			else if(input3 >= input1 & input1 >= input2) begin
				Max <= input3;
				Med <= input1;
				Min <= input2;
			end
			else begin
				Max <= input3;
				Med <= input2;
				Min <= input1;
			end
		end
	end

endmodule