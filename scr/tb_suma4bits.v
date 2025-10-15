`include "scr\suma4bits.v"

`timescale 1ns/1ps
module tb_suma4bits;
  reg  [3:0] A,B;
  reg        Cin;
  wire [3:0] S;
  wire [4:0] ST;
  wire       Cout;

  suma4bits dut(.A(A),.B(B),.Cin(Cin),.S(S),.ST(ST),.Cout(Cout));

  initial begin
    $dumpfile("tb_suma4bits.vcd");
    $dumpvars(0, tb_suma4bits);
  end

  integer a,b,ci;
  initial begin
    for (ci=0;ci<2;ci=ci+1) begin
      for (a=0;a<16;a=a+1) begin
        for (b=0;b<16;b=b+1) begin
          A=a; B=b; Cin=ci; #1;
          automatic int exp = a + b + ci;
          check(S, Cout, exp[3:0], exp[4]);
        end
      end
    end
    $display("OK: suma4bits");
    #5 $finish;
  end

  task check(input [3:0] s, input c, input [3:0] exps, input expc);
    if (s!==exps || c!==expc) begin
      $display("FAIL A=%0d B=%0d Cin=%0d -> S=%0h C=%0b (esp %0h %0b)",
        A,B,Cin,s,c,exps,expc);
      $fatal;
    end
  endtask
endmodule

