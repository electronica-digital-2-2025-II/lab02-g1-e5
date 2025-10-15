`include "scr\Mover_Izquierda.v"

`timescale 1ns/1ps
module tb_Mover_Izquierda;
  reg  [3:0] A;
  reg  [1:0] B;
  wire [3:0] E;

  Mover_Izquierda dut(.A(A), .B(B), .E(E));

  initial begin
    $dumpfile("tb_Mover_Izquierda.vcd");
    $dumpvars(0, tb_Mover_Izquierda);
  end

  integer a,b;
  initial begin
    for (a=0;a<16;a=a+1) begin
      for (b=0;b<4;b=b+1) begin
        A=a; B=b; #1;
        automatic [3:0] exp = (a << b) & 4'hF;
        if (E !== exp) begin
          $display("FAIL A=%0h B=%0d -> E=%0h (esp %0h)", A,B,E,exp);
          $fatal;
        end
      end
    end
    $display("OK: Mover_Izquierda");
    #5 $finish;
  end
endmodule

