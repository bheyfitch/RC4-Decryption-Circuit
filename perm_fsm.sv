module perm_fsm (
    input  logic clk,
    input  logic [7:0] secret_key [2:0], // i need to figure out how this will work out with the top module 
    input  logic reset_n,
    input  logic start,
    output logic [7:0] address,
    output logic [7:0] data,
    output logic       wren,
    
    
    output logic finish,
    input  logic [7:0] q
);

                                    
logic [11:0] state;

parameter IDLE                 = 12'b0_00_000_000000;
parameter CHECK_COUNTER        = 12'b0_00_000_000001;
parameter READ_INDEX_I         = 12'b0_00_000_000010;
parameter WAIT_FOR_I_READ      = 12'b0_00_000_000011;
parameter GET_INDEX_I          = 12'b0_00_000_000100;
parameter ACCUMULATE           = 12'b0_00_000_000101;
parameter READ_INDEX_J         = 12'b0_00_000_000110;
parameter WAIT_FOR_J_READ      = 12'b0_00_000_000111;
parameter GET_INDEX_J          = 12'b0_00_000_001000;
parameter CALCULATE_TEMP_PART1 = 12'b0_00_000_001001;
parameter CALCULATE_TEMP_PART2 = 12'b0_00_000_001010;
parameter CALCULATE_TEMP_PART3 = 12'b0_00_000_001011;
parameter WRITE_NEW_S_I_VALUE  = 12'b0_00_000_001100;
parameter WAIT_TO_WRITE_S_I    = 12'b0_00_000_001101;
parameter WRITE_NEW_S_J_VALUE  = 12'b0_00_000_001110;
parameter WAIT_TO_WRITE_S_J    = 12'b0_00_000_001111;
parameter INCREMENT_I          = 12'b0_00_000_010000;
parameter DONE                 = 12'b1_00_000_010001;
parameter NEX_STG              = 12'b0_10_000_010001;







// Internal registers
logic [7:0] j_ = 8'b0; // j in S[j]
logic [7:0] i_ = 8'b0; // i in S[i]
logic [7:0] temp;
logic [7:0] s_i_val;
logic [7:0] s_j_val;

// FSM
always_ff @(posedge clk) begin
    if (!reset_n) begin
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                i_<= 8'b0; //reinitialize and get ready for another loop but do not execute until the start signal comes
                j_ <= 8'b0;
                if (start) state <= CHECK_COUNTER; //we dont want to write here wren =0 
                else       state <= IDLE;
            end

            CHECK_COUNTER: begin
                //if (i_ >= 8'd255) state <= DONE;  //wren =0 
                           state <= READ_INDEX_I;
            end

            READ_INDEX_I: begin
                address <= i_; //tell memory that we want to read address S[i]
                wren    <= 0; // encode this into the bits
                state   <= WAIT_FOR_I_READ;
            end

            WAIT_FOR_I_READ: begin
                state <= GET_INDEX_I;
            end

            GET_INDEX_I: begin
                s_i_val <= q;
                state   <= ACCUMULATE;
            end

            ACCUMULATE: begin
                j_    <= j_ + s_i_val + secret_key[i_ % 3]; //we have now successfully calculated j 
                state <= READ_INDEX_J;
            end

            READ_INDEX_J: begin
                address <= j_;
                wren    <= 0; //this should be encoded into the bits 
                state   <= WAIT_FOR_J_READ;
            end

            WAIT_FOR_J_READ: begin
                state <= GET_INDEX_J;
            end

            GET_INDEX_J: begin
                s_j_val <= q; //s[j]
                state   <= CALCULATE_TEMP_PART1;
            end

            CALCULATE_TEMP_PART1: begin
                temp  <= s_j_val; // save the S[j] value
                state <= CALCULATE_TEMP_PART2;
            end

            CALCULATE_TEMP_PART2: begin
                s_j_val <= s_i_val;
                state   <= CALCULATE_TEMP_PART3;
            end

            CALCULATE_TEMP_PART3: begin
                s_i_val <= temp; 
                state   <= WRITE_NEW_S_I_VALUE;
            end

            WRITE_NEW_S_I_VALUE: begin //we have now swapped the values now it's time to write them back into memory 
                address <= i_;         //wenable has to be 1 in this state ***********************
                data    <= s_i_val;
                wren    <= 1;
                state   <= WAIT_TO_WRITE_S_I;
            end

            WAIT_TO_WRITE_S_I: begin
                wren  <= 0;
                state <= WRITE_NEW_S_J_VALUE;
            end

            WRITE_NEW_S_J_VALUE: begin
                address <= j_;
                data    <= s_j_val;
                wren    <= 1;
                state   <= WAIT_TO_WRITE_S_J;
            end

            WAIT_TO_WRITE_S_J: begin
                wren  <= 0;
                state <= INCREMENT_I;
            end

            INCREMENT_I: begin
                i_    <= i_ + 1;
                state <= NEX_STG;
            end



            NEX_STG : 
            begin 

                    if (i_ == 0 ) state<= DONE;
                    else state<= CHECK_COUNTER;
            end



            DONE: begin
                state <= IDLE; //supposed to go IDLE and wait for start
                //finish <= 1;
            end

            default : state<= IDLE;
        endcase
    end
end


assign finish = state[11];


endmodule
