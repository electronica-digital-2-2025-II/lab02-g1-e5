`timescale 1ns/1ps

module tb_ALU;

  // Clock 100 MHz (T = 10 ns)
  reg clk = 1'b0;
  always #5 clk = ~clk;

  // Señales de control
  reg rst  = 1'b1;
  reg init = 1'b0;

  // Entradas de datos
  reg  [3:0] A  = 4'd0;
  reg  [3:0] B  = 4'd0;
  reg  [2:0] op = 3'b000;

  // Salidas
  wire [7:0] Y;
  wire overflow, zero, negative, done;

  // Opcodes (de acuerdo con tu ALU.v)
  localparam OP_ADD = 3'b000;
  localparam OP_SUB = 3'b001;
  localparam OP_XOR = 3'b010;
  localparam OP_SHL = 3'b011;
  localparam OP_MUL = 3'b100;

  // DUT
  ALU #(.M(4)) dut (
    .clk(clk),
    .rst(rst),
    .init(init),
    .op(op),
    .A(A),
    .B(B),
    .Y(Y),
    .overflow(overflow),
    .zero(zero),
    .negative(negative),
    .done(done)
  );

  // ==== Helpers ====
  task automatic pulse_init();
    begin
      @(negedge clk);
      init <= 1'b1;
      @(negedge clk);
      init <= 1'b0;
    end
  endtask

  // Para operaciones combinacionales (ADD/SUB/XOR/SHL)
  task automatic do_nonmul(input [2:0] opc, input [3:0] a, input [3:0] b, input string name);
    begin
      op <= opc; A <= a; B <= b;
      pulse_init();
      // done debe ir alto por 1 ciclo (según ALU)
      wait(done === 1'b1);
      @(posedge clk);
      $display("[%0t] %-4s A=%0d(0x%0h)  B=%0d(0x%0h)  -> Y=0x%0h ovf=%0b neg=%0b zero=%0b",
                $time, name, a, a, b, b, Y, overflow, negative, zero);
    end
  endtask

  // Para multiplicación secuencial (MUL)
  task automatic do_mul(input [3:0] a, input [3:0] b);
    begin
      op <= OP_MUL; A <= a; B <= b;
      pulse_init();
      // Esperar a que el multiplicador termine
      wait(done === 1'b1);
      @(posedge clk);
      $display("[%0t] MUL  A=%0d(0x%0h)  B=%0d(0x%0h)  -> Y=0x%0h ovf=%0b neg=%0b zero=%0b",
                $time, a, a, b, b, Y, overflow, negative, zero);
    end
  endtask

  initial begin
    // Dump para GTKWave
    $dumpfile("alu_tb.vcd");
    $dumpvars(0, tb_ALU);

    // Reset síncrono
    repeat (3) @(negedge clk);
    rst <= 1'b0;

    // ==== PRUEBAS RÁPIDAS ====

    // ADD
    do_nonmul(OP_ADD, 4'd3 , 4'd5 , "ADD");
    do_nonmul(OP_ADD, 4'd15, 4'd1 , "ADD"); // overflow posible

    // SUB
    do_nonmul(OP_SUB, 4'd13, 4'd5 , "SUB"); // 13-5 = 8
    do_nonmul(OP_SUB, 4'd5 , 4'd13, "SUB"); // 5-13 = -8 (si hay Negative)

    // XOR
    do_nonmul(OP_XOR, 4'b1010, 4'b1100, "XOR");

    // SHL (A<<B[1:0])
    do_nonmul(OP_SHL, 4'b0011, 4'b0001, "SHL"); // 3<<1 = 6
    do_nonmul(OP_SHL, 4'b0011, 4'b0011, "SHL"); // 3<<3 = 24(0x18) -> se verá en los 8b

    // MUL (secuencial)
    do_mul(4'd3 , 4'd5 );
    do_mul(4'd15, 4'd15);

    // Fin
    repeat (5) @(negedge clk);
    $finish;
  end

endmodule
"""
with open('/mnt/data/tb_ALU.v', 'w') as f:
    f.write(tb_code)
print("Saved /mnt/data/tb_ALU.v")


