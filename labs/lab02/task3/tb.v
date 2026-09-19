// tb.v
// Self-checking testbench for 2-bit unsigned magnitude comparator.

module tb;

  reg  [1:0] t_a, t_b;
  wire       t_gt, t_lt, t_eq;

  comp2 DUT (
    .A  (t_a),
    .B  (t_b),
    .GT (t_gt),
    .LT (t_lt),
    .EQ (t_eq)
  );

  // Waveform dump configuration (DO NOT CHANGE)
  string vcd_file;
  initial begin
    if ($value$plusargs("vcd=%s", vcd_file)) begin
      $dumpfile(vcd_file);
      $dumpvars(0, DUT);
    end
  end

  integer i, j;
  integer errors;

  initial begin
    errors = 0;

    // Exhaustive: all 16 combinations of A(2-bit) x B(2-bit)
    for (i = 0; i < 4; i = i + 1) begin
      for (j = 0; j < 4; j = j + 1) begin
        t_a = i; t_b = j;
        #5;

        // Check: exactly one of GT, LT, EQ must be 1
        if ((t_gt + t_lt + t_eq) !== 1) begin
          $display("ERROR at A=%0d B=%0d: GT=%b LT=%b EQ=%b (not exactly one hot)",
                   t_a, t_b, t_gt, t_lt, t_eq);
          errors = errors + 1;
        end

        // Check correctness of each output
        if (i > j && !t_gt) begin
          $display("ERROR at A=%0d B=%0d: expected GT=1", t_a, t_b);
          errors = errors + 1;
        end
        if (i < j && !t_lt) begin
          $display("ERROR at A=%0d B=%0d: expected LT=1", t_a, t_b);
          errors = errors + 1;
        end
        if (i == j && !t_eq) begin
          $display("ERROR at A=%0d B=%0d: expected EQ=1", t_a, t_b);
          errors = errors + 1;
        end
      end
    end

    if (errors == 0)
      $display("ALL TESTS PASSED");
    else
      $display("FAILED with %0d error(s)", errors);

    $finish;
  end

  initial
    $monitor($time, " A=%b B=%b | GT=%b LT=%b EQ=%b", t_a, t_b, t_gt, t_lt, t_eq);

endmodule