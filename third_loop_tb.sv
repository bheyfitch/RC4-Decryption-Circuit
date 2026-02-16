`timescale 1ns/1ps

module third_loop_fsm_tb;

  // DUT interface signals
  logic clk, reset_n, start_L3;
  logic [7:0] q_loop3, out_q, message_data;
  logic finish_L3, out_wren;
  logic [7:0] out_address, message_address;
  logic wren_loop3;
  logic [7:0] address_loop3, data_loop3, out_data;
  logic run_again;

  // Instantiate the DUT
  third_loop_fsm dut (
    .clk(clk),
    .reset_n(reset_n),
    .start_L3(start_L3),
    .q_loop3(q_loop3),
    .out_q(out_q),
    .message_data(message_data),
    .finish_L3(finish_L3),
    .out_wren(out_wren),
    .out_address(out_address),
    .message_address(message_address),
    .wren_loop3(wren_loop3),
    .address_loop3(address_loop3),
    .data_loop3(data_loop3),
    .out_data(out_data),
    .run_again(run_again)
  );

  // Internal memory to simulate RAMs
  logic [7:0] s_mem [0:255];     // S array
  logic [7:0] msg_mem [0:255];   // Encrypted input
  logic [7:0] out_mem [0:255];   // Decrypted output

  // Clock generation
  always #5 clk = ~clk;

  // Simulated RAM behavior
  always @(posedge clk) begin
    q_loop3 <= s_mem[address_loop3];
    message_data <= msg_mem[message_address];

    if (wren_loop3)
      s_mem[address_loop3] = data_loop3;

    if (out_wren) begin
      out_mem[out_address] = out_data;
      $display("Time: %0t ns | Output written at [%0d] = %0d", $time, out_address, out_data);
    end
  end

  // Monitor state changes in the DUT
  logic [11:0] prev_state;
  always @(posedge clk) begin
    if (prev_state !== dut.state) begin
      $display("Time: %0t ns | FSM state changed to: %b", $time, dut.state);
      prev_state <= dut.state;
    end
  end

  // Initial stimulus
  initial begin
    // Initialize clock and signals
    clk = 0;
    reset_n = 0;
    start_L3 = 0;
    prev_state = 12'bx;

    // Initialize memory
    for (int i = 0; i < 256; i++) begin
      s_mem[i] = i;
      msg_mem[i] = 8'h41 + i;  // Fill with ASCII A, B, C, ...
      out_mem[i] = 0;
    end

    // Hold reset
    #20;
    reset_n = 1;

    // Start the FSM
    #10;
    start_L3 = 1;
    #10;
    start_L3 = 0;

    // Run long enough to complete
    #5000;

    $display("Test complete.");
    $stop;
  end

endmodule
