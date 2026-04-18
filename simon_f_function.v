// =============================================================================
// Module  : simon_f_function
// Purpose : SIMON-32/64 round function  f(x) = (x<<<1 & x<<<8) ^ x<<<2
// =============================================================================
module simon_f_function (
    input  wire [15:0] x,
    output wire [15:0] f_out
);

    wire [15:0] rot1, rot8, rot2;

    
    assign rot1  = {x[14:0], x[15]};
    
    assign rot8  = {x[7:0],  x[15:8]};
    
    assign rot2  = {x[13:0], x[15:14]};

    assign f_out = (rot1 & rot8) ^ rot2;

endmodule
