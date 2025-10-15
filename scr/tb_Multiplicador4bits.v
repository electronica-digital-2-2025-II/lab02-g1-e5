`include "scr\Multiplicador4bits.v"

`timescale 1ns/1ps
module tb_Multiplicador4bits;
  reg clk=0, rst=1, init=0;
  reg  [3:0] MD, MR;
  wire [7:0] PP;
  wire done;

  Multiplicador4bits dut(.clk(clk), .rst(rst), .init(init), .MD(MD), .MR(MR), .PP(PP), .done(done));

  // clock
  always #5 clk = ~clk;

  // VCD
  initial begin
    $dumpfile("tb_Multiplicador4bits.vcd");
    $dumpvars(0, tb_Multiplicador4bits);
  end

  task start_mult(input [3:0] a, input [3:0] b);
    begin
      @(negedge clk);
      MD=a; MR=b; init=1;
      @(negedge clk);
      init=0;
    end
  endtask

  task wait_done_and_check(input [3:0] a, input [3:0] b);
    automatic int exp;
    begin
      wait(done===1'b1);
      @(posedge clk);
      exp = a*b;
      if (PP !== exp[7:0]) begin
        $display("FAIL %0d*%0d -> PP=%0d (esp %0d)", a,b,PP,exp);
        $fatal;
      end
    end
  endtask

  integer i,j;
  initial begin
    repeat(3) @(negedge clk); rst=0;

    // Dirigidos
    start_mult(4'd0,4'd0); wait_done_and_check(0,0);
    start_mult(4'd1,4'd9); wait_done_and_check(1,9);
    start_mult(4'd9,4'd1); wait_done_and_check(9,1);
    start_mult(4'd15,4'd15); wait_done_and_check(15,15);

    // Aleatorios
    for (i=0;i<16;i=i+1) begin
      j = $urandom_range(0,15);
      start_mult(i[3:0], j[3:0]); wait_done_and_check(i[3:0], j[3:0]);
    end

    // Back-to-back
    start_mult(4'd7,4'd12);
    start_mult(4'd3,4'd5);  // si tu FSM ignora durante busy, está bien
    wait_done_and_check(7,12);
    start_mult(4'd3,4'd5);  wait_done_and_check(3,5);

    $display("OK: Multiplicador4bits");
    #10 $finish;
  end
endmodule
