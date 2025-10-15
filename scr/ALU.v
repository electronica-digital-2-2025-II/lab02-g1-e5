`include "scr\suma4bits.v"
`include "scr\Resta4bits.v"
`include "scr\Multiplicador4bits.v"
`include "scr\Mover_Izquierda.v"
`include "scr\ModuloXor.v"

module adder4_if (
    input  wire [3:0] A, B,
    output wire [4:0] ST
);

    suma4bits u_add (.A(A), .B(B), .Cin(1'b0), .ST(ST), .Cout());

endmodule

module sub4_if (
    input  wire [3:0] A, B,
    output wire [3:0] D,
    output wire Overflow
);
    
    Resta4bits u_sub (.A(A), .B(B), .D(D), .Overflow(Overflow), .Negative(), .Zero()); 

endmodule

module xor4_if (
    input  wire [3:0] A, B,
    output wire [3:0] X
);
    xor_1 b0 (.a(A[0]), .b(B[0]), .z(X[0]));
    xor_1 b1 (.a(A[1]), .b(B[1]), .z(X[1]));
    xor_1 b2 (.a(A[2]), .b(B[2]), .z(X[2]));
    xor_1 b3 (.a(A[3]), .b(B[3]), .z(X[3]));
endmodule

module shl4_if (
    input  wire [3:0] A,
    input  wire [1:0] B,
    output wire [3:0] E
);
    Mover_Izquierda u_sh (.A(A), .B(B), .E(E)); 
endmodule

module mul4_if (
    input  wire       clk,
    input  wire       rst,
    input  wire       init,        
    input  wire [3:0] A, B,        
    output wire [7:0] P,           
    output wire       done         
);

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
endmodule

module alu4 #(
    parameter N = 4,
    parameter M = 8
) (
    input  wire           clk,
    input  wire           rst,          // added: to drive the sequential multiplier
    input  wire           init,         // for non-MUL capture; also used to start MUL
    input  wire [N-1:0]   A,
    input  wire [N-1:0]   B,
    input  wire [2:0]     opcode,       // 000 add, 001 sub, 010 xor, 011 shl, 100 mul
    output reg  [M-1:0]   Y,
    output reg            overflow,
    output reg            zero
);

    wire [3:0] sum4, diff4, xor4, shl4;
    wire [M-1:0] prod8;   // 8-bit product
    wire         ovf_sub; // from subtractor
    wire         mul_done;

    // --- Instantiate operators ---
    adder4_if u_add  (.A(A[3:0]), .B(B[3:0]),       .S(sum4));

    sub4_if   u_sub  (.A(A[3:0]), .B(B[3:0]),       .D(diff4), .Overflow(ovf_sub));

    xor4_if   u_xor  (.A(A[3:0]), .B(B[3:0]),       .X(xor4));

    shl4_if   u_shl  (.A(A[3:0]), .B(B[1:0]),       .E(shl4)); 

    // Start multiplier only when opcode==MUL
    wire init_mul = init & (opcode == 3'b100);
    mul4_if   u_mul  (.clk(clk), .rst(rst), .init(init_mul),
                      .A(A[3:0]), .B(B[3:0]), .P(prod8), .done(mul_done));

    // ---- Overflow rules (two's complement for add/sub) ----
    wire ovf_add = (A[N-1] == B[N-1]) && (sum4[N-1]  != A[N-1]);
    //wire ovf_sub = (A[N-1] != B[N-1]) && (diff4[N-1] != A[N-1]);
    wire ovf_mul = |prod8[7:4]; 

    // ---- Opcode-driven multiplexer (combinational) ----
    reg [M-1:0] y_sel;
    reg         ovf_sel;
    always @* begin
        y_sel   = {M{1'b0}};
        ovf_sel = 1'b0;
        case (opcode)
            3'b000: begin y_sel = {{(M-4){1'b0}}, sum4 }; ovf_sel = ovf_add; end
            3'b001: begin y_sel = {{(M-4){1'b0}}, diff4}; ovf_sel = ovf_sub; end
            3'b010: begin y_sel = {{(M-4){1'b0}}, xor4 }; ovf_sel = 1'b0;   end
            3'b011: begin y_sel = {{(M-4){1'b0}}, shl4 }; ovf_sel = 1'b0;   end
            3'b100: begin y_sel = prod8;                 ovf_sel = ovf_mul; end
            default: begin y_sel = {M{1'b0}};            ovf_sel = 1'b0;    end
        endcase
    end

        // ---- Output registers ----
    // Non-MUL ops: capture on init. MUL: capture on mul_done.
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
