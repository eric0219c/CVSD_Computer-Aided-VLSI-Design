`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000
module testbed;

	wire clk, rst_n;
	wire [ 31 : 0 ] imem_addr;
	wire [ 31 : 0 ] imem_inst;
	wire            dmem_wen;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  1 : 0 ] mips_status;
	wire            mips_status_valid;

	initial $readmemb (`Inst, u_inst_mem.mem_r);
	//initial $readmemb (`DMEM_INIT, Data_memory.mem);
    initial begin
        $fsdbDumpfile("test.fsdb");
        $fsdbDumpvars(0, "+mda");
    end

    initial begin
        $display("----------------------------------------------");
        $display("                  MIPS TEST START");
        $display("----------------------------------------------");
			
		//$display("i = %d, Data = %d", 0, Data_memory.mem[0]);

        while(mips_status!==3 & mips_status!==2) begin
            @(posedge mips_status_valid);
			
			//$display("ADDR = %b, DATA = %d", dmem_addr, dmem_rdata);
            if(mips_status == 0) begin
                $display("R_TYPE_SUCCESS. INST:%h, Inst = %b", imem_addr, imem_inst);
            end
            else if(mips_status == 1) begin
                $display("I_TYPE_SUCCESS. INST:%h, Inst = %b", imem_addr, imem_inst);
            end
            else if(mips_status == 2) begin
                $display("MIPS_OVERFLOW.  INST:%h, Inst = %b", imem_addr, imem_inst);
            end
            else if(mips_status == 3) begin
                $display("MIPS_END.       INST:%h, Inst = %b", imem_addr, imem_inst);
            end
        end
        
        $display("----------------------------------------------");
        $display("                  MIPS TEST OVER");
        $display("----------------------------------------------");
        $finish;
    end

    core u_core (
        .i_clk(clk),
		.i_rst_n(rst_n),
		.o_i_addr(imem_addr),
		.i_i_inst(imem_inst),
		.o_d_wen(dmem_wen),
		.o_d_addr(dmem_addr),
		.o_d_wdata(dmem_wdata),
		.i_d_rdata(dmem_rdata),
		.o_status(mips_status),
		.o_status_valid(mips_status_valid)
	);

	inst_mem  u_inst_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_addr(imem_addr),
		.o_inst(imem_inst)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_wen(dmem_wen),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

    Clkgen u_clk (
        .clk(clk),
        .rst_n(rst_n)
    );

endmodule

module Clkgen (
    output reg clk,
    output reg rst_n
);
    always # (`HCYCLE) clk = ~clk;

    initial begin
        clk = 1'b1;
        rst_n = 1; # (               0.25 * `CYCLE);
        rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
        rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
        $display("----------------------------------------------");
        $display("Latency of your design is over 100000 cycles!!");
        $display("----------------------------------------------");
        $finish;
    end
endmodule



