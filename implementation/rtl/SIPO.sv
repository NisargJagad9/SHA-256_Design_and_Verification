module sipo (
    input  logic         clk,
    input  logic         rst_n,         // active-low reset

    // UART-like byte input
    input  logic         rx_dv,         // 1-cycle strobe: rx_byte is valid
    input  logic [7:0]   rx_byte,

    // To preproc - burst style like your testbench
    output logic         msg_valid,     // high for 1 cycle when message is ready
    output logic [5:0]   byte_valid,    // 0..55  (number of meaningful bytes)
    output logic [439:0] msg_word       // MSB byte first (big-endian byte order)
);

    // ────────────────────────────────────────────────
    // Storage
    // ────────────────────────────────────────────────
    logic [439:0] buffer;
    logic [5:0]   cnt;                  // how many bytes we have so far (0..55)

    typedef enum logic [1:0] {
        IDLE    = 2'd0,
        COLLECT = 2'd1,
        OUTPUT  = 2'd2
    } state_t;

    state_t state, next;

    // ────────────────────────────────────────────────
    // Registers
    // ────────────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            buffer    <= '0;
            cnt       <= '0;
            msg_valid <= '0;
            byte_valid<= '0;
            msg_word  <= '0;
        end
        else begin
            state     <= next;
            msg_valid <= 1'b0;          // default - single cycle

            case (state)
                IDLE: begin
                    buffer <= '0;
                    cnt    <= '0;

                    if (rx_dv && rx_byte != 8'h0D) begin
                        buffer[439:432] <= rx_byte;
                        cnt             <= 6'd1;
                    end
                end

                COLLECT: begin
                    if (rx_dv) begin
                        if (rx_byte == 8'h0D || cnt == 55) begin
                            // End condition → output next cycle
                            next       <= OUTPUT;
                            byte_valid <= cnt;          // freeze the count
                            msg_word   <= buffer;
                            msg_valid  <= 1'b1;         // pulse right here (or move to OUTPUT)
                        end
                        else begin
                            // Shift in new byte from the left (MSB first)
                            buffer <= {buffer[431:0], rx_byte};
                            cnt    <= cnt + 1'd1;
                        end
                    end
                end

                OUTPUT: begin
                    // In your testbench style: present for 1 cycle, then idle
                    msg_valid <= 1'b1;
                    // already set byte_valid & msg_word in previous state
                    next      <= IDLE;
                end
            endcase
        end
    end

    // State transition
    always_comb begin
        next = state;
        case (state)
            IDLE:    if (cnt == 6'd1)           next = COLLECT;
            COLLECT: if (msg_valid)             next = OUTPUT;   // or handle inside seq
            OUTPUT:                             next = IDLE;
            default:                            next = IDLE;
        endcase
    end

endmodule