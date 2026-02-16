`timescale 1ns/1ps

module tb_perm_fsm;

  // Inputs to DUT
  logic clk = 0;
  logic reset_n = 0;
  logic start = 0;
  logic [7:0] secret_key [2:0];
  logic [7:0] q;

  // Outputs from DUT
  logic [7:0] address;
  logic [7:0] data;
  logic       wren;
  logic       finish;

  // Instantiate the DUT
  perm_fsm dut (
    .clk(clk),
    .reset_n(reset_n),
    .start(start),
    .secret_key(secret_key),
    .address(address),
    .data(data),
    .wren(wren),
    .finish(finish),
    .q(q)
  );

  // Simulated S memory (RAM)
  logic [7:0] s_memory [0:255];

  // Generate clock: 10ns period
  always #5 clk = ~clk;

  // Drive q based on address when not writing
  always_comb begin
    if (!wren)
      q = s_memory[address];
    else
      q = 8'bz;
  end

  // Write to simulated memory when wren is high
  always @(posedge clk) begin
    if (wren) begin
      s_memory[address] = data;
      $display("[WRITE] @ %0d <= %0d", address, data);
    end
  end

  // Test sequence
  initial begin
    // Initialize memory and secret key
    for (int i = 0; i < 256; i++) begin
      s_memory[i] = i;
    end
    secret_key[0] = 8'd1;
    secret_key[1] = 8'd2;
    secret_key[2] = 8'd3;

    // Reset pulse
    #10 reset_n = 0;
    #10 reset_n = 1;

    // Pulse start
    #10 start = 1;
    #10 start = 0;

    // Wait for finish
    wait (finish == 1);

    #20;
    $display("Permutation FSM finished execution.");

    $stop;
  end

  // Optional: monitor signal activity
  initial begin
    $monitor("T=%0t | addr=%0d | data=%0d | wren=%b | q=%0d | finish=%b",
              $time, address, data, wren, q, finish);
  end

endmodule
