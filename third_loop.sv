module third_loop_fsm (
    input logic [7:0]  q_loop3,
    input logic [7:0] out_q,
    input logic [7:0] message_data,
    input logic reset_n, 
    input logic clk,
    input logic start_L3,
    output logic finish_L3,
    output logic out_wren,
    output logic [7:0] out_address,
    output logic [7:0] message_address,
    output logic wren_loop3,
    output logic [7:0] address_loop3,
    output logic [7:0] data_loop3,
    output logic [7:0] out_data,
    output logic run_again
    );

logic [11:0] state;
logic [7:0] index_i;
logic [7:0] index_j;
logic [7:0] index_k;
logic [7:0] f_index;
logic [7:0] encrypted_input;
logic [7:0] decrypted_output;

logic [7:0] s_i ; //S[i]
logic [7:0] s_j ; //S[j]
logic [7:0] f_; //f array
logic [7:0] dummy_var; //variables used in swapping





/* set of parameters talking to the message input (reading from it)
input logic [7:0] message_data,
output logic [7:0] message_address
*/
//-------------------------------------------------------------------------
/* set of parameters talking to the S array 
output logic [7:0] wren_loop3;
output logic [7:0] address_loop3;
output logic [7:0] data_loop3;
input logic [7:0]  q_loop3

*/
//-------------------------------------------------------------------------
/* set of parameters talking to the decrypted message RAM;
output logic out_wren,
output logic [7:0] out_address,
input logic [7:0] out_q
output logic [7:0] out_data;


*/
// make sure to change the access from perm fsm to third_loop_fsm after it is done 

parameter   INIT_LOOP3          = 12'b0_00_000_000000;
parameter  CHECK_K_INDEX        = 12'b0_00_000_000001;
parameter   READ_REQ_SI         = 12'b0_00_000_000010;
parameter   WAIT_FOR_SI         = 12'b0_00_000_000011;
parameter   GET_SI              = 12'b0_00_000_000100;
parameter   CALCULATE           = 12'b0_00_000_000101;
parameter   READ_SI_2           = 12'b0_00_000_000110;
parameter   WAIT_1_CLK          = 12'b0_00_000_000111;
parameter   GET_NEW_SI          = 12'b0_00_000_001000;
parameter   READ_SJ_2           = 12'b0_00_000_001001;
parameter   WAIT_FOR_SJ         = 12'b0_00_000_001010;
parameter   GET_SJ              = 12'b0_00_000_001011;
parameter   SWAP_PT1            = 12'b0_00_000_001100;
parameter   SWAP_PT2            = 12'b0_00_000_001101;
parameter   WRITE_NEW_SI        = 12'b0_00_000_001110;
parameter   WAIT_W_SI           = 12'b0_00_000_001111;
parameter   WRITE_NEW_SJ        = 12'b0_00_000_010000;
parameter   WAIT_W_SJ           = 12'b0_00_000_010001;
parameter   GET_F_INDEX         = 12'b0_00_000_010010;
parameter   READ_F_INDEX        = 12'b0_00_000_010011;
parameter   WAIT_FOR_F          = 12'b0_00_000_010100;
parameter   GET_F               = 12'b0_00_000_010101;
parameter   READ_FROM_ENC_INPUT = 12'b0_00_000_010110; //this one has to be checkd 
parameter   WAIT_FOR_K_RESULT   = 12'b0_00_000_010111;  
parameter   GET_ENCRYPTED_INPUT = 12'b0_00_000_011100;  //goes here
parameter   XOR                 = 12'b0_00_000_011101;
parameter   STORE_OUTPUT        = 12'b0_00_000_011110;
parameter   WAIT_FOR_WRITING    = 12'b0_00_000_011111;
parameter   INCREMENT_K         = 12'b0_00_000_100000;
parameter   DONE_LOOP3          = 12'b1_00_000_100001;
parameter INCREMENT_INDEX       = 12'b0_00_000_100010;
parameter ADDITIONAL_WAIT       = 12'b0_00_000_100011;
parameter  WAIT_BEFORE_SWAP     = 12'b0_00_000_100111;

//new states can be the source of bugs
parameter IS_IT_READABLE       =  12'b0_00_000_101111;
parameter CHECK                =  12'b0_00_000_101000;
parameter RUN_AGAIN            =  12'b0_10_000_101001; //set the run again flag to 1 

                                

//01101010
//01111111
//00010101
                                     


//insert state parameters here 


always_ff @(posedge clk ) begin 

if (!reset_n) state<= INIT_LOOP3;

else begin 

        case(state) 

            INIT_LOOP3 :  //reinitialize and get ready to go again.
                begin 
                    index_i <= 0 ;
                    index_j <= 0 ;
                    index_k <= 0 ;
                    if (start_L3) state<= CHECK_K_INDEX;
                    else state<=INIT_LOOP3;
                end 

            CHECK_K_INDEX : 
                    if (index_k == 8'd32) state<= DONE_LOOP3;
                    else  state<=INCREMENT_INDEX ;


            INCREMENT_INDEX : 
                begin 
                index_i <= index_i + 1;
                state<=ADDITIONAL_WAIT;
                end 


            ADDITIONAL_WAIT : 
            begin 
                //JUST MAKING SURE i is stable 
                state<=READ_REQ_SI;

            end 

            READ_REQ_SI : 

                begin 
                    wren_loop3<=0;
                    address_loop3<= index_i;
                    state<= WAIT_FOR_SI;
                end 


            WAIT_FOR_SI : 
                    state <= GET_SI;
                
            GET_SI : 
                begin 
                s_i <=  q_loop3; // get the value of S[i]
                state <=CALCULATE;

                end 
            
            CALCULATE : 
                begin 
                    index_j <= index_j + s_i;  // j = j + S[i]
                    state<= WAIT_1_CLK;
                end 

            /*
            READ_SI_2 :  //use the updated index to read again 
                begin 
                address_loop3 <= index_i;
                wren_loop3<=0;
                state<=WAIT_1_CLK;
                end 
            */

            WAIT_1_CLK : 
                state <= READ_SJ_2; //just wait one clock cycle until j becomes stable


            /*
            GET_NEW_SI : 
                begin 
                    s_i <= q_loop3;
                    state<= READ_SJ_2;
                end 
                */

            READ_SJ_2 : 
            begin 

                dummy_var <= s_i ; //preserve the value of S[i]
                wren_loop3<=0;
                address_loop3 <= index_j;
                state <= WAIT_FOR_SJ;

            end 

              
            WAIT_FOR_SJ : 
                state<= GET_SJ;

            GET_SJ : 
                begin 
                    s_j <= q_loop3; //store the result in S[j]
                    state <= WAIT_BEFORE_SWAP;
                end 

            WAIT_BEFORE_SWAP :  //wait for S[j] to become available 
                 state<= SWAP_PT1;

            SWAP_PT1 : 

                begin 
                    s_i <= s_j ; 
                    state <= SWAP_PT2;
                end 

            SWAP_PT2 : 

                begin 

                    s_j <= dummy_var ; //S[j] = preserved value of S[i]
                    state<=WRITE_NEW_SI;
                end 

            WRITE_NEW_SI :

            begin 
                address_loop3 <= index_i; //write the new S[i] values into memory 
                data_loop3<=s_i;
                wren_loop3 <= 1; 
                state<= WAIT_W_SI;

            end 


            WAIT_W_SI : //wait one clock cycle and stop writing 
            begin 
                wren_loop3<=0;
                state<= WRITE_NEW_SJ;
            end 

            WRITE_NEW_SJ :  //write the new S[i] value into memory
            begin 
                address_loop3 <= index_j;
                data_loop3 <= s_j;
                wren_loop3 <= 1; 
                state<= WAIT_W_SJ;
            end 

            WAIT_W_SJ : //wait for one clk cycle ad stop writing 
            begin 
                wren_loop3<= 0 ;
                state<= GET_F_INDEX;
            end 

            GET_F_INDEX : 
            begin 
                f_index <= ((s_i + s_j) %256 ) ;  //Calculate the index of the array f
                state<= READ_F_INDEX;
            end 

            READ_F_INDEX : 
            begin 

                address_loop3 <= f_index;
                wren_loop3<=0;
                state<= WAIT_FOR_F;

            end

            WAIT_FOR_F :

                state<= GET_F;
            
            GET_F : 
            begin
                f_ <= q_loop3;
                state<= READ_FROM_ENC_INPUT;

            end 

            READ_FROM_ENC_INPUT :  //
            begin 
             message_address <= index_k ; //instantiate request to read encrypted_input[k];
             state<= WAIT_FOR_K_RESULT;
            end 

            WAIT_FOR_K_RESULT : //wait for one clk cycle
             state <= GET_ENCRYPTED_INPUT;


            GET_ENCRYPTED_INPUT : 
                begin 

                    encrypted_input <= message_data ;   //encrypted_input[k];
                    state <= XOR;

                end  

            XOR : 
                begin 
                decrypted_output <=  (encrypted_input ^ f_) ; //decrypted_output[k] = f xor encrypted_input[k] 
                state<= IS_IT_READABLE;

                end 

            IS_IT_READABLE :        //new state
            //treat this as a wait staet to make the dectpyed_output stable
            state<= CHECK;


            CHECK  : 
            if ((decrypted_output == 32) || (decrypted_output >= 97 && decrypted_output <= 122)) state<= STORE_OUTPUT;
            else state<=RUN_AGAIN;

            
            STORE_OUTPUT : 
            begin 
                out_address <= index_k;
                out_data<= decrypted_output;
                out_wren<= 1;
                state<= WAIT_FOR_WRITING;

            end 

            WAIT_FOR_WRITING :   //wait for the writing operation 
            begin 
                    out_wren<=0;
                    state<= INCREMENT_K;

            end 

            INCREMENT_K : 
            begin 
            out_wren <= 0;
            index_k <= index_k + 1;
            state <= CHECK_K_INDEX;

            end 


            DONE_LOOP3: 
            begin     //say we done and stay in DONE
                
               
                state <= INIT_LOOP3; //GO THERE BUT DO NOT EXECUTE AND WAIT FOR START_L3


            end 

            RUN_AGAIN : 
            //run again is 1 
            state<= INIT_LOOP3; //go to state IDLE and wait for the start signal 


            default : state<= INIT_LOOP3;

        endcase 
end 


end

assign finish_L3 = state[11];
assign run_again = state[10];

endmodule 