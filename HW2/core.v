module core #(                             //Don't modify interface
	parameter ADDR_W = 32,
	parameter INST_W = 32,
	parameter DATA_W = 32
)(
	input                   i_clk,
	input                   i_rst_n,
	output [ ADDR_W-1 : 0 ] o_i_addr,
	input  [ INST_W-1 : 0 ] i_i_inst,
	output                  o_d_wen,
	output [ ADDR_W-1 : 0 ] o_d_addr,
	output [ DATA_W-1 : 0 ] o_d_wdata,
	input  [ DATA_W-1 : 0 ] i_d_rdata,
	output [        1 : 0 ] o_status,
	output                  o_status_valid
);

parameter IDLE   = 3'd0;
parameter IF     = 3'd1;
parameter ID     = 3'd2;
parameter EX     = 3'd3;
parameter WB     = 3'd4;
parameter PC     = 3'd5;
parameter END    = 3'd6;
parameter OverF	 = 3'd7;

parameter NOP		= 4'd0;
parameter OP_ADD	= 4'd1;
parameter OP_SUB	= 4'd2;
parameter OP_ADDI	= 4'd3;
parameter OP_LW		= 4'd4;
parameter OP_SW		= 4'd5;
parameter OP_AND	= 4'd6;
parameter OP_OR		= 4'd7;
parameter OP_NOR	= 4'd8;
parameter OP_BEQ	= 4'd9;
parameter OP_BNE	= 4'd10;
parameter OP_SLT	= 4'd11;
parameter OP_EOF	= 4'd12;

parameter R_TYPE_SUCCESS = 2'd0;
parameter I_TYPE_SUCCESS = 2'd1;
parameter MIPS_OVERFLOW  = 2'd2;
parameter MIPS_END	     = 2'd3;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //
	wire [ADDR_W-1:0] 	PcAdd4;
	wire [DATA_W-1:0]   DM_data;
	
	reg [31:0] 			Reg [31:0];         // 32 * 32bit register

	reg [ADDR_W-1:0]	o_i_addr_w, o_i_addr_r;
	reg [ADDR_W-1:0]	o_d_addr_w, o_d_addr_r;
	reg [DATA_W-1:0]	o_d_wdata_w, o_d_wdata_r;
	reg [1:0]			o_status_w, o_status_r;
	reg  				o_status_valid_w, o_status_valid_r;
	reg 				o_d_wen_w, o_d_wen_r;
	reg 				overflow;				// to detect overflow
	reg [15:0]			Im;
	reg [2:0]			curr_state;
	reg [2:0]			next_state;
	reg [6:0] 			Opcode;
	reg [5:0] 			reg25, reg20, reg15;
	reg [DATA_W-1:0]	AluResult;
	reg [31:0] 			RF_data_w;				// Result ready to write back.
	reg [31:0] 			RF_data_r;				// Result ready to write back.
	
	
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
	assign PcAdd4	= o_i_addr_r + 4;				// PC+4

	assign o_i_addr  = o_i_addr_r;
	assign o_d_wen   = o_d_wen_r;
	assign o_d_addr  = o_d_addr_r;
	assign o_d_wdata = o_d_wdata_r;
	assign o_status  = o_status_r;
	assign o_status_valid = o_status_valid_r;

	assign DM_data = i_d_rdata;

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

always@(*) begin
	if(overflow)
		next_state = OverF;
	else begin
		case(curr_state)
			IDLE: begin
				if(i_i_inst[31:26] == 0)						// May need to revise.
					next_state = IDLE;
				else
					next_state = ID;
			end
			ID: 	 next_state = EX;
			EX: 	 next_state = WB;
			WB: 	 next_state = PC;
			PC: 	 next_state = END;
			END:	 next_state = IDLE;
			OverF:	 next_state = IDLE;
			default: next_state = IDLE;
		endcase
	end
end

