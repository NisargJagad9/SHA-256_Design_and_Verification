`timescale 1ns / 1ps

module tb_sha256_top;

    // -------------------------------------------------------------------------
    // Signals
    // -------------------------------------------------------------------------
    reg         clk;
    reg         rst_n;

    reg         msg_valid;
    reg  [5:0]  byte_valid;
    reg  [439:0] msg_word;

    wire        hash_done;
    wire [255:0] fin_hash;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    top u_top (
        .clk        (clk),
        .rst_n      (rst_n),
        .msg_valid  (msg_valid),
        .byte_valid (byte_valid),
        .msg_word   (msg_word),
        .hash_done  (hash_done),
        .fin_hash   (fin_hash)
    );

    // -------------------------------------------------------------------------
    // Clock generation (100 MHz → 10 ns period)
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // -------------------------------------------------------------------------
    // VCD dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("sha256_tb.vcd");
        $dumpvars(0, tb_sha256_top);           // dump all signals
        // $dumpvars(1, u_top);                // or just the DUT if preferred
    end

    // -------------------------------------------------------------------------
    // Test stimulus
    // -------------------------------------------------------------------------
    initial begin
        // Initialize
        rst_n       = 0;
        msg_valid   = 0;
        byte_valid  = 0;
        msg_word    = 0;

        $display("=== SHA-256 Testbench started ===");

        // Reset
        repeat (8) @(posedge clk);
        rst_n = 1;
        repeat (8) @(posedge clk);

        // ────────────────────────────────────────────────
        // Test 1: Empty message (should give SHA-256(""))
        // ────────────────────────────────────────────────
        $display("\nTest 1: Empty message");
        send_message("", 0);           // 0 bytes

        wait(hash_done);
        $display("Empty message hash = %h", fin_hash);
        check_hash(fin_hash, 256'he3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855);

        repeat(20) @(posedge clk);

        // ────────────────────────────────────────────────
        // Test 2: "abc" (very short message)
        // ────────────────────────────────────────────────
        $display("\nTest 2: 'abc'");
        send_message("abc", 3);

        wait(hash_done);
        $display("'abc' hash = %h", fin_hash);
        check_hash(fin_hash, 256'hba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad);

        repeat(40) @(posedge clk);

        // ────────────────────────────────────────────────
        // Test 3: Longer message - "The quick brown fox jumps over the lazy dog"
        // ────────────────────────────────────────────────
        $display("\nTest 3: 'The quick brown fox jumps over the lazy dog'");
        send_message("The quick brown fox jumps over the lazy dog", 43);

        wait(hash_done);
        $display("Long message hash = %h", fin_hash);
        check_hash(fin_hash, 256'hd7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592);

        repeat(40) @(posedge clk);

        // ────────────────────────────────────────────────
        // Test 4: Message that needs padding + length > 512 bits (two blocks)
        // ────────────────────────────────────────────────
        $display("\nTest 4: 128-byte message (two 512-bit blocks)");
        send_long_message();

        wait(hash_done);
        $display("128-byte message hash = %h", fin_hash);
        // You can compute expected value externally and put it here

        repeat(100) @(posedge clk);

        $display("\n=== All tests finished ===");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Task: send one message (handles padding automatically in preproc)
    // -------------------------------------------------------------------------
    task automatic send_message(
        input string text,
        input integer len_bytes
    );
        integer i;
        reg [439:0] chunk;
        integer bytes_left = len_bytes;
        integer offset = 0;

        msg_valid <= 0;
        @(posedge clk);

        while (bytes_left > 0) begin
            integer bytes_this_time = (bytes_left >= 55) ? 55 : bytes_left;

            chunk = 0;
            for (i = 0; i < bytes_this_time; i = i + 1) begin
                chunk[439 - i*8 -: 8] = text[offset + i];
            end

            @(posedge clk);
            msg_valid   <= 1;
            byte_valid  <= bytes_this_time[5:0];
            msg_word    <= chunk;

            @(posedge clk);
            msg_valid   <= 0;

            bytes_left -= bytes_this_time;
            offset     += bytes_this_time;
        end

        // Last chunk → trigger padding (byte_valid = 0)
        @(posedge clk);
        msg_valid   <= 1;
        byte_valid  <= 0;
        msg_word    <= 0;
        @(posedge clk);
        msg_valid   <= 0;
    endtask

    // -------------------------------------------------------------------------
    // Task: send a longer message (>64 bytes) to force two blocks
    // -------------------------------------------------------------------------
    task automatic send_long_message();
        integer i;
        reg [7:0] data[0:127];

        // Fill with pattern (example: 0x00, 0x01, ..., repeating)
        for (i = 0; i < 128; i++) begin
            data[i] = i[7:0];
        end

        // Send in chunks of max 55 bytes
        for (i = 0; i < 128; i = i + 55) begin
            integer bytes_this = (i + 55 <= 128) ? 55 : (128 - i);
            reg [439:0] chunk = 0;

            for (integer j = 0; j < bytes_this; j++) begin
                chunk[439 - j*8 -: 8] = data[i + j];
            end

            @(posedge clk);
            msg_valid   <= 1;
            byte_valid  <= bytes_this[5:0];
            msg_word    <= chunk;
            @(posedge clk);
            msg_valid   <= 0;
        end

        // Final chunk with byte_valid=0 → triggers padding
        @(posedge clk);
        msg_valid   <= 1;
        byte_valid  <= 0;
        msg_word    <= 0;
        @(posedge clk);
        msg_valid   <= 0;
    endtask

    // -------------------------------------------------------------------------
    // Simple pass/fail checker
    // -------------------------------------------------------------------------
    task automatic check_hash(
        input [255:0] got,
        input [255:0] expected
    );
        if (got === expected) begin
            $display("   → PASS");
        end else begin
            $display("   → FAIL");
            $display("   Expected: %h", expected);
            $display("   Got:      %h", got);
        end
    endtask

endmodule