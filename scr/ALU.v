
// Ops:
//   000: ADD   (A + B)
//   001: SUB   (A - B)
//   010: XOR   (A ^ B)
//   011: SHL   (A << B[log2(M)-1:0])
//   100: MUL   (A * B)  -- secuencial, usa Multiplicador4bits
// ===============================================
module ALU #(
    parameter integer M = 4
)(
    input  wire               clk,
    input  wire               rst,        
    input  wire               init,       
    input  wire [2:0]         opcode,     
    input  wire [M-1:0]       A,
    input  wire [M-1:0]       B,
    output reg  [2*M-1:0]     Y,          
    output reg                overflow,   
    output reg                zero,       
    output wire               busy,       
    output reg                done        
);

    
    // Aux: ancho del desplazamiento (al menos 1)
    localparam integer SHIFT_W = (M <= 2) ? 1 : $clog2(M);

    // Operaciones combinacionales
    // SUMA
    wire [M-1:0] add_S;
    wire         add_Cout;
    suma4bits u_add (
        .A   (A),
        .B   (B),
        .Cin (1'b0),
        .S   (add_S),
        .ST  (),          // sin usar
        .Cout(add_Cout)
    );

    // RESTA 
    wire [M-1:0] sub_D;
    wire         sub_Overflow, sub_Negative, sub_Zero;
    Resta4bits u_sub (
        .A        (A),
        .B        (B),
        .D        (sub_D),
        .Overflow (sub_Overflow),
        .Negative (sub_Negative),
        .Zero     (sub_Zero)
    );

    // XOR
    wire [M-1:0] xorz = A ^ B;

    // SHIFT LEFT lógico: limitar cantidad con SHIFT_W
    wire [M-1:0] shl  = A << B[SHIFT_W-1:0];

    // Overflow suma con signo: (~(Amsb^Bmsb)) & (Amsb^Sumsb)
    wire ovf_add = (~(A[M-1] ^ B[M-1])) & (A[M-1] ^ add_S[M-1]);

    // Multiplicación secuencial 4x4
    wire [2*M-1:0] mul_PP;
    wire           mul_done;

    Multiplicador4bits u_mul (
        .clk (clk),
        .rst (rst),
        .init(opcode==3'b100 && init),  // solo dispara cuando opcode=mul
        .MD  (A),
        .MR  (B),
        .PP  (mul_PP),
        .done(mul_done)
    );

    assign busy = (opcode==3'b100) && ~mul_done;

    // ----------------------------------------------------------------
    // Selección y registro de salida
    //  - Para no-mul: latch con init (un ciclo)
    //  - Para mul:    actualizar en mul_done
    //  - done:
    //      * no-mul: pulso 1 ciclo cuando init=1
    //      * mul:    replica mul_done
    // ----------------------------------------------------------------
    wire [2*M-1:0] y_comb =
        (opcode==3'b000) ? {{M{1'b0}}, add_S} :
        (opcode==3'b001) ? {{M{1'b0}}, sub_D} :
        (opcode==3'b010) ? {{M{1'b0}}, xorz } :
        (opcode==3'b011) ? {{M{1'b0}}, shl  } :
                           mul_PP; // MUL

    wire ovf_comb =
        (opcode==3'b000) ? ovf_add      :
        (opcode==3'b001) ? sub_Overflow :
                           1'b0;

    // done pulse para no-mul
    wire nonmul = (opcode != 3'b100);

    always @(posedge clk) begin
        if (rst) begin
            Y        <= {2*M{1'b0}};
            overflow <= 1'b0;
            zero     <= 1'b1;
            done     <= 1'b0;
        end else begin
            // Por defecto done se limpia; lo levantamos en los eventos válidos
            done <= 1'b0;

            if (nonmul) begin
                // ADD/SUB/XOR/SHL: latch cuando init=1
                if (init) begin
                    Y        <= y_comb;
                    overflow <= ovf_comb;
                    zero     <= (y_comb == {2*M{1'b0}});
                    done     <= 1'b1;  // pulso 1 ciclo
                end
            end else begin
                // MUL: actualizar cuando el multiplicador indique done
                if (mul_done) begin
                    Y        <= mul_PP;
                    overflow <= 1'b0; // para 4x4 sin signo no se marca overflow
                    zero     <= (mul_PP == {2*M{1'b0}});
                    done     <= 1'b1;  // pulso cuando termina
                end
            end
        end
    end

endmodule
