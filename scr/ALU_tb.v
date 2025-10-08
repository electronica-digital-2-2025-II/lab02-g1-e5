`include "scr\ALU.v" 
`timescale 1ns/1ps


module alu4_tb;

  // Clock / reset / init
  reg clk = 0;
  always #5 clk = ~clk;   // 100 MHz

  reg rst;
  reg init;

  // Inputs
  reg  [3:0] A, B;
  reg  [2:0] opcode;

  // Outputs
  wire [7:0] Y;
  wire       overflow;
  wire       zero;

  // Device Under Test
  alu4 dut (
    .clk(clk),
    .rst(rst),
    .init(init),
    .A(A),
    .B(B),
    .opcode(opcode),
    .Y(Y),
    .overflow(overflow),
    .zero(zero)
  );

  // Dumpfile only (no console prints)
  initial begin
    $dumpfile("alu4_tb.vcd");
    $dumpvars(0, alu4_tb);
  end

  // --- Helper tasks (no $display) ---

  // Non-MUL ops: ADD(000), SUB(001), XOR(010), SHL(011)
  task run_nonmul(input [2:0] opc, input [3:0] a, input [3:0] b);
  begin
    opcode = opc; A = a; B = b;
    @(posedge clk); init = 1'b1;
    @(posedge clk); init = 1'b0;  // ALU captures here for non-MUL
    // leave a little settling time in the waveform
    repeat (2) @(posedge clk);
  end
  endtask

  // MUL (100): wait for internal done handshake
  task run_mul(input [3:0] a, input [3:0] b);
  begin
    opcode = 3'b100; A = a; B = b;
    @(posedge clk); init = 1'b1;
    @(posedge clk); init = 1'b0;
    // Wait for the ALU's multiplier to finish (internal signal)
    wait (dut.mul_done === 1'b1);
    @(posedge clk);                 // one extra edge after capture
    repeat (1) @(posedge clk);
  end
  endtask

  // --- Stimulus sequence (probe cases only; comments show expectations) ---
  initial begin
    // Reset
    rst = 1'b1; init = 1'b0; opcode = 3'b000; A = 4'd0; B = 4'd0;
    repeat (2) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);

    // ===== ADD (000) =====
    run_nonmul(3'b000, 4'sd7, 4'sd4);   // 7+4 = 11 (0x0B), ovf=0
    run_nonmul(3'b000, 4'sd7, 4'sd5);   // 7+5 = 12 (0x0C), ovf=1 in 4-bit 2's comp

    // ===== SUB (001) =====
    run_nonmul(3'b001, 4'sd3, 4'sd7);   // 3-7 = -4 (0xC), ovf=0
    run_nonmul(3'b001, -6,     4'sd3);  // -6-3 = -9 -> wraps to +7, ovf=1

    // ===== XOR (010) =====
    run_nonmul(3'b010, 4'b1010, 4'b0110); // 0xA ^ 0x6 = 0xC
    run_nonmul(3'b010, 4'b0101, 4'b0101); // 0x5 ^ 0x5 = 0x0 (zero=1)

    // ===== SHL (011) =====
    run_nonmul(3'b011, 4'b0011, 4'b0010); // 0x3 << 2 = 0xC
    run_nonmul(3'b011, 4'b1111, 4'b0011); // 0xF << 3 = 0x8

    // ===== MUL (100) =====
    run_mul(4'd9,  4'd7);   // 9*7  = 63 (0x3F); ovf relative to 4-bit low nibble
    run_mul(4'd15, 4'd15);  // 15*15 = 225 (0xE1)
    run_mul(4'd0,  4'd7);   // 0*7 = 0

    // Done
    #50 $finish;
  end

endmodule
