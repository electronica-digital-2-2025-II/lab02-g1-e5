`include "scr\Resta4bits.v"

`timescale 1ns/1ps
module tb_Resta4bits;
  reg  [3:0] A,B;
  wire [3:0] D;
  wire Overflow, Negative, Zero;

  Resta4bits dut(.A(A), .B(B), .D(D), .Overflow(Overflow), .Negative(Negative), .Zero(Zero));

  initial begin
    $dumpfile("tb_Resta4bits.vcd");
    $dumpvars(0, tb_Resta4bits);
  end

  function integer sgn4; input [3:0] x; begin sgn4 = (x>=8)? (x-16): x; end endfunction

  integer a,b;
  initial begin
    for (a=0;a<16;a=a+1) begin
      for (b=0;b<16;b=b+1) begin
        A=a; B=b; #1;
        automatic int  As=sgn4(a), Bs=sgn4(b), Ds=As-Bs;
        automatic bit  expZ = ((Ds & 32'hFF)==0);
        automatic bit  expN = (Ds < 0);
        automatic bit  expV = ((As<0) ^ (Bs<0)) & ((As<0) ^ (Ds<0));
        automatic [3:0] expD = (a - b) & 4'hF;

        if (D!==expD || Zero!==expZ || Negative!==expN || Overflow!==expV) begin
          $display("FAIL A=%0d B=%0d -> D=%0h Z=%0b N=%0b V=%0b (esp %0h %0b %0b %0b)",
            A,B,D,Zero,Negative,Overflow,expD,expZ,expN,expV);
          $fatal;
        end
      end
    end
    $display("OK: Resta4bits");
    #5 $finish;
  end
endmodule


