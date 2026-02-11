module ksa (
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

    logic clk, reset_n;
    logic [7:0] address, data, mem_out;
    logic wren, start;
    logic finish_id; // this means the identity fsm has finished its work


    logic [7:0] secret_key [2:0];
    //3 bytes , 8 bits each 
    //setting the upper 14 bits of the SW to 0 for this task 
    assign secret_key[0]  = 8'b0; 
    assign secret_key[1] = {6'b00000, SW[9:8]}; //setting the last 14 bits to zero for now
    assign secret_key[2] = {SW[7:0]};

    //datapath fsm parameters
    logic [5:0] state;
    logic [7:0] address_perm, data_perm;
    logic       wren_perm;
    logic       start_id, start_perm;
    logic       finish_perm;
    logic [7:0] ram_address, ram_data, ram_q;
   


//identity fsm parameters
    logic [7:0] address_id;
    logic [7:0] data_id;
    logic wren_id;
    logic [7:0] q_id;


    logic select_identity; //should i connect to identity matrix ?



    assign clk     = CLOCK_50;
    assign reset_n = KEY[3];

    // Instantiate RAM
    s_memory DUT (
        .address(ram_address),
        .clock(clk),
        .data(ram_data),
        .wren(ram_wren),
        .q(ram_q)
    );

    // Instantiate FSM
    identity_fsm identity_fsm_inst (
        .clk(clk),
        .reset_n(reset_n),
        .address(address_id),
        .data(data_id),
        .wren(wren_id),
        .start_id(start_id),
        .finish(finish_id)
    );


    perm_fsm u_perm_fsm (
    .clk(clk),
    .reset_n(reset_n),
    .start(start_perm),
    .secret_key(secret_key),
    .address(address_perm),
    .data(data_perm),
    .wren(wren_perm),
    .q(ram_q),
    .finish(finish_perm)
);


logic [7:0] message_data;
logic [7:0] message_address;

message_rom u_message_rom (
    .address(message_address),
    .clock(CLOCK_50),
    .q(message_data)
);

logic [7:0] out_address;
logic [7:0] out_data;
logic out_wren;
logic out_q;

decrypted_ram output_RAM (
	.address(out_address),
	.clock(CLOCK_50),
	.data(out_data),
	.wren(out_wren),
	.q(out_q));

 
//insert state parameters here
parameter START_IDENTITY = 6'b0_1_1_000; 
parameter RUN_IDENTITY  =  6'b0_1_1_001;
parameter START_PERM =     6'b1_0_0_010;
parameter RUN_PERM =       6'b0_0_0_011;
parameter DONE =           6'b0_0_0_100;


always_ff @(posedge CLOCK_50) begin 

    if (!reset_n) begin  // if reset then go to the first state 
        state <= RUN_IDENTITY;
        
    end 

    else begin 
        
        case(state) 

            START_IDENTITY : 

                state <= RUN_IDENTITY ;


            RUN_IDENTITY : //wait until finish_id is asserted meaning the identity fsm is done
                //start_id <=0 
                if (finish_id) state<= START_PERM;
                else  state <= RUN_IDENTITY;


            START_PERM : 
                //select_identity<= 0 ; // do not select the identity matrix anymore 
                //start_perm <= 1;
                state <= RUN_PERM;


            RUN_PERM :
                //start_perm<=0
                if (finish_perm) state <= DONE;
                else state<=RUN_PERM;


            DONE : 
                state <= DONE;
            
            default : state <= START_IDENTITY;
        endcase 
    end 

end 


assign  start_id = state[3]; //send start signal to the identity_fsm
assign  select_identity = state[4] ; // select identity_fsm of the perm_fsm
assign start_perm = state[5];  // send start signal to the perm_fsm


assign ram_address = (select_identity) ? address_id  : address_perm;
assign ram_data    = (select_identity) ? data_id     : data_perm;
assign ram_wren    = (select_identity) ? wren_id     : wren_perm;

// RAM output goes to both FSMs
assign q_id   = ram_q;
assign mem_q  = ram_q;

endmodule
