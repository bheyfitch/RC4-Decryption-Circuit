`timescale 1ns/1ps

module identity_fsm_tb;

    // Testbench signals
    logic clk;
    logic reset_n;
    logic start_id;
    logic [7:0] address;
    logic [7:0] data;
    logic wren;
    logic finish;

    // Instantiate the DUT
    identity_fsm dut (
        .clk(clk),
        .reset_n(reset_n),
        .start_id(start_id),
        .address(address),
        .data(data),
        .wren(wren),
        .finish(finish)
    );

    // Clock generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // Task to display write activity
    always_ff @(posedge clk) begin
        if (wren) begin
            $display("Time %0t: Writing %0d to address %0d", $time, data, address);
        end
    end

    initial begin
        // Init
        clk = 0;
        reset_n = 0;
        start_id = 0;

        // Hold reset
        #20;
        reset_n = 1;

        // Wait a bit
        #20;

        // Start the FSM
        start_id = 1;
        #10;
        start_id = 0;

        // Wait for FSM to finish
        wait (finish == 1);

        $display("FSM finished at time %0t", $time);
        #20;

        // End simulation
        $stop;
    end

endmodule
