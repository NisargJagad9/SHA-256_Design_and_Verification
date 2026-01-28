// ============================================================================
// SHA-256 Controller FSM
//  - Controls message scheduler and hash core
//  - 16-cycle message load
//  - 64-cycle hash round execution
//  - 1-cycle finalization
//  - Clean datapath/control separation
// ============================================================================

module sha256_ctrl_fsm (
    input  logic        clk,
    input  logic        rst_n,

    // Control inputs
    input  logic        start_i,
    input  logic        msg_word_valid_i,

    // Control outputs
    output logic        msg_ld_o,
    output logic        hash_ld_o,
    output logic        hash_en_o,
    output logic        final_o,
    output logic        done_o,

    // Round index (for K ROM)
    output logic [5:0]  round_o
);

    // ------------------------------------------------------------------------
    // FSM state encoding
    // ------------------------------------------------------------------------
    typedef enum logic [2:0] {
        ST_IDLE  = 3'd0,
        ST_LOAD  = 3'd1,
        ST_ROUND = 3'd2,
        ST_FINAL = 3'd3,
        ST_DONE  = 3'd4
    } state_t;

    state_t state, next_state;

    // ------------------------------------------------------------------------
    // Counters
    // ------------------------------------------------------------------------
    logic [4:0] load_cnt;   // 0..15
    logic [5:0] round_cnt;  // 0..63

    assign round_o = round_cnt;

    // ------------------------------------------------------------------------
    // FSM sequential logic
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            load_cnt  <= 5'd0;
            round_cnt <= 6'd0;
        end
        else begin
            state <= next_state;

            // Load counter
            if (state == ST_LOAD && msg_word_valid_i)
                load_cnt <= load_cnt + 1'b1;
            else if (state != ST_LOAD)
                load_cnt <= 5'd0;

            // Round counter
            if (state == ST_ROUND)
                round_cnt <= round_cnt + 1'b1;
            else
                round_cnt <= 6'd0;
        end
    end

    // ------------------------------------------------------------------------
    // FSM combinational logic
    // ------------------------------------------------------------------------
    always_comb begin
        // Defaults
        next_state = state;

        msg_ld_o  = 1'b0;
        hash_ld_o = 1'b0;
        hash_en_o = 1'b0;
        final_o   = 1'b0;
        done_o    = 1'b0;

        case (state)

            // --------------------------------------------------------------
            ST_IDLE: begin
                if (start_i)
                    next_state = ST_LOAD;
            end

            // --------------------------------------------------------------
            ST_LOAD: begin
                msg_ld_o = msg_word_valid_i;

                // Load IV on first word
                if (load_cnt == 5'd0 && msg_word_valid_i)
                    hash_ld_o = 1'b1;

                if (load_cnt == 5'd15 && msg_word_valid_i)
                    next_state = ST_ROUND;
            end

            // --------------------------------------------------------------
            ST_ROUND: begin
                hash_en_o = 1'b1;

                if (round_cnt == 6'd63)
                    next_state = ST_FINAL;
            end

            // --------------------------------------------------------------
            ST_FINAL: begin
                final_o   = 1'b1;
                next_state = ST_DONE;
            end

            // --------------------------------------------------------------
            ST_DONE: begin
                done_o = 1'b1;
                next_state = ST_IDLE;
            end

            // --------------------------------------------------------------
            default: begin
                next_state = ST_IDLE;
            end

        endcase
    end

endmodule


//trialllll
`timescale 1ns / 1ps

module sha256_controller (
    input  logic        clk,
    input  logic        rst_n,

    // Control input
    input  logic        msg_valid,   //asserted when new 512-bit block is ready

    // Outputs to datapath
    output logic        d_valid,            // goes to hash_core
    output logic        scheduler_en,            // enable message scheduler
    output logic [5:0]  round_idx,           // 0 to 63, for Wt and Kt
    output logic        hash_done            // indicates final hash is valid
);

    // ------------------------------------------------------------
    // FSM state encoding
    // ------------------------------------------------------------
    typedef enum logic [1:0] {
        IDLE,
        LOAD,
        COMPRESS,
        DONE
    } state_t;

    state_t state, next_state;

    // ------------------------------------------------------------
    // Round counter (shared by scheduler + ROM)
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            round_idx <= 6'd0;
        else if (state == LOAD)
            round_idx <= 6'd0;
        else if (state == COMPRESS)
            round_idx <= round_idx + 6'd1;
    end

    // ------------------------------------------------------------
    // FSM state register
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------------------
    // FSM next-state logic
    // ------------------------------------------------------------
    always_comb begin
        next_state = state;

        case (state)
            IDLE: begin
                if (msg_valid)
                    next_state = LOAD;
            end

            LOAD: begin
                next_state = COMPRESS;
            end

            COMPRESS: begin
                if (round_idx == 6'd63)
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------
    // Output logic
    // ------------------------------------------------------------
    always_comb begin
        // Default outputs
        d_valid   = 1'b0;
        scheduler_en  = 1'b0;
        hash_done = 1'b0;

        case (state)
            IDLE: begin
                // nothing active
            end

            LOAD: begin
                d_valid  = 1'b1;   // pulse to load initial hash values
                scheduler_en = 1'b1;   // prepare scheduler
            end

            COMPRESS: begin
                scheduler_en = 1'b1;   // scheduler + ROM active
            end

            DONE: begin
                hash_done = 1'b1;  // final hash is valid
            end
        endcase
    end

endmodule

