`timescale 1ns/1ps

module ksa_tb;

  logic stop;
  logic CLOCK_50;
  logic [3:0] KEY;
  logic [9:0] SW;
  logic [9:0] LEDR;
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  logic solution_core1;

  // Instantiate the ksa module
  ksa uut (
    .stop(stop),
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR),
    .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2),
    .HEX3(HEX3), .HEX4(HEX4), .HEX5(HEX5),
    .solution_core1(solution_core1)
  );

  // Clock generation
  initial CLOCK_50 = 0;
  always #10 CLOCK_50 = ~CLOCK_50; // 50 MHz clock (20ns period)

  // Test sequence
  initial begin
    $display("Starting simulation...");
    stop = 0;
    SW = 10'b0;
    KEY = 4'b1111; // All keys inactive

    // Apply reset
    #50;
    KEY[3] = 0; // assert reset
    #50;
    KEY[3] = 1; // deassert reset

    // Wait enough time for FSMs to go through identity, perm, and third loop
    #50000;

    // Optionally force stop to test the DONE state and key capture
    stop = 1;
    #2000;

    $display("Simulation completed.");
    $stop;
  end

endmodule
