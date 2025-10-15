`ifndef SUMA1BIT_V
`define SUMA1BIT_V

module suma1bit(
    input A,
    input B,
    input Cin,
    output S,
    output Cout
);

wire xor1;
wire and1;
wire and2;

assign xor1 = A ^ B;
assign and1 = A & B;
assign and2 = Cin & xor1;
assign S = Cin ^ xor1;
assign Cout =  and1 | and2;

endmodule

`endif // SUMA1BIT_V