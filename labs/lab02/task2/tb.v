// tb.v
// Starter testbench template -- YOU complete this file.

module tb;

  // Inputs and outputs
  reg  [1:0] t_sel;
  wire [7:0] t_dout;

  // Instantiate DUT
  lut DUT (
    .sel  (t_sel),
    .dout (t_dout)
  );

  // Waveform dump configuration (DO NOT CHANGE)
  string vcd_file;
  initial begin
    if ($value$plusargs("vcd=%s", vcd_file)) begin
      $dumpfile(vcd_file);
      $dumpvars(0, DUT);
    end
  end

  initial begin
    // Apply all 4 sel values, 5 time units apart
    t_sel = 2'b00; #5;  // expect 0*0 = 0
    t_sel = 2'b01; #5;  // expect 1*1 = 1
    t_sel = 2'b10; #5;  // expect 2*2 = 4
    t_sel = 2'b11; #5;  // expect 3*3 = 9
    $finish;
  end

  initial
    $monitor($time, " sel=%b | dout=%d", t_sel, t_dout);

endmodule