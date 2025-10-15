`include "ALU.v"
`include "Multiplicador4bits.v"
`include "Resta4bits.v"
`include "suma4bits.v"
`include "suma1bit.v"
`include "ModuloXor.v"
`include "Mover_Izquierda.v"

`timescale 1ns/1ps
module tb_ALU;
  parameter M = 4;

  reg               clk, rst, init;
  reg  [2:0]        opcode;
  reg  [M-1:0]      A,B;
  wire [2*M-1:0]    Y;
  wire              overflow, zero, busy, done;

  ALU #(M) dut(
    .clk(clk), .rst(rst), .init(init), .opcode(opcode),
    .A(A), .B(B),
    .Y(Y), .overflow(overflow), .zero(zero),
    .busy(busy), .done(done)
  );

  initial begin
    $dumpfile("tb_ALU.vcd");
    $dumpvars(0, tb_ALU);
  end

  // clock
  initial begin clk=0; forever #5 clk = ~clk; end

  // helpers (sin automatic/int)
  task pulse_init; begin @(negedge clk); init=1; @(negedge clk); init=0; end endtask
  function integer sgn4; input [3:0] x; begin sgn4 = (x>=8)? (x-16): x; end endfunction

  task do_add; input [3:0] a; input [3:0] b;
    integer As, Bs, Ss; reg ovf_e, zero_e;
    begin
      opcode=3'b000; A=a; B=b; pulse_init();
      @(posedge clk);
      As=sgn4(a); Bs=sgn4(b); Ss=As+Bs;
      ovf_e = (~((As<0) ^ (Bs<0))) & (((Ss<0) ^ (As<0)));
      zero_e = ((Ss & 32'hFF)==0);
      if (Y !== {4'b0, (a+b)&4'hF} || overflow!==ovf_e || zero!==zero_e || done!==1'b1) begin
        $display("FAIL ADD a=%0d b=%0d -> Y=%0h ovf=%0b zero=%0b done=%0b", a,b,Y,overflow,zero,done);
        $fatal;
      end
    end
  endtask

  task do_sub; input [3:0] a; input [3:0] b;
    integer As, Bs, Ds; reg ovf_e, zero_e;
    begin
      opcode=3'b001; A=a; B=b; pulse_init();
      @(posedge clk);
      As=sgn4(a); Bs=sgn4(b); Ds=As-Bs;
      ovf_e = ((As<0) ^ (Bs<0)) & ((As<0) ^ (Ds<0));
      zero_e = ((Ds & 32'hFF)==0);
      if (Y[3:0] !== ((a-b)&4'hF) || overflow!==ovf_e || zero!==zero_e || done!==1'b1) begin
        $display("FAIL SUB a=%0d b=%0d -> Y=%0h ovf=%0b zero=%0b done=%0b", a,b,Y,overflow,zero,done);
        $fatal;
      end
    end
  endtask

  task do_xor; input [3:0] a; input [3:0] b;
    reg [3:0] exp;
    begin
      opcode=3'b010; A=a; B=b; pulse_init();
      @(posedge clk);
      exp = a ^ b;
      if (Y[3:0] !== exp || overflow!==1'b0 || zero!==(exp==0) || done!==1'b1) begin
        $display("FAIL XOR a=%0h b=%0h -> Y=%0h ovf=%0b zero=%0b done=%0b", a,b,Y,overflow,zero,done);
        $fatal;
      end
    end
  endtask

  task do_shl; input [3:0] a; input [3:0] b;
    reg [3:0] exp;
    begin
      opcode=3'b011; A=a; B=b; pulse_init();
      @(posedge clk);
      exp = (a << (b[1:0])) & 4'hF;
      if (Y[3:0] !== exp || overflow!==1'b0 || zero!==(exp==0) || done!==1'b1) begin
        $display("FAIL SHL a=%0h b=%0h -> Y=%0h exp=%0h", a,b,Y,exp);
        $fatal;
      end
    end
  endtask

  task do_mul; input [3:0] a; input [3:0] b;
    integer exp;
    begin
      opcode=3'b100; A=a; B=b; pulse_init();
      wait(done===1'b1);
      @(posedge clk);
      exp = a*b;
      if (Y !== exp[7:0] || zero !== (exp==0)) begin
        $display("FAIL MUL a=%0d b=%0d -> Y=%0d exp=%0d", a,b,Y,exp);
        $fatal;
      end
    end
  endtask

  integer i;

  initial begin
    // reset
    rst=1; init=0; A=0; B=0; opcode=3'b000;
    repeat(3) @(negedge clk); rst=0;

    // ADD
    do_add(4'd7,4'd8);
    do_add(4'd15,4'd1);
    for (i=0;i<8;i=i+1) do_add($random%16, $random%16);

    // SUB
    do_sub(4'd7,4'd8);
    do_sub(4'd8,4'd7);
    for (i=0;i<8;i=i+1) do_sub($random%16, $random%16);

    // XOR
    do_xor(4'hA,4'h5);
    for (i=0;i<8;i=i+1) do_xor($random%16, $random%16);

    // SHL
    do_shl(4'h3,4'h1);
    do_shl(4'h9,4'h2);
    for (i=0;i<8;i=i+1) do_shl($random%16, $random%16);

    // MUL
    do_mul(4'd9,4'd7);
    do_mul(4'd0,4'd15);
    do_mul(4'd15,4'd15);
    for (i=0;i<8;i=i+1) do_mul($random%16, $random%16);

    $display("OK: ALU");
    #10 $finish;
  end
endmodule

