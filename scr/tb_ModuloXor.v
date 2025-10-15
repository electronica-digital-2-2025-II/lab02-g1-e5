`include "scr\ModuloXor.v"

`timescale 1ns/1ps
module tb_ModuloXor;
  reg  [3:0] a,b;
  wire [3:0] z;

  ModuloXor dut(.a(a), .b(b), .z(z));

  initial begin
    $dumpfile("tb_ModuloXor.vcd");
    $dumpvars(0, tb_ModuloXor);
  end

  integer i,j;
  initial begin
    for (i=0;i<16;i=i+1) begin
      for (j=0;j<16;j=j+1) begin
        a=i; b=j; #1;
        if (z !== (i^j)) begin
          $display("FAIL a=%0h b=%0h -> z=%0h (esp %0h)", a,b,z, (i^j));
          $fatal;
        end
      end
    end
    $display("OK: ModuloXor");
    #5 $finish;
  end
endmodule

