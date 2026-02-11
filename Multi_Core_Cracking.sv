module Multi_Core_Cracking (
    input  logic         CLOCK_50,
    input  logic [3:0]   KEY,
    input  logic [9:0]   SW,
    output logic [9:0]   LEDR,
    output logic [6:0]   HEX0,
    output logic [6:0]   HEX1,
    output logic [6:0]   HEX2,
    output logic [6:0]   HEX3,
    output logic [6:0]   HEX4,
    output logic [6:0]   HEX5
);

// Signals to track which core finished
logic solution_core1, solution_core2, solution_core3, solution_core4;
logic stop;

// Internal display/control lines for each core
logic [9:0] LEDR_core1, LEDR_core2, LEDR_core3, LEDR_core4;
logic [6:0] HEX0_core1, HEX1_core1, HEX2_core1, HEX3_core1, HEX4_core1, HEX5_core1;
logic [6:0] HEX0_core2, HEX1_core2, HEX2_core2, HEX3_core2, HEX4_core2, HEX5_core2;
logic [6:0] HEX0_core3, HEX1_core3, HEX2_core3, HEX3_core3, HEX4_core3, HEX5_core3;
logic [6:0] HEX0_core4, HEX1_core4, HEX2_core4, HEX3_core4, HEX4_core4, HEX5_core4;

// Instantiate Core 1
ksa CORE_1 (
    .stop(stop),
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR_core1),
    .HEX0(HEX0_core1),
    .HEX1(HEX1_core1),
    .HEX2(HEX2_core1),
    .HEX3(HEX3_core1),
    .HEX4(HEX4_core1),
    .HEX5(HEX5_core1),
    .solution_core1(solution_core1)
);

// Instantiate Core 2
ksa_core2 CORE_2 (
    .stop(stop),
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR_core2),
    .HEX0(HEX0_core2),
    .HEX1(HEX1_core2),
    .HEX2(HEX2_core2),
    .HEX3(HEX3_core2),
    .HEX4(HEX4_core2),
    .HEX5(HEX5_core2),
    .solution_core2(solution_core2)
);

// Instantiate Core 3
ksa_core3 CORE_3 (
    .stop(stop),
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR_core3),
    .HEX0(HEX0_core3),
    .HEX1(HEX1_core3),
    .HEX2(HEX2_core3),
    .HEX3(HEX3_core3),
    .HEX4(HEX4_core3),
    .HEX5(HEX5_core3),
    .solution_core3(solution_core3)
);

// Instantiate Core 4
ksa_core4 CORE_4 (
    .stop(stop),
    .CLOCK_50(CLOCK_50),
    .KEY(KEY),
    .SW(SW),
    .LEDR(LEDR_core4),
    .HEX0(HEX0_core4),
    .HEX1(HEX1_core4),
    .HEX2(HEX2_core4),
    .HEX3(HEX3_core4),
    .HEX4(HEX4_core4),
    .HEX5(HEX5_core4),
    .solution_core4(solution_core4)
);

// Display output from the first core that finishes
always_comb begin
    if (solution_core1) begin
        LEDR = LEDR_core1;
        HEX0 = HEX0_core1; HEX1 = HEX1_core1; HEX2 = HEX2_core1;
        HEX3 = HEX3_core1; HEX4 = HEX4_core1; HEX5 = HEX5_core1;
    end else if (solution_core2) begin
        LEDR = LEDR_core2;
        HEX0 = HEX0_core2; HEX1 = HEX1_core2; HEX2 = HEX2_core2;
        HEX3 = HEX3_core2; HEX4 = HEX4_core2; HEX5 = HEX5_core2;
    end else if (solution_core3) begin
        LEDR = LEDR_core3;
        HEX0 = HEX0_core3; HEX1 = HEX1_core3; HEX2 = HEX2_core3;
        HEX3 = HEX3_core3; HEX4 = HEX4_core3; HEX5 = HEX5_core3;
    end else if (solution_core4) begin
        LEDR = LEDR_core4;
        HEX0 = HEX0_core4; HEX1 = HEX1_core4; HEX2 = HEX2_core4;
        HEX3 = HEX3_core4; HEX4 = HEX4_core4; HEX5 = HEX5_core4;
    end else begin
        LEDR = 10'b0;
        HEX0 = HEX0_core1; HEX1 = HEX1_core1; HEX2 =HEX2_core1 ;
        HEX3 = HEX3_core1; HEX4 = HEX4_core1; HEX5 =HEX5_core1; // blank display
    end
end

// Stop all cores when any one finds a solution
always_comb begin
    stop = solution_core1 || solution_core2 || solution_core3 || solution_core4;
end

endmodule
