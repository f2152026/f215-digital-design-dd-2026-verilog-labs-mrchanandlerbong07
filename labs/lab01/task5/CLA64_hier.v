// cla64_hier.v
// BONUS -- hierarchical (2-level) 64-bit carry-lookahead adder.
//
// Structure: 16 four-bit CLA blocks (reusing the cla4 logic, extended
// here as cla4_blk to also expose block-generate/block-propagate), plus
// one second-level lookahead unit that computes each block's carry-in
// directly from Gblk_0..Gblk_15, Pblk_0..Pblk_15, and cin -- structurally
// identical to cla4's own bit-level lookahead, just one level up and
// scaled to 16 inputs instead of 4.

// ---------------------------------------------------------------------
// cla4_blk: same 4-bit CLA logic as cla4.v, with two extra outputs:
//   Gblk = this block generates a carry regardless of its incoming carry
//   Pblk = an incoming carry propagates straight through the whole block
// Both are pure functions of this block's own p0..p3, g0..g3 -- they do
// NOT depend on this block's cin input.
// ---------------------------------------------------------------------
module cla4_blk(
  input  [3:0] a,
  input  [3:0] b,
  input        cin,
  output [3:0] sum,
  output       cout,
  output       Gblk,
  output       Pblk
);

  wire p0, p1, p2, p3;
  wire g0, g1, g2, g3;
  wire c1, c2, c3, c4;

  xor #(2) (p0, a[0], b[0]);
  xor #(2) (p1, a[1], b[1]);
  xor #(2) (p2, a[2], b[2]);
  xor #(2) (p3, a[3], b[3]);

  and #(2) (g0, a[0], b[0]);
  and #(2) (g1, a[1], b[1]);
  and #(2) (g2, a[2], b[2]);
  and #(2) (g3, a[3], b[3]);

  wire t0;
  and #(2) (t0, p0, cin);
  or  #(2) (c1, g0, t0);

  wire t1a, t1b;
  and #(2) (t1a, p1, g0);
  and #(2) (t1b, p1, p0, cin);
  or  #(2) (c2, g1, t1a, t1b);

  wire t2a, t2b, t2c;
  and #(2) (t2a, p2, g1);
  and #(2) (t2b, p2, p1, g0);
  and #(2) (t2c, p2, p1, p0, cin);
  or  #(2) (c3, g2, t2a, t2b, t2c);

  wire t3a, t3b, t3c, t3d;
  and #(2) (t3a, p3, g2);
  and #(2) (t3b, p3, p2, g1);
  and #(2) (t3c, p3, p2, p1, g0);
  and #(2) (t3d, p3, p2, p1, p0, cin);
  or  #(2) (c4, g3, t3a, t3b, t3c, t3d);

  assign cout = c4;

  xor #(2) (sum[0], p0, cin);
  xor #(2) (sum[1], p1, c1);
  xor #(2) (sum[2], p2, c2);
  xor #(2) (sum[3], p3, c3);

  // Block generate: does this block produce a carry on its own?
  wire bt0, bt1, bt2;
  and #(2) (bt0, p3, g2);
  and #(2) (bt1, p3, p2, g1);
  and #(2) (bt2, p3, p2, p1, g0);
  or  #(2) (Gblk, g3, bt0, bt1, bt2);

  // Block propagate: does an incoming carry sail straight through?
  and #(2) (Pblk, p3, p2, p1, p0);

endmodule

// ---------------------------------------------------------------------
// cla64_hier: 16 cla4_blk blocks + one second-level lookahead unit that
// computes each block's carry-in directly (non-recursive) from Gblk[],
// Pblk[], and cin.
// ---------------------------------------------------------------------
module cla64_hier(
  input  [63:0] a,
  input  [63:0] b,
  input         cin,
  output [63:0] sum,
  output        cout
);

  wire [15:0] Gblk, Pblk;
  wire [16:0] c;   // c[0]=cin; c[1]..c[16] are the block-level carries

  assign c[0] = cin;

  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : gen_blk
      cla4_blk BLK (
        .a    (a[4*k+3 : 4*k]),
        .b    (b[4*k+3 : 4*k]),
        .cin  (c[k]),
        .sum  (sum[4*k+3 : 4*k]),
        .cout (),           // unused -- block-level carry comes from the
                             // second-level lookahead below, not a ripple
        .Gblk (Gblk[k]),
        .Pblk (Pblk[k])
      );
    end
  endgenerate

  // Second-level lookahead: direct (non-recursive) block-carry equations,
  // exactly the same sum-of-products pattern as cla4's bit-level carries,
  // just built from Gblk[]/Pblk[] instead of g[]/p[], and scaled to 16
  // inputs instead of 4.
  assign #(2) c[1] = Gblk[0] | (Pblk[0] & cin);
  assign #(2) c[2] = Gblk[1] | (Pblk[1] & Gblk[0]) | (Pblk[1] & Pblk[0] & cin);
  assign #(2) c[3] = Gblk[2] | (Pblk[2] & Gblk[1]) | (Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[4] = Gblk[3] | (Pblk[3] & Gblk[2]) | (Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[5] = Gblk[4] | (Pblk[4] & Gblk[3]) | (Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[6] = Gblk[5] | (Pblk[5] & Gblk[4]) | (Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[7] = Gblk[6] | (Pblk[6] & Gblk[5]) | (Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[8] = Gblk[7] | (Pblk[7] & Gblk[6]) | (Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[9] = Gblk[8] | (Pblk[8] & Gblk[7]) | (Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[10] = Gblk[9] | (Pblk[9] & Gblk[8]) | (Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[11] = Gblk[10] | (Pblk[10] & Gblk[9]) | (Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[12] = Gblk[11] | (Pblk[11] & Gblk[10]) | (Pblk[11] & Pblk[10] & Gblk[9]) | (Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[13] = Gblk[12] | (Pblk[12] & Gblk[11]) | (Pblk[12] & Pblk[11] & Gblk[10]) | (Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[14] = Gblk[13] | (Pblk[13] & Gblk[12]) | (Pblk[13] & Pblk[12] & Gblk[11]) | (Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[15] = Gblk[14] | (Pblk[14] & Gblk[13]) | (Pblk[14] & Pblk[13] & Gblk[12]) | (Pblk[14] & Pblk[13] & Pblk[12] & Gblk[11]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);
  assign #(2) c[16] = Gblk[15] | (Pblk[15] & Gblk[14]) | (Pblk[15] & Pblk[14] & Gblk[13]) | (Pblk[15] & Pblk[14] & Pblk[13] & Gblk[12]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Gblk[11]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Gblk[10]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Gblk[9]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Gblk[8]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Gblk[7]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Gblk[6]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Gblk[5]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Gblk[4]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Gblk[3]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Gblk[2]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Gblk[1]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Gblk[0]) | (Pblk[15] & Pblk[14] & Pblk[13] & Pblk[12] & Pblk[11] & Pblk[10] & Pblk[9] & Pblk[8] & Pblk[7] & Pblk[6] & Pblk[5] & Pblk[4] & Pblk[3] & Pblk[2] & Pblk[1] & Pblk[0] & cin);

  assign cout = c[16];

endmodule