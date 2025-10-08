`include "scr\suma4bits.v"

// sub4b_signed.v
module Resta4bits(
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [3:0] D,         // D = A - B  
    output wire       Overflow,  // Overflow del complemento a 2
    output wire       Negative,  // Avisa que es negativo
    output wire       Zero       // Avisa que dió 0
);
  wire [3:0] Bx = ~B;  // B negado
  wire       Cout;

  // Two’s-complement subtraction: A - B = A + (~B) + 1
  suma4bits u_add(.A(A), .B(Bx), .Cin(1'b1), .S(D), .Cout(Cout));

  // Signed overflow for subtraction:
  assign Overflow = (A[3] ^ B[3]) & (A[3] ^ D[3]);
  // Helpful CPU-like flags:
  assign Negative = D[3];
  assign Zero     = (D == 4'b0000);
endmodule
