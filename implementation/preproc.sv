//preproc
`timescale 1ns / 1ps

// ========================================================
// SHA-256 Preprocessor + Padder with CR (0x0D) terminator
// ========================================================
module preproc (
    input  logic       clk,
    input  logic       rst_n,
        
    input  logic       rx_valid,
    input  logic [7:0] rx_data,
    
    output logic       valid_o,     // 1 when new 32-bit word ready
    output logic [31:0] M_o         // Big-endian word
);

typedef enum logic [2:0] {
    IDLE, RECEIVE, PAD1, SEND
} state_t;

state_t state;

logic [7:0] block [0:63];
logic [63:0] bit_length;
logic [6:0]  byte_cnt;
logic [3:0]  word_cnt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state      <= IDLE;
        byte_cnt   <= '0;
        bit_length <= '0;
        word_cnt   <= '0;
        valid_o    <= 1'b0;
        M_o        <= '0;
        for (int i=0; i<64; i++) block[i] <= '0;
    end else begin

        valid_o <= 1'b0;

        case (state)
            IDLE: begin
                if (rx_valid && rx_data != 8'h0D) begin
                    block[0]   <= rx_data;
                    byte_cnt   <= 7'd1;
                    bit_length <= 64'd8;
                    state      <= RECEIVE;
                end
            end

            RECEIVE: begin
                if (rx_valid) begin
                    if (rx_data == 8'h0d) begin          // Message end
                        state <= PAD1;
                    end else if (byte_cnt < 64) begin
                        block[byte_cnt] <= rx_data;
                        byte_cnt        <= byte_cnt + 1'd1;
                        bit_length      <= bit_length + 64'd8;
                    end
                end
            end

            // ================== PADDING ==================
            PAD1: begin
                block[byte_cnt] <= 8'h80;     // Append 1-bit

                // Fill zeros up to length field (byte 56)
//                for (int i = byte_cnt+1; i < 56; i++)
//                    block[i] <= 8'h00;

                // 64-bit length (big-endian)
                block[56] <= bit_length[63:56];
                block[57] <= bit_length[55:48];
                block[58] <= bit_length[47:40];
                block[59] <= bit_length[39:32];
                block[60] <= bit_length[31:24];
                block[61] <= bit_length[23:16];
                block[62] <= bit_length[15:8];
                block[63] <= bit_length[7:0];

                state     <= SEND;
                word_cnt  <= '0;
            end

            SEND: begin
                valid_o <= 1'b1;
                M_o <= {block[word_cnt*4],   block[word_cnt*4+1],
                        block[word_cnt*4+2], block[word_cnt*4+3]};

                if (word_cnt == 15) begin
                    state <= IDLE;
                    byte_cnt   <= '0;
                    bit_length <= '0;
                end else begin
                    word_cnt <= word_cnt + 1'd1;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule