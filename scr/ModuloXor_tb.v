`include "scr\ModuloXor.v"
`timescale 1ns/1ps

module xor1_tb;
    reg  a, b;
    wire z;

    // DUT
    xor_1 dut (.a(a), .b(b), .z(z));

    // VCD for GTKWave
    initial begin
        $dumpfile("xor1_tb.vcd");
        $dumpvars(0, xor1_tb);
    end

    // (Optional) Console probe
    initial begin
        $display(" t(ns) | a b | z");
        $monitor("%6t | %b %b | %b", $time, a, b, z);
    end

    // Probe cases
    initial begin
        a = 0; b = 0; #5;   // 0 ^ 0 -> 0
        a = 0; b = 1; #5;   // 0 ^ 1 -> 1
        a = 1; b = 0; #5;   // 1 ^ 0 -> 1
        a = 1; b = 1; #5;   // 1 ^ 1 -> 0
        $finish;
    end
endmodule

/*
`timescale 1ns/1ps

module xorn_tb;
    localparam N = 8;

    reg  [N-1:0] a, b;
    wire [N-1:0] z;

    // DUT
    xorn #(.N(N)) dut (.a(a), .b(b), .z(z));

    // VCD for GTKWave
    initial begin
        $dumpfile("xorn_tb.vcd");
        $dumpvars(0, xorn_tb);
    end

    // Quick display of results
    initial begin
        $display("   time       a        b       |      z");
        $monitor("%8t  0x%0h   0x%0h  |  0x%0h", $time, a, b, z);
    end

    // Stimulus: a few concise cases
    initial begin
        a = {N{1'b0}}; b = {N{1'b0}}; #2;   // 00…0 ^ 00…0 = 00…0
        a = {N{1'b0}}; b = {N{1'b1}}; #2;   // 00…0 ^ 11…1 = 11…1
        a = {N{1'b1}}; b = {N{1'b1}}; #2;   // 11…1 ^ 11…1 = 00…0
        a = 8'hAA;      b = 8'h55;    #2;   // alternation (requires N>=8)
        a = 8'h0F;      b = 8'hF0;    #2;   // complementary nibbles (N>=8)
        a = 8'b01011010; b = 8'b00111100; #2; // mixed pattern (N>=8)
        $finish;
    end
endmodule

*/
