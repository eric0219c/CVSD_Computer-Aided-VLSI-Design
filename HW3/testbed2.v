`timescale 1ns/100ps
`define CYCLE       11.0      // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   10000000
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
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
`endif

`define SDFFILE "ipdc_syn.sdf"  // Modify your sdf file name


module testbed;

reg clk, rst_n;
reg         op_valid;
reg  [ 3:0] op_mode;
wire        op_ready;
reg         in_valid;
reg  [23:0] in_data;
wire        in_ready;
wire        out_valid;
wire [23:0] out_data;

reg [23:0] indata_mem [ 255:0];
reg [ 3:0] opmode_mem [ 63:0];
reg [23:0] golden_mem [1023:0];

// ==============================================
// TODO: Declare regs and wires you need
// ==============================================
integer i, j, golden_index;
integer size;


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
always begin #(`CYCLE/2) clk = ~clk; end

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
    golden_index = 0;
    size = 4;
    op_valid = 1'b0;
    op_mode = 4'b0;
    in_valid = 1'b0;
    in_data = 24'b0;
    #(`CYCLE);

    wait (rst_n == 1'b1);
    
    for (i = 0; i < 22; i = i + 1) begin
        wait (op_ready == 1'b1);
        @(negedge clk)
        #(`CYCLE);
        op_valid = 1'b1;
        op_mode = opmode_mem[i];
        #(`CYCLE);
        op_valid = 1'b0;
        op_mode = 3'd0;

        // load
        if (opmode_mem[i] == 4'd0) begin
            for (j = 0; j < 256; j = j + 1) begin
                in_valid = 1'b1;
                in_data = indata_mem[j];
                #(`CYCLE);
            end
            in_data = 24'd0;
            in_valid = 1'b0;
            //wait (out_valid == 1'b1);
            #(`CYCLE);
            $display("op(%d) done", opmode_mem[i]);
        end

        // diaplay region
        if (opmode_mem[i] == 4'd8 && size != 1) size = size / 2;
        if (opmode_mem[i] == 4'd9 && size != 4) size = size * 2;

        // 4*4
        if (((opmode_mem[i] >= 4'd4 && opmode_mem[i] <= 4'd9) || (opmode_mem[i] >= 4'd12 && opmode_mem[i] <= 4'd14)) && size == 4) begin
            // while (out_valid) ?
            for (j = golden_index; j < golden_index + 16; j = j + 1) begin
                wait (out_valid == 1'b1);
                @(negedge clk)
                if (golden_mem[j] != out_data) begin
                    $display("4*4 Error!, (%d)th op, (%d)th golden data: op=(%d), golden=(%b), yours=(%b)",
                            i, j, opmode_mem[i], golden_mem[j], out_data);
                    $finish;
                end
                #(`CYCLE * 0.5);
            end
            golden_index = golden_index + 16;
            $display("i = %d, op(%d) correct!", i, opmode_mem[i]);
        end

        // 2*2
        if (((opmode_mem[i] >= 4'd4 && opmode_mem[i] <= 4'd9) || (opmode_mem[i] >= 4'd12 && opmode_mem[i] <= 4'd14)) && size == 2) begin
            for (j = golden_index; j < golden_index + 4; j = j + 1) begin
                wait (out_valid == 1'b1);
                @(negedge clk)
                if (golden_mem[j] != out_data) begin
                    $display("2*2 Error!, (%d)th op, (%d)th golden data: op=(%d), golden=(%b), yours=(%b)",
                            i, j, opmode_mem[i], golden_mem[j], out_data);
                    $finish;
                end
                #(`CYCLE * 0.5);
            end
            golden_index = golden_index + 4;
            $display("i = %d, op(%d) correct!", i, opmode_mem[i]);
        end

        // 1*1
        if (((opmode_mem[i] >= 4'd4 & opmode_mem[i] <= 4'd9) || (opmode_mem[i] >= 4'd12 && opmode_mem[i] <= 4'd14)) && size == 1) begin
            for (j = golden_index; j < golden_index + 1; j = j + 1) begin
                wait (out_valid == 1'b1);
                @(negedge clk)
                if (golden_mem[j] != out_data) begin
                    $display("1*1 Error!, (%d)th op, (%d)th golden data: op=(%d), golden=(%b), yours=(%b)",
                            i, j, opmode_mem[i], golden_mem[j], out_data);
                    $finish;
                end
                #(`CYCLE * 0.5);
            end
            golden_index = golden_index + 1;
            $display("i = %d, op(%d) correct!", i, opmode_mem[i]);
        end

    end
    $display("Simulation Pass!");
    $finish;
end

endmodule
