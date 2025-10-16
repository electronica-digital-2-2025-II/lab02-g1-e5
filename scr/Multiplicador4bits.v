module Multiplicador4bits(
    input  wire       clk,
    input  wire       rst,      
    input  wire       init,     
    input  wire [3:0] MD,       
    input  wire [3:0] MR,     
    output reg  [7:0] PP,       
    output reg        done     
);
    // Estados
    localparam [2:0] S_IDLE  = 3'b000,
                     S_CHECK = 3'b001,
                     S_ADD   = 3'b010,
                     S_SHIFT = 3'b011,
                     S_DONE  = 3'b100;

    reg [2:0] state;
    reg [7:0] acc;      // acumulador parcial (alto) + MR desplazado (bajo)
    reg [3:0] mdr;      // MD alineado para sumas
    reg [2:0] cnt;      // 0..4 (4 ciclos)

    // opcional: sincronizar init (si viene asíncrono)
    reg init_d;
    wire init_rise = init & ~init_d;

    always @(posedge clk) begin
        if (rst) begin
            init_d <= 1'b0;
        end else begin
            init_d <= init;
        end
    end

    // FSM
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            acc   <= 8'd0;
            mdr   <= 4'd0;
            cnt   <= 3'd0;
            PP    <= 8'd0;
            done  <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    if (init || init_rise) begin
                        // cargar registros
                        acc   <= {4'b0000, MR}; // MR en los 4 LSB
                        mdr   <= MD;
                        cnt   <= 3'd0;
                        state <= S_CHECK;
                    end
                end
                S_CHECK: begin
                    // Si LSB de acc es 1, sumamos MD desplazado a los 4 MSB
                    if (acc[0]) state <= S_ADD;
                    else         state <= S_SHIFT;
                end
                S_ADD: begin
                    acc[7:4] <= acc[7:4] + mdr; // suma en la parte alta
                    state    <= S_SHIFT;
                end
                S_SHIFT: begin
                    // desplazamiento lógico a la derecha de todo el registro
                    acc <= {1'b0, acc[7:1]};
                    cnt <= cnt + 3'd1;
                    if (cnt == 3'd3) state <= S_DONE; // 4 iteraciones
                    else              state <= S_CHECK;
                end
                S_DONE: begin
                    PP   <= acc;
                    done <= 1'b1;
                    if (init || init_rise) state <= S_IDLE; // permitir nuevo ciclo
                end
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule

