`ifndef SUMA4BITS_V
`define SUMA4BITS_V

`include "suma1bit.v"

module suma4bits (
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] S,  
    output [4:0] ST,
    output  Cout
);

wire C0;
wire C1;
wire C2;

suma1bit bit0(.A(A[0]), .B(B[0]), .Cin(Cin), .S(S[0]), .Cout(C0));
suma1bit bit1(.A(A[1]), .B(B[1]), .Cin(C0), .S(S[1]), .Cout(C1));
suma1bit bit2(.A(A[2]), .B(B[2]), .Cin(C1), .S(S[2]), .Cout(C2));
suma1bit bit3(.A(A[3]), .B(B[3]), .Cin(C2), .S(S[3]), .Cout(Cout));

assign ST = {Cout, S};

endmodule

`endif // SUMA4BITS_V