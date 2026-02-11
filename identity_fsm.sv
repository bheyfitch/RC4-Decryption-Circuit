module identity_fsm (
    input  logic        clk,
    input  logic        reset_n,
    input logic start_id,
    output logic [7:0]  address,
    output logic [7:0]  data,
    output logic        wren,
    output logic        finish
);

    logic [5:0] state;
    logic [7:0] counter_i = 0;

    parameter INIT_S_MEM            = 6'b0_0_0_000;
    parameter IS_COUNTER_256        = 6'b0_0_0_001;
    parameter IDENTITY_PERM         = 6'b0_1_0_010;
    parameter BREAK                 = 6'b1_0_0_011;
    parameter WRTE_AND_BREAK        = 6'b0_1_0_111;
    parameter WRTE_AND_BREAK_AGAIN  = 6'b0_1_1_111;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state     <= INIT_S_MEM;
            counter_i <= 0;
        end else begin
            case(state)
                INIT_S_MEM: begin
                    address <= 0;  //it should get here but should not run again and should wait for the start signal 
                    counter_i<=0;
                    if (start_id) state   <= IS_COUNTER_256; //wait for the start signal from the controller fsm otherwise stay here
                    else state <= INIT_S_MEM;
                end

                IS_COUNTER_256: begin
                    if (counter_i == 8'd255)
                        state <= WRTE_AND_BREAK;
                    else
                        state <= IDENTITY_PERM;
                end

                IDENTITY_PERM: begin
                    address    <= counter_i;
                    data       <= counter_i;
                    counter_i  <= counter_i + 1;
                    state <= IS_COUNTER_256;
                end


                WRTE_AND_BREAK : 
						begin 
                    address    <= counter_i;
                    data       <= counter_i;
                    counter_i  <= counter_i + 1;
                    
                    state<= WRTE_AND_BREAK_AGAIN;
						  end 

                WRTE_AND_BREAK_AGAIN : 
                    begin 
                    address    <= counter_i;
                    data       <= counter_i;
                    //counter_i  <= counter_i + 1;
                    state <= IS_COUNTER_256;
                    state<= BREAK;
                    end 



                BREAK: begin
                    state <= INIT_S_MEM; // stay here


					//finish<=1;
                    // we need the change the acess to the s_memory here !
                end

                default : state <= INIT_S_MEM;
            endcase

        end
    end

    assign wren   = state[4];
    assign finish = state[5];


endmodule
