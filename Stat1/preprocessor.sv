`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Created by : Nisarg and Shravani
// Create Date: 01/23/2026 07:44:02 PM
// Design Name: pre processor
// Module Name: preprocessor
// Project Name: SHA - 256
// Target Devices: -
// Tool Versions: -
// Description: 
// This code takes user input and converts it in processed blocks for SHA engine
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module preprocessor (
    input logic         rst,
    input logic         clk,
    input logic         data_valid,
    input logic [127:0] data_in,     
    input logic [3:0]   byte_valid,
    output logic        valid_o,
    output logic [31:0] M_o
);

//State Type Declaration
typedef enum {RECV,PAD,SEND} state_t;

logic [7:0] block_bytes [0:63];
logic [63:0] length;      //length of data
logic [5:0] write_ptr;
logic [3:0] send_count;
state_t state;       //state variable


always_ff @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        for(integer i = 0; i <64 ; i++)  block_bytes[i]<=8'b0;
        length <= 'b0;
        valid_o <= 'b0;
        M_o <= 'b0;
        write_ptr <= 'b0;
        send_count <= 'b0;
        state <= RECV;
    end
    else
    begin
        case(state)
           RECV : begin
                  valid_o <= 0;
                  M_o <= 0;
                    if(data_valid)
                            begin
                                if(byte_valid!=0) 
                                begin
                                    for(integer i = 0; i < 16; i++) 
                                    begin
                                        if(i < byte_valid) 
                                        begin
                                        block_bytes[write_ptr + i] <= data_in[127-(i*8)-:8];
                                        end
                                write_ptr <= write_ptr + byte_valid;
                                length <= length + (byte_valid*8);
                                end
                            end
                        else
                        begin
                                
                                state <= PAD;
                        end
                        end
                    
                    end
           PAD  :  begin : pad
                     block_bytes[write_ptr] <= 8'h80;  //Adds 1 to the end of the data
                     {block_bytes[56],block_bytes[57],block_bytes[58],block_bytes[59],
                      block_bytes[60],block_bytes[61],block_bytes[62],block_bytes[63]} <= length; //Adding length to 63:0 of block
                      state <= SEND; 
                   end
           SEND :  begin
                      valid_o <= 1'b1;   //Raise output valid
                      M_o <= {block_bytes[send_count*4],block_bytes[send_count*4 + 1],
                              block_bytes[send_count*4 + 2],block_bytes[send_count*4 + 3]};  //Send 32 bit data
                      if(send_count==15) begin
                        state <= RECV;
                        send_count <= 0;
                        
                        write_ptr <= 0;
                        length <= 0;
                      end
                      else
                      begin
                        send_count <= send_count + 1;
                      end
                   end
            default : state <= RECV;           
        endcase
    end
end


endmodule
