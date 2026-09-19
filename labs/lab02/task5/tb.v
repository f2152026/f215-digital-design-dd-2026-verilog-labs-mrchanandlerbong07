// tb.v
// Self-checking testbench for 1-bit-opcode ALU.

module tb;

  reg  [3:0] t_a, t_b;
  reg        t_op;
  wire [3:0] t_result;

  alu DUT (
    .a      (t_a),
    .b      (t_b),
    .op     (t_op),
    .result (t_result)
  );

  // Waveform dump configuration
  string vcd_file;
  initial begin
    if ($value$plusargs("vcd=%s", vcd_file)) begin
      $dumpfile(vcd_file);
      $dumpvars(0, DUT);
    end
  end

  integer i, j, k;
  integer errors;
  reg [3:0] expected;

  initial begin
    errors = 0;

    // Test all a, b combos for both op values
    for (k = 0; k < 2; k = k + 1) begin
      for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
          t_a = i; t_b = j; t_op = k;
          #5;

          if (k == 0)
            expected = (i + j) & 4'hF;
          else
            expected = (i - j) & 4'hF;

          if (t_result !== expected) begin
            $display("ERROR: a=%0d b=%0d op=%0d | result=%0d expected=%0d",
                     t_a, t_b, t_op, t_result, expected);
            errors = errors + 1;
          end
        end
      end
    end

    // Extra: toggle op with fixed a, b to catch sensitivity-list bug
    t_a = 4'd7; t_b = 4'd3;
    t_op = 0; #5;
    if (t_result !== 4'd10) begin
      $display("ERROR: op toggle add failed, got %0d expected 10", t_result);
      errors = errors + 1;
    end
    t_op = 1; #5;
    if (t_result !== 4'd4) begin
      $display("ERROR: op toggle sub failed, got %0d expected 4", t_result);
      errors = errors + 1;
    end

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED with %0d error(s)", errors);

    $finish;
  end

  initial
    $monitor($time, " a=%0d b=%0d op=%b | result=%0d", t_a, t_b, t_op, t_result);

endmodule