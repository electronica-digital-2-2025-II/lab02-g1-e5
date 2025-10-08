// shifter4_logical_right.v
module Mover_Izquierda (
    input  wire [3:0] A,
    input  wire [1:0] B,   // shift amount: 0..3
    output wire [3:0] E
);
    assign C = A << B;     
endmodule
