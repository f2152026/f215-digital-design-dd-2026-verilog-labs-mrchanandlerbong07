// and_beh_before.v
// 2-input AND gate, BEHAVIORAL style with #5 inter-assignment delay.
// The delay comes BEFORE the assignment, so `a & b` is evaluated
// AFTER the delay using whatever values exist at that later time.

module and_beh_before (
  input      a,
  input      b,
  output reg y
);

  always @(*) begin
    #5
    y = a & b;
  end


endmodule