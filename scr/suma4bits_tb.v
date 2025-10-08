`include "scr\suma4bits.v"
`timescale 1ps/1ps

module suma4bits_tb();

reg [3:0] A_tb;
reg [3:0] B_tb;
reg Cin_tb;

suma4bits uut(
    .A(A_tb),
    .B(B_tb),
    .Cin(Cin_tb)
);

initial begin
    A_tb = 4'b0000;
    B_tb = 4'b0000;
    Cin_tb = 1'b0;
    #10;
    A_tb = 4'b0101;
    B_tb = 4'b0011;
    Cin_tb = 1'b0;
    #10;
    A_tb = 4'b1010;
    B_tb = 4'b1100;
    Cin_tb = 1'b0;
    #10;
    A_tb = 4'b1111;
    B_tb = 4'b1111;
    Cin_tb = 1'b0;
end

initial begin:TEST_CASE
    $dumpfile("suma4bits_tb.vcd");
    $dumpvars(-1,uut);
  #100 $finish;
end


endmodule