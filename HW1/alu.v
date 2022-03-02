module alu (
    input               i_clk,
    input               i_rst_n,
    input               i_valid,
    input signed [11:0] i_data_a,
    input signed [11:0] i_data_b,
    input        [2:0]  i_inst,
    output              o_valid,
    output       [11:0] o_data,
    output              o_overflow
);
    
// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg  [11:0] o_data_w, o_data_r;
reg         o_valid_w, o_valid_r;
reg         o_overflow_w, o_overflow_r;
// ---- Add your own wires and registers here if needed ---- //
wire [11:0] abs_A, abs_B;
reg signed [11:0] sum;
reg signed [12:0] tempSum;              // to compute Mean
reg signed [23:0] mulExtend;            // to compute multiplication result
reg signed [11:0] o_mult_w;
reg signed [11:0] macAccumulate;        // to compute Mac accumulate.
reg               macOverFlow;          // to remember Mac_overflow is happened.
// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
assign o_valid = o_valid_r;
assign o_data = o_data_r;
assign o_overflow = o_overflow_r;

// ---- Add your own wire data assignments here if needed ---- //
assign abs_A = (i_data_a[11] == 0)? i_data_a : (~i_data_a + 1'b1); 
assign abs_B = (i_data_b[11] == 0)? i_data_b : (~i_data_b + 1'b1); 
// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

always@(*) begin
    case(i_inst)
        3'b000: begin                       // Signed Addition
            o_data_w = i_data_a + i_data_b;
            o_overflow_w = (~(i_data_a[11] ^ i_data_b[11]) & (i_data_a[11] ^ o_data_w[11]) )? 1 : 0;
        end

        3'b001: begin                       // Signed Subtraction
            o_data_w = i_data_a - i_data_b;
            o_overflow_w = ( (i_data_a[11] ^ i_data_b[11]) & (i_data_a[11] ^ o_data_w[11]) )? 1 : 0;
        end

        3'b010: begin                       // Signed Multiplication
            mulExtend = i_data_a * i_data_b; // need to be rounded before output.

            if( !mulExtend[16] & (|mulExtend[23:17]))       // if it is positive and overflow
                o_overflow_w = 1'b1;
            else if( mulExtend[16] & (mulExtend[23:17] != 7'b1111111))
                o_overflow_w = 1'b1;
            else if( mulExtend[16] ^ o_data_w[11] )         // to check if o_data_w plus 1 in the end will cause overflow or not.
                o_overflow_w = 1'b1;
            else
                o_overflow_w = 1'b0;

            if(mulExtend[4] == 1'b1)
                o_data_w = mulExtend[16:5] + 1'b1;
            else
                o_data_w = mulExtend[16:5];

        end

        3'b011: begin                       // Mac, need to be rounded before output
            mulExtend = i_data_a * i_data_b; // need to be rounded before output.
            
            if( !mulExtend[16] & (|mulExtend[23:17])) begin     // if it is positive and overflow
                o_overflow_w = 1'b1;
                macOverFlow = 1'b1;
            end       
            else if( mulExtend[16] & (mulExtend[23:17] != 7'b1111111)) begin
                o_overflow_w = 1'b1;
                macOverFlow = 1'b1;
            end
            else if(macOverFlow | (~(o_mult_w[11] ^ macAccumulate[11]) & (o_mult_w[11] ^ o_data_w[11]) ))
                o_overflow_w = 1'b1;
            else
                o_overflow_w = 1'b0;


            if(mulExtend[4] == 1'b1)
                o_mult_w = mulExtend[16:5] + 1'b1;
            else
                o_mult_w = mulExtend[16:5];
            
            o_data_w = o_mult_w + macAccumulate;

        end

        3'b100: begin                       // XNOR
            o_overflow_w = 0;
            o_data_w = ~( i_data_a ^ i_data_b);
        end

        3'b101: begin                       // ReLU
            o_overflow_w = 0;
            if(i_data_a > 0)
                o_data_w = i_data_a;
            else
                o_data_w = 0;      
        end

        3'b110: begin                       // Mean
            o_overflow_w = 0;
            tempSum = i_data_a + i_data_b;

            o_data_w = tempSum >>> 1;

        end

        3'b111: begin                       // Absolute Max
            o_overflow_w = 0;
            if(abs_A >= abs_B)
                o_data_w = abs_A;
            else
                o_data_w = abs_B;
        end

        default: begin
            o_data_w = 0;
            o_overflow_w = 0;
        end

    endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always@(posedge i_clk or negedge i_rst_n or posedge i_valid) begin

    if(!i_rst_n) begin
        o_data_r <= 0;
        o_overflow_r <= 0;
        o_valid_r <= 0;
        macAccumulate <= 0;
        macOverFlow <= 0;
        tempSum <= 0;
        o_mult_w <= 0;
        mulExtend <= 0;
        sum <= 0;
    end

    else if(i_valid & i_clk) begin
        o_data_r <= o_data_w;
        o_overflow_r <= o_overflow_w;
        o_valid_r <= 1;
        o_overflow_w <= 1'b0;

        if(i_inst == 3'b011) begin
            macAccumulate <= o_data_w;
            if(o_overflow_w)
                macOverFlow <= 1'b1;
        end
        else begin
            macAccumulate <= 0;
            macOverFlow <= 1'b0;
        end
    end 

    else begin
        o_data_r <= 0;
        o_overflow_r <= 0;
        o_valid_r <= 0;
    end
    
end

endmodule
