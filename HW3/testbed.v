`timescale 1ns/100ps
`define CYCLE       11.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000
`define RST_DELAY   2


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERN/indata3.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
`elsif tb4
    `define INFILE "../00_TESTBED/hidden/indata_hidden.dat"
    `define OPFILE "../00_TESTBED/hidden/opmode_hidden.dat"
    `define GOLDEN "../00_TESTBED/hidden/golden_hidden.dat"
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
`endif

`define SDFFILE "ipdc_syn.sdf"  // Modify your sdf file name


module testbed;

reg clk, rst_n;
reg         op_valid;
reg [ 3:0]  op_mode;
wire        op_ready;
reg         in_valid;
reg [23:0]  in_data;
wire        in_ready;
wire        out_valid;
wire [23:0] out_data;

reg [23:0] indata_mem [ 0:255];
reg [ 3:0] opmode_mem [ 0:255];
reg [23:0] golden_mem [ 0:2048];

integer index, inst_i, i, error_cnt;


// ==============================================
// TODO: Declare regs and wires you need
// ==============================================


// For gate-level simulation only
`ifdef SDF
    initial $sdf_annotate(`SDFFILE, u_ipdc);
    initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
`endif

// Write out waveform file
initial begin
  $fsdbDumpfile("ipdc.fsdb");
  $fsdbDumpvars(3, "+mda");
end


ipdc u_ipdc (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_op_valid(op_valid),
	.i_op_mode(op_mode),
    .o_op_ready(op_ready),
	.i_in_valid(in_valid),
	.i_in_data(in_data),
	.o_in_ready(in_ready),
	.o_out_valid(out_valid),
	.o_out_data(out_data)
);

// Read in test pattern and golden pattern
initial $readmemb(`INFILE, indata_mem);
initial $readmemb(`OPFILE, opmode_mem);
initial $readmemb(`GOLDEN, golden_mem);

// Clock generation
initial clk = 1'b0;
always  #(`HCYCLE) begin clk = ~clk;    end

// Reset generation

initial begin
    rst_n = 1; # (               0.25 * `CYCLE);
    rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
    rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
    $display("Error! Runtime exceeded!");
    $finish;
end

// ==============================================
// TODO: Check pattern after process finish
// ==============================================

    initial begin
        @(negedge rst_n);
        op_valid = 1'd0;
        op_mode = 2'd0;
        in_valid = 1'd0;
        in_data = 24'd0;
        index = 0;
        error_cnt = 0;
    end

    initial begin
        @(posedge rst_n);
        $display("----------------------------------------------");
        $display("                  IPDC TEST 0 START");
        $display("----------------------------------------------");

        for(index=0; index<256; index = index+16) begin
            $display("%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n", 
                indata_mem[index],indata_mem[index+1],indata_mem[index+2],indata_mem[index+3],
                indata_mem[index+4],indata_mem[index+5],indata_mem[index+6],indata_mem[index+7],
                indata_mem[index+8],indata_mem[index+9],indata_mem[index+10],indata_mem[index+11],
                indata_mem[index+12],indata_mem[index+13],indata_mem[index+14],indata_mem[index+15]);
        end

        /*for(index=0; index<256; index = index+16) begin
            $display("%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h\n", 
                opmode_mem[index],opmode_mem[index+1],opmode_mem[index+2],opmode_mem[index+3],
                opmode_mem[index+4],opmode_mem[index+5],opmode_mem[index+6],opmode_mem[index+7],
                opmode_mem[index+8],opmode_mem[index+9],opmode_mem[index+10],opmode_mem[index+11],
                opmode_mem[index+12],opmode_mem[index+13],opmode_mem[index+14],indata_mem[index+15]);
        end*/

        wait(op_ready == 1);
        $display("----------------------------------------------");
        $display("                  OP is Ready                 ");
        $display("----------------------------------------------");

        #(`CYCLE)
        @(negedge clk);
        op_valid = 1'd1;
        op_mode = opmode_mem[0];
        index = 0;

        // 0000 Load
        $display("----------------------------------------------");
        $display("                  INST 0 :%b",opmode_mem[0]);
        $display("----------------------------------------------");

        @(negedge clk);
        op_valid = 1'd0;
        in_valid = 1'd1;

        while(index < 256) begin
            in_data = indata_mem[index];
            @(negedge clk);
            if(in_ready == 1'b1)
                index = index + 1;
        end
        in_valid = 1'd0;

//-------------------------------------------------------------------------------------//
        // #(`CYCLE)

        index = 0;

        for(i = 1; i <= 20; i = i+1) begin
            wait(op_ready == 1);

            #(`CYCLE)
            @(negedge clk);
            op_valid = 1'd1;
            op_mode = opmode_mem[i];

            // 0111 Load
            $display("----------------------------------------------");
            $display("                  INST %d :%b", i, opmode_mem[i]);
            $display("----------------------------------------------");

            @(negedge clk);
            op_valid = 1'd0;
            op_mode = 4'd0;

            @(posedge out_valid);
            @(posedge clk);
            //$display("out_valid = %d", out_valid);
            while(out_valid) begin
                $display("------Test OutData------ MyData = %h, GoldenD = %h , index = %d", out_data, golden_mem[index], index);
                if(out_data != golden_mem[index]) begin
                  //$display("Error :  MyData = %h, GoldenData = %h , index = %d", out_data, golden_mem[index], index);
                   error_cnt = error_cnt + 1; 
                end
                index = index + 1;
                @(posedge clk);
            end
        end
 
        if(error_cnt == 0) begin
            $display("----------------------------------------------");
            $display("                  ALL   SUCCESS               ");
            $display("----------------------------------------------");
            $finish;
        end
        else begin
            $display("----------------------------------------------");
            $display("                  PROGRAM HAS ERROR           ");
            $display("----------------------------------------------");
            $finish;
        end
    end
endmodule
