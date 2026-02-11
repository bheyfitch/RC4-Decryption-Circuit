module ksa_core3 (
    input  logic stop,
    input  logic         CLOCK_50,
    input  logic [3:0]   KEY,
    input  logic [9:0]   SW,
    output logic [9:0]   LEDR,
    output logic [6:0]   HEX0,
    output logic [6:0]   HEX1,
    output logic [6:0]   HEX2,
    output logic [6:0]   HEX3,
    output logic [6:0]   HEX4,
    output logic [6:0]   HEX5,
    output logic solution_core3
);

    logic clk, reset_n;
    logic [7:0] address, data, mem_out;
    logic wren, start;
    logic finish_id; // this means the identity fsm has finished its work


    logic [7:0] secret_key [2:0];



   /*
    //3 bytes , 8 bits each 
    //setting the upper 14 bits of the SW to 0 for this task 
    assign secret_key[0]  = 8'b0; 
    assign secret_key[1] = {6'b00000, SW[9:8]}; //setting the last 14 bits to zero for now
    assign secret_key[2] = {SW[7:0]};
*/


logic [23:0] current_key = 24'b0010_0000_0000_0000_0000_0000; //use this variable to increment the keys

logic [23:0] found_key =0;

assign secret_key[0] = current_key[23:16];
assign secret_key[1] = current_key[15:8];
assign secret_key[2] = current_key[7:0];






    //datapath fsm parameters

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


    logic [1:0] select_identity; //should i connect to identity matrix ?



    assign clk     = CLOCK_50;
    assign reset_n = KEY[3];

    // Instantiate RAM
    s_memory3 DUT (
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

/*message_rom u_message_rom (
    .address(message_address),
    .clock(CLOCK_50),
    .q(message_data)
);
*/

rom_input3 ROM_INSTANCE (
	.address(message_address),
	.clock(CLOCK_50),
	.q(message_data));


logic [7:0] out_address;
logic [7:0] out_data;
logic out_wren;
logic [7:0] out_q;

decrypted_ram3 output_RAM (
	.address(out_address),
	.clock(CLOCK_50),
	.data(out_data),
	.wren(out_wren),
	.q(out_q));


logic [7:0] data_loop3;
logic [7:0] address_loop3;
logic wren_loop3;
logic [7:0] q_loop3;
logic start_L3;
logic finish_L3;
logic run_again;

third_loop_fsm third_loop_instance (
    .q_loop3(ram_q),
    .out_q(out_q),
    .message_data(message_data),
    .reset_n(reset_n), 
    .clk(CLOCK_50),
    .start_L3(start_L3),
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


 
//insert state parameters here
parameter START_IDENTITY =       8'b00_0_0_1_000; 
parameter RUN_IDENTITY  =        8'b00_0_0_0_001;
parameter START_PERM =           8'b00_1_0_0_010;
parameter RUN_PERM =             8'b00_0_0_0_011;
parameter START_FSM3 =           8'b00_0_1_0_100;
parameter RUN_FSM3 =             8'b00_0_0_0_101;
parameter DONE =                 8'b01_0_0_0_111;
parameter NEED_TO_RUN_AGAIN    = 8'b00_0_0_0_110;
parameter INCREMENT_SECRET_KEY = 8'b10_0_0_0_111;
parameter FIRST_CORE_FOUND    =  8'b00_0_0_0_000;



logic [7:0] state = START_IDENTITY; //INITIAL STATE

always_ff @(posedge CLOCK_50) begin 

    if (!reset_n) begin  // if reset then go to the first state 
        state <= RUN_IDENTITY;
        
    end 

    else begin 
        
        case(state) 

            START_IDENTITY : 
					begin 
                state <= RUN_IDENTITY ;
                select_identity <= 2'b01;
					 end


            RUN_IDENTITY : //wait until finish_id is asserted meaning the identity fsm is done
                //start_id <=0 
					 begin 
                select_identity <= 2'b01;
                if (finish_id) state<= START_PERM;
                else  state <= RUN_IDENTITY;
					 end 


            START_PERM : 
                //select_identity<= 0 ; // do not select the identity matrix anymore 
                //start_perm <= 1;
					 begin 
                select_identity <= 2'b10;
                state <= RUN_PERM;
					 end 


            RUN_PERM :
                //start_perm<=0 
					 begin 
                select_identity <= 2'b10;
                if (finish_perm) state <= START_FSM3;
                else state<=RUN_PERM;
					 end 


            START_FSM3 : 
            begin 
                select_identity <=2'b11;
                //start_L3<= 1;
                state<= RUN_FSM3;
            end 

            RUN_FSM3 : 
            begin 
                select_identity <= 2'b11;
                if (finish_L3) state<= DONE;
                else if (run_again) state <= NEED_TO_RUN_AGAIN;
                else state<= RUN_FSM3;

            end 

            DONE : 
				begin
                //solution_core2 <= 1;
                LEDR[6:4] <= 3'b111;   //core 2 has found a solution 
                found_key <= current_key;
                state<= DONE;
					 end 
                

            NEED_TO_RUN_AGAIN : 
				begin
            //LEDR[9]<=1;
            state <= INCREMENT_SECRET_KEY;
				end 


            INCREMENT_SECRET_KEY : 
            begin
            current_key<= current_key + 1 ; 
            if (stop) state <= FIRST_CORE_FOUND; //if one core has found the solution stop processing 
            else  state<=START_IDENTITY;
            end 




            FIRST_CORE_FOUND : 
            state<=FIRST_CORE_FOUND;
            
            default : state <= START_IDENTITY;
        endcase 
    end 

end 


assign start_id = state[3]; //send start signal to the identity_fsm
assign start_L3  = state[4];
assign start_perm = state[5];  // send start signal to the perm_fsm
assign solution_core3 = state[6];



always_comb begin //mux logic to tace care of multiple fsms trying to acess the s_memory

    case(select_identity) 
     
     2'b01 : begin 
        ram_address =  address_id;
        ram_data = data_id;
        ram_wren = wren_id;
     end 

     2'b10 : begin 
        ram_address =  address_perm;
        ram_data = data_perm;
        ram_wren = wren_perm;
     end 

	  
     2'b11 : begin 
        ram_address =  address_loop3;
        ram_data = data_loop3;
        ram_wren = wren_loop3;
     end 
	  

      default : begin 
        ram_address =  address_id;
        ram_data = data_id;
        ram_wren = wren_id;
      end 

    endcase

end

logic [3:0] digit0, digit1, digit2, digit3, digit4, digit5;

always_comb begin
    digit0 = found_key[3:0];
    digit1 = found_key[7:4];
    digit2 = found_key[11:8];
    digit3 = found_key[15:12];
    digit4 = found_key[19:16];
    digit5 = found_key[23:20];
end

// Use combinational display decoders
SevenSegmentDisplayDecoder DISP0(.ssOut(HEX0), .nIn(digit0));
SevenSegmentDisplayDecoder DISP1(.ssOut(HEX1), .nIn(digit1));
SevenSegmentDisplayDecoder DISP2(.ssOut(HEX2), .nIn(digit2));
SevenSegmentDisplayDecoder DISP3(.ssOut(HEX3), .nIn(digit3));
SevenSegmentDisplayDecoder DISP4(.ssOut(HEX4), .nIn(digit4));
SevenSegmentDisplayDecoder DISP5(.ssOut(HEX5), .nIn(digit5));



endmodule