always@(*) begin
	case(curr_state)
		IDLE: begin
			o_status_w   = 2'd0;
			o_status_valid_w = 1'd0;
		end

		ID: begin
			Opcode	= i_i_inst[31:26];
			reg25	= i_i_inst[25:21];
			reg20	= i_i_inst[20:16];
			reg15	= i_i_inst[15:11];
			Im		= i_i_inst[15:0];
		end

		EX: begin
			case(Opcode)
				OP_ADD : begin
					{overflow, RF_data_w} = Reg[reg25] + Reg[reg20];
				end

				OP_SUB : begin
					if(Reg[reg25] < Reg[reg20])	
						overflow = 1;
					else	
						RF_data_w = Reg[reg25] - Reg[reg20];
				end

				OP_ADDI : begin
					{overflow, RF_data_w} = Reg[reg25] + Im;
				end

				OP_LW: begin
					{overflow, o_d_addr_r} = Reg[reg25] + Im;
					o_d_wen_w = 0;						// set o_d_wen to 0 to load data from data memory
				end

				OP_SW: begin
					{overflow, o_d_addr_w} = Reg[reg25] + Im;
					o_d_wen_w = 1;						// set o_d_wen to 1 to save data to data memory
					o_d_wdata_w = Reg[reg20];			// may need to move to WB
				end

				OP_AND : RF_data_w = Reg[reg25] & Reg[reg20];
				OP_OR  : RF_data_w = Reg[reg25] | Reg[reg20];
				OP_NOR : RF_data_w = ~(Reg[reg25] | Reg[reg20]);
				OP_BEQ : AluResult = (Reg[reg25] == Reg[reg20])? 0 : 1;
				OP_BNE : AluResult = (Reg[reg25] == Reg[reg20])? 0 : 1;
				OP_SLT : RF_data_w = (Reg[reg25] < Reg[reg20])? 1 : 0;
				default: RF_data_w = 0;

			endcase
		end
		
		WB: begin
			case(Opcode)
				OP_ADD	: Reg[reg15] = RF_data_r;
				OP_SUB	: Reg[reg15] = RF_data_r;
				OP_ADDI : Reg[reg20] = RF_data_r;
				OP_LW	: Reg[reg20] = DM_data;		
				OP_SW	: o_d_wen_w  = 0;				// reset o_d_wen
				OP_AND	: Reg[reg15] = RF_data_r;
				OP_OR	: Reg[reg15] = RF_data_r;
				OP_NOR	: Reg[reg15] = RF_data_r;
				OP_SLT	: Reg[reg15] = RF_data_r;
				default	: RF_data_r = 0;
			endcase
		end

		PC: begin
			case(Opcode)
				OP_BEQ:		o_i_addr_w = (AluResult == 0)? PcAdd4 + Im : PcAdd4;
				OP_BNE:		o_i_addr_w = (AluResult == 0)? PcAdd4 : PcAdd4 + Im;
				default:	o_i_addr_w = PcAdd4; 
			endcase	
		end

		OverF: begin
			o_status_w		 = 2'b10;			// When overflow, status = 2.
			o_status_valid_w = 1;
		end

		END: begin
			o_status_valid_w = 1;
			case(Opcode)
				OP_ADD	: o_status_w = 2'b00;
				OP_SUB	: o_status_w = 2'b00;
				OP_ADDI : o_status_w = 2'b01;
				OP_LW	: o_status_w = 2'b01;
				OP_SW	: o_status_w = 2'b01;
				OP_AND	: o_status_w = 2'b00;
				OP_OR	: o_status_w = 2'b00;
				OP_NOR	: o_status_w = 2'b00;
				OP_BEQ	: o_status_w = 2'b01;
				OP_BNE	: o_status_w = 2'b01;
				OP_SLT	: o_status_w = 2'b00;
				OP_EOF	: o_status_w = 2'b11;
				default	: o_status_w = 2'b00;
			endcase
		end
	endcase
end




// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
integer i;
	always@(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			curr_state <= IDLE;
			o_i_addr_r <= 0;
			o_i_addr_w <= 0;
			o_d_wen_r <= 0;
			o_d_wen_w <= 0;
			o_d_addr_r <= 0;
			o_d_addr_w <= 0;
			o_d_wdata_r <= 0;
			o_d_wdata_w <= 0;
			o_status_w <= 0;
			o_status_r <= 0;
			o_status_valid_w <= 0;
			o_status_valid_r <= 0;
			RF_data_r <= 0;
			RF_data_w <= 0;
			overflow <= 0;
			for(i = 0; i < 32; i = i+1) // Register File
                Reg[i] <= 32'd0;
		end
		else begin
			curr_state <= next_state;
			o_d_wen_r <= o_d_wen_w;
			o_d_addr_r <= o_d_addr_w;
			o_d_wdata_r <= o_d_wdata_w;
			o_status_r <= o_status_w;
			o_status_valid_r <= o_status_valid_w;
			RF_data_r <= RF_data_w;
			curr_state <= next_state;

			if(|o_i_addr_r[31:12])	overflow <= 1;				// instr_addr 31-12 bit has 1 then overflow. 
			else					o_i_addr_r <= o_i_addr_w;

			if(|o_d_addr_r[31:8])	overflow <= 1;				// Data_addr 31-8 bit has 1 then overflow. 
			else					o_d_addr_r <= o_d_addr_w;

		end
	end


endmodule