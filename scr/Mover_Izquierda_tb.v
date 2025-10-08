`include "scr\Mover_Izquierda.v"
`timescale 1ns/1ps
module MoverIzquierda_tb;
    reg  [3:0] A;
    reg  [1:0] B;
    wire [3:0] C;

    // DUT
    Mover_Izquierda dut (.A(A), .B(B), .C(C));

    initial begin
        $dumpfile("MoverIzquierda_tb.vcd");
        $dumpvars(0, MoverIzquierda_tb);

        // Probe cases
        A = 4'b1011; B = 2'd0; #5;   // expect 1011
        B = 2'd1;         #5;        // expect 0101
        B = 2'd2;         #5;        // expect 0010
        B = 2'd3;         #5;        // expect 0001

        A = 4'b0101; B = 2'd1; #5;   // expect 0010
        A = 4'b1111; B = 2'd3; #5;   // expect 0001
        A = 4'b0001; B = 2'd2; #5;   // expect 0000

        $finish;
    end
endmodule
