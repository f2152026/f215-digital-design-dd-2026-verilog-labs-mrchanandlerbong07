// and_beh_intra.v
// 2-input AND gate, BEHAVIORAL style with #5 intra-assignment delay.
// The RHS is evaluated NOW, but the assignment to y happens 5 units later.

module and_beh_intra (
  input      a,
  input      b,
  output reg y
);

  always @(*) begin
    y = #5 a & b;
  end

endmodule