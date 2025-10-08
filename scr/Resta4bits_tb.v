`include "scr\Resta4bits.v"
// sub4b_tb.v
`timescale 1ns/1ps
module Resta4bits_tb;
  reg  [3:0] A, B;
  wire [3:0] D;
  wire       Ov, N, Z;

  Resta4bits dut(.A(A), .B(B), .D(D), .Overflow(Ov), .Negative(N), .Zero(Z));

  initial begin
    $dumpfile("Resta4bits_tb.vcd");   // for GTKWave
    $dumpvars(0, Resta4bits_tb);

    // Vector 1: +7 - +2 = +5, no overflow
    A = 4'sd7;  B = 4'sd2;  #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    // Vector 2: +3 - +5 = -2, no overflow
    A = 4'sd3;  B = 4'sd5;  #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    // Vector 3: -3 - +5 = -8, fits exactly, no overflow
    A = -4'sd3; B = 4'sd5;  #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    // Vector 4: +7 - (-2) = +9 -> out of range, overflow=1
    A = 4'sd7;  B = -4'sd2; #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    // Vector 5: -8 - +1 = -9 -> out of range, overflow=1
    A = -4'sd8; B = 4'sd1;  #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    // Vector 6: any - itself = 0
    A = 4'sd5;  B = 4'sd5;  #1;
    $display("A=%0d B=%0d | D=%0d (0x%0h) Ov=%b N=%b Z=%b", $signed(A), $signed(B), $signed(D), D, Ov, N, Z);

    $finish;
  end
endmodule
