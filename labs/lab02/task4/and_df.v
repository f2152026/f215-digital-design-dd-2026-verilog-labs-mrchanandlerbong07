// and_df.v
// 2-input AND gate, DATAFLOW style with #5 transport delay.

module and_df (
  input  a,
  input  b,
  output y
);

  assign #5 y = a & b;

endmodule