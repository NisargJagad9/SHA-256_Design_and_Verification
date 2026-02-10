//piso
module piso (
    input  logic       clk,
    input  logic       rst_n,

    // From your hash module
    input  logic       hash_done,           // 1-cycle pulse when hash is ready
    input  logic [255:0] fin_hash,          // 256-bit hash to transmit

    // To your UART TX module
    output logic       tx_dv,               // pulse to start sending one byte
    output logic [7:0] tx_byte,             // byte to send
    input  logic       tx_done,             // from UART TX - high for 1 cycle when byte sent
    input  logic       tx_active            // optional - if you want to wait until fully idle
);

    // ────────────────────────────────────────────────
    // Registers
    // ────────────────────────────────────────────────
    reg [255:0]  hash_reg;                  // captured hash
    reg [4:0]    byte_idx;                  // 0..31  (5 bits enough for 32 bytes)
    reg          busy;

    typedef enum logic [1:0] {
        IDLE       = 2'd0,
        LOAD_NEXT  = 2'd1,
        WAIT_TX    = 2'd2
    } state_t;

    state_t state, next_state;

    // ────────────────────────────────────────────────
    // Main FSM + control
    // ────────────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            hash_reg  <= 256'b0;
            byte_idx  <= 5'd0;
            busy      <= 1'b0;
            tx_dv     <= 1'b0;
            tx_byte   <= 8'h00;
        end
        else begin
            tx_dv <= 1'b0;   // default: single-cycle pulse

            case (state)
                IDLE: begin
                    if (hash_done) begin
                        hash_reg  <= fin_hash;
                        byte_idx  <= 5'd0;
                        busy      <= 1'b1;
                        state     <= LOAD_NEXT;
                    end
                end

                LOAD_NEXT: begin
                    // Select byte - MSB byte first
                    tx_byte <= hash_reg[(31 - byte_idx)*8 +: 8];
                    // tx_byte <= hash_reg[255byte_idx - byte_idx*8 -: 8];  // alternative syntax
                    tx_dv   <= 1'b1;
                    state   <= WAIT_TX;
                end

                WAIT_TX: begin
                    if (tx_done) begin
                        if (byte_idx == 5'd31) begin
                            // Last byte sent → done
                            busy  <= 1'b0;
                            state <= IDLE;
                        end
                        else begin
                            byte_idx <= byte_idx + 1'b1;
                            state    <= LOAD_NEXT;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
