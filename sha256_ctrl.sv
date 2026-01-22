`timescale 1ns / 1ps

module sha256_ctrl(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic last_block,
    output logic initial_hash,
    output logic load_message,
    output logic expand_message,
    output logic round_en,
    output logic update_hash,
    output logic finish,  
    output logic [6:0] curr_round_no
    );
    
   logic start_delay;
   logic start_pulse;
    
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)
                start_delay <= 1'b0;
                else 
                    start_delay <= start;
    end
    assign start_pulse = start & ~start_delay;
    
    //state encoding
    typedef enum logic[2:0]{
    IDLE = 3'd0,
    INITIAL = 3'd1,
    LOAD = 3'd2,
    EXPAND = 3'd3,
    ROUND = 3'd4,
    UPDATE = 3'd5,
    FINISH = 3'd6
    }state_t;
     
     state_t curr_state,next_state;
     
    logic [6:0] round_count;
    
    always_ff@(posedge clk or negedge rst_n)begin
    if(!rst_n)
         round_count <= 7'd0;
    else if(curr_state == ROUND)
        round_count <= round_count + 7'd1;
        else
         round_count <= 7'd0;
    end
    
    assign curr_round_no = round_count;
    
    //state register
    
    always_ff@(posedge clk or negedge rst_n)begin
    if(!rst_n)
        curr_state <= IDLE;
       else 
       curr_state <= next_state;
      end
       
       //next state and output
       
       always_comb begin
       initial_hash <= 1'b0;
       load_message <= 1'b0;
       expand_message <= 1'b0;
       round_en <=1'b0;
       update_hash <= 1'b0;
       finish <= 1'b0;
       next_state <= curr_state;
       
       
        case(curr_state)
        
        IDLE: begin
        if (start_pulse)begin
            initial_hash <= 1'b1;
            next_state <= INITIAL;
        end
        end
        
        INITIAL:begin
            next_state <= LOAD;
          end
          
         LOAD:begin
            load_message <= 1'b1;
            next_state <= EXPAND;
            end
            
         EXPAND:begin
            expand_message <= 1'b1;
            next_state <= ROUND;
            end
        
          ROUND:begin
            round_en <=1'b1;
            if(round_count == 7'd63)
                 next_state <= UPDATE;
            end
            
         UPDATE:begin
            update_hash <= 1'b1;
               next_state <= (last_block) ? FINISH : LOAD;
            end
               
          FINISH:begin
                finish <= 1'b1;
                next_state <= IDLE;
           end 
            
           default: next_state <= IDLE;

        endcase
       end 
    
endmodule
