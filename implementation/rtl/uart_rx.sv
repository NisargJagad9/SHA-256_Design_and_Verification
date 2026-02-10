`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 10416   // 100MHz / 9600 baud
)(
    input  wire       i_Clock,
    input  wire       i_Reset,      // ACTIVE HIGH RESET
    input  wire       i_Rx_Serial,

    output reg        o_Rx_DV,      // 1-clock pulse when byte valid
    output reg [7:0] o_Rx_Byte
);

    // FSM states
    localparam IDLE         = 3'd0;
    localparam START_BIT   = 3'd1;
    localparam DATA_BITS  = 3'd2;
    localparam STOP_BIT   = 3'd3;
    localparam CLEANUP    = 3'd4;

    reg [2:0]  r_SM_Main = IDLE;
    reg [15:0] r_Clock_Count = 0;
    reg [2:0]  r_Bit_Index = 0;
    reg [7:0]  r_Rx_Byte = 0;

    // RX synchronizer
    reg r_Rx_Data_R = 1'b1;
    reg r_Rx_Data   = 1'b1;

    // Double flop for metastability protection
    always @(posedge i_Clock) begin
        r_Rx_Data_R <= i_Rx_Serial;
        r_Rx_Data   <= r_Rx_Data_R;
    end

    // UART RX FSM
    always @(posedge i_Clock) begin
        if (i_Reset) begin
            r_SM_Main     <= IDLE;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
            r_Rx_Byte    <= 0;
            o_Rx_DV      <= 0;
            o_Rx_Byte    <= 0;
        end else begin
            case (r_SM_Main)

                // Wait for start bit
                IDLE: begin
                    o_Rx_DV      <= 1'b0;
                    r_Clock_Count <= 0;
                    r_Bit_Index  <= 0;

                    if (r_Rx_Data == 1'b0)
                        r_SM_Main <= START_BIT;
                end

                // Confirm start bit in middle
                START_BIT: begin
                    if (r_Clock_Count == (CLKS_PER_BIT-1)/2) begin
                        if (r_Rx_Data == 1'b0) begin
                            r_Clock_Count <= 0;
                            r_SM_Main <= DATA_BITS;
                        end else
                            r_SM_Main <= IDLE;
                    end else
                        r_Clock_Count <= r_Clock_Count + 1;
                end

                // Sample each data bit in the center
                DATA_BITS: begin
                    if (r_Clock_Count == CLKS_PER_BIT-1) begin
                        r_Clock_Count <= 0;
                        r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;

                        if (r_Bit_Index < 7)
                            r_Bit_Index <= r_Bit_Index + 1;
                        else begin
                            r_Bit_Index <= 0;
                            r_SM_Main <= STOP_BIT;
                        end
                    end else
                        r_Clock_Count <= r_Clock_Count + 1;
                end

                // Stop bit
                STOP_BIT: begin
                    if (r_Clock_Count == CLKS_PER_BIT-1) begin
                        o_Rx_Byte <= r_Rx_Byte;
                        o_Rx_DV <= 1'b1;
                        r_Clock_Count <= 0;
                        r_SM_Main <= CLEANUP;
                    end else
                        r_Clock_Count <= r_Clock_Count + 1;
                end

                // One-cycle DV pulse
                CLEANUP: begin
                    o_Rx_DV <= 1'b0;
                    r_SM_Main <= IDLE;
                end

                default: r_SM_Main <= IDLE;
            endcase
        end
    end

endmodule
