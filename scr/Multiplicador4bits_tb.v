`include "scr\Multiplicador4bits.v"
`timescale 1ps/1ps

module Multiplicador4bits_tb();

    reg        clk_tb;
    reg        rst_tb;
    reg        init_tb;
    reg  [3:0] MD_tb;
    reg  [3:0] MR_tb;
    wire [7:0] PP_tb;
    wire       done_tb;

    initial clk_tb = 1'b0;
    always  #5 clk_tb = ~clk_tb;

    Multiplicador4bits uut (
        .init(init_tb),
        .clk (clk_tb),
        .rst (rst_tb),
        .MD  (MD_tb),
        .MR  (MR_tb),
        .PP  (PP_tb),
        .done(done_tb)
    );

    initial begin: TEST_CASE
        $dumpfile("Multiplicador4bits_tb.vcd");
        $dumpvars(0, Multiplicador4bits_tb); 
    end


    initial begin
        $display("\n=== multiplier_tb: traza por ciclo ===");
        $display("time(ps) | MD MR |  PP  |    A    B  iter | done | state");
        $display("--------------------------------------------------------");
    end

    always @(posedge clk_tb) begin
        $display("%8t |  %0d  %0d | %3d  | %3d %3d   %0d  |  %b   | %b",
                 $time,
                 MD_tb, MR_tb,
                 PP_tb,
                 uut.A, uut.B, uut.iter,
                 done_tb,
                 uut.fsm_state);
    end

    // tarea para ejecutar un caso de prueba con timeout (en ciclos de reloj)
    task run_case(input [3:0] multiplicando, input [3:0] multiplicador, input [7:0] esperado);
        integer timeout;
        begin
            // colocar operandos
            MD_tb = multiplicando;
            MR_tb = multiplicador;

            // esperar estabilidad (menos que un periodo)
            #2;

            // aplicar init síncrono: pulso de 1 ciclo
            @(posedge clk_tb);
            init_tb = 1'b1;
            @(posedge clk_tb);
            init_tb = 1'b0;

            // esperar done con timeout (ej: 40 ciclos)
            timeout = 0;
            while (!done_tb && timeout < 40) begin
                @(posedge clk_tb);
                timeout = timeout + 1;
            end

            // verificar resultado
            if (!done_tb) begin
                $display("[%0t ps] TIMEOUT: %0d x %0d -> PP=%0d (esperado %0d)",
                         $time, multiplicando, multiplicador, PP_tb, esperado);
            end else begin
                if (PP_tb === esperado) begin
                    $display("[%0t ps] PASS: %0d x %0d -> PP=%0d (esperado %0d)",
                             $time, multiplicando, multiplicador, PP_tb, esperado);
                end else begin
                    $display("[%0t ps] FAIL: %0d x %0d -> PP=%0d (esperado %0d)",
                             $time, multiplicando, multiplicador, PP_tb, esperado);
                end
            end

            // small gap before next case
            repeat (2) @(posedge clk_tb);
        end
    endtask

    // Secuencia principal de tests
    initial begin
        // Inicialización
        init_tb = 1'b0;
        MD_tb   = 4'd0;
        MR_tb   = 4'd0;
        rst_tb  = 1'b1;   // aplicar reset síncrono al inicio

        // Mantener rst activo unos ciclos
        repeat (3) @(posedge clk_tb);
        @(posedge clk_tb);
        rst_tb = 1'b0;    // liberar reset
        @(posedge clk_tb);

        $display("\n=== Inicio de tests ===");

        // Tests (multiplicando x multiplicador) -> esperado
        // Test 1: 5 x 3 = 15
        run_case(4'd5, 4'd3, 8'd15);

        // Test 2: 7 x 7 = 49
        run_case(4'd7, 4'd7, 8'd49);

        // Test 3: 6 x 2 = 12
        run_case(4'd6, 4'd2, 8'd12);

        // Test 4: 0 x 7 = 0
        run_case(4'd0, 4'd7, 8'd0);

        $display("=== Fin de tests ===");
        #50;

        $finish;
    end

endmodule