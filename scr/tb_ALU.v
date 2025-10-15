`include "scr\ALU.v"
`timescale 1ns/1ps
module tb_ALU;
  localparam M = 4;

  reg               clk=0, rst=1, init=0;
  reg  [2:0]        opcode;
  reg  [M-1:0]      A,B;
  wire [2*M-1:0]    Y;
  wire              overflow, zero, busy, done;

  ALU #(.M(M)) dut(
    .clk(clk), .rst(rst), .init(init), .opcode(opcode),
    .A(A), .B(B),
    .Y(Y), .overflow(overflow), .zero(zero),
    .busy(busy), .done(done)
  );

  always #5 clk = ~clk;

  // Helpers
  task pulse_init; begin @(negedge clk); init=1; @(negedge clk); init=0; end endtask
  function integer sgn4; input [3:0] x; begin sgn4 = (x>=8)? (x-16): x; end endfunction

  task do_add(input [3:0] a, input [3:0] b);
    automatic int As, Bs, Ss;
    automatic bit ovf_e, zero_e;
    begin
      opcode=3'b000; A=a; B=b; pulse_init();
      @(posedge clk);
      As=sgn4(a); Bs=sgn4(b); Ss=As+Bs;
      ovf_e = (~(As<0 ^ Bs<0)) & ((Ss<0) ^ (As<0));
      zero_e = (((Ss)&255)==0);
      if (Y !== {4'b0,(a+b)&4'hF} || overflow!==ovf_e || zero!==zero_e || done!==1'b1) begin
        $display("FAIL ADD a=%0d b=%0d -> Y=%0h ovf=%0b zero=%0b done=%0b", a,b,Y,overflow,zero,done);
        $fatal;
      end
    end
  endtask

  task do_sub(input [3:0] a, input [3:0] b);
    automatic int As, Bs, Ds;
    automatic bit ovf_e, zero_e, neg_e;
    begin
      opcode=3'b001; A=a; B=b; pulse_init();
      @(posedge clk);
      As=sgn4(a); Bs=sgn4(b); Ds=As-Bs;
      ovf_e = ((As<0) ^ (Bs<0)) & ((As<0) ^ (Ds<0));
      zero_e = ((Ds&255)==0);
      neg_e  = (Ds<0);
      if (Y[3:0] !== ((a - b) & 4'hF) || overflow!==ovf_e || zero!==zero_e) begin
        $display("FAIL SUB a=%0d b=%0d -> Y=%0h ovf=%0b zero=%0b", a,b,Y,overflow,zero);
        $fatal;
      end
      if (done!==1'b1) begin
        $display("FAIL SUB done no pulso");
        $fatal;
      end
    end
  endtask

  task do_xor(input [3:0] a, input [3:0] b);
    begin
      opcode=3'b010; A=a; B=b; pulse_init();
      @(posedge clk);
      if (Y[3:0] !== (a^b) || overflow!==1'b0 || zero!==( (a^b)==0 ) || done!==1'b1) begin
        $display("FAIL XOR a=%0h b=%0h -> Y=%0h ovf=%0b zero=%0b done=%0b", a,b,Y,overflow,zero,done);
        $fatal;
      end
    end
  endtask

  task do_shl(input [3:0] a, input [3:0] b);
    automatic [3:0] exp;
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

  task do_mul(input [3:0] a, input [3:0] b);
    automatic int exp;
    begin
      opcode=3'b100; A=a; B=b; pulse_init();
      if (busy!==1'b1) begin
        $display("WARN: MUL busy no se activó (verifica FSM)"); // no fatal
      end
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
    repeat(3) @(negedge clk); rst=0;

    // ADD dirigidos + aleatorios
    do_add(4'd7,4'd8);
    do_add(4'd15,4'd1);
    for (i=0;i<10;i=i+1) do_add($urandom%16, $urandom%16);

    // SUB
    do_sub(4'd7,4'd8);
    do_sub(4'd8,4'd7);
    for (i=0;i<10;i=i+1) do_sub($urandom%16, $urandom%16);

    // XOR
    do_xor(4'hA,4'h5);
    for (i=0;i<10;i=i+1) do_xor($urandom%16, $urandom%16);

    // SHL
    do_shl(4'h3,4'h1);
    do_shl(4'h9,4'h2);
    for (i=0;i<10;i=i+1) do_shl($urandom%16, $urandom%16);

    // MUL
    do_mul(4'd9,4'd7);
    do_mul(4'd0,4'd15);
    do_mul(4'd15,4'd15);
    for (i=0;i<10;i=i+1) do_mul($urandom%16, $urandom%16);

    $display("OK: ALU pasó todas las pruebas");
    $finish;
  end
endmodule
