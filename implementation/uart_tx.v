// ============================================================================
// UART Transmitter Module
// ============================================================================
// Description: 
//   - Transmits serial data via UART protocol
//   - Configurable baud rate via CLKS_PER_BIT parameter
//   - 8 data bits, 1 stop bit, no parity (8N1 format)
//   - Handshake: Assert i_Tx_DV with valid i_Tx_Byte to start transmission
//   - o_Tx_Active goes high during transmission
//   - o_Tx_Done pulses for 1 clock cycle when transmission complete
// ============================================================================

`timescale 1ns / 1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 10416  // For 100MHz clock, 9600 baud
                                     // Formula: CLKS_PER_BIT = Clock_Freq / Baud_Rate
)(
    input  wire       i_Clock,
    input  wire       i_Tx_DV,       // Data Valid - pulse to start transmission
    input  wire [7:0] i_Tx_Byte,     // Byte to transmit
    output reg        o_Tx_Active,   // High during transmission
    output reg        o_Tx_Serial,   // Serial output line
    output reg        o_Tx_Done      // Pulse for 1 clock when byte sent
);

    // State machine states
    localparam IDLE         = 3'b000;
    localparam TX_START_BIT = 3'b001;
    localparam TX_DATA_BITS = 3'b010;
    localparam TX_STOP_BIT  = 3'b011;
    localparam CLEANUP      = 3'b100;
    
    reg [2:0]  r_SM_Main;
    reg [15:0] r_Clock_Count;
    reg [2:0]  r_Bit_Index;     // 8 bits total (0 to 7)
    reg [7:0]  r_Tx_Data;
    
    // Main UART TX State Machine
    always @(posedge i_Clock) begin
        case (r_SM_Main)
            
            IDLE: begin
                o_Tx_Serial   <= 1'b1;     // Drive line high for idle
                o_Tx_Done     <= 1'b0;
                r_Clock_Count <= 0;
                r_Bit_Index   <= 0;
                
                if (i_Tx_DV == 1'b1) begin
                    o_Tx_Active <= 1'b1;
                    r_Tx_Data   <= i_Tx_Byte;  // Latch the byte to transmit
                    r_SM_Main   <= TX_START_BIT;
                end
                else begin
                    o_Tx_Active <= 1'b0;
                    r_SM_Main   <= IDLE;
                end
            end
            
            // Send out Start Bit (Start bit = 0)
            TX_START_BIT: begin
                o_Tx_Serial <= 1'b0;
                
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= TX_START_BIT;
                end
                else begin
                    r_Clock_Count <= 0;
                    r_SM_Main     <= TX_DATA_BITS;
                end
            end
            
            // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish
            TX_DATA_BITS: begin
                o_Tx_Serial <= r_Tx_Data[r_Bit_Index];
                
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= TX_DATA_BITS;
                end
                else begin
                    r_Clock_Count <= 0;
                    
                    // Check if we have sent out all bits
                    if (r_Bit_Index < 7) begin
                        r_Bit_Index <= r_Bit_Index + 1;
                        r_SM_Main   <= TX_DATA_BITS;
                    end
                    else begin
                        r_Bit_Index <= 0;
                        r_SM_Main   <= TX_STOP_BIT;
                    end
                end
            end
            
            // Send out Stop bit (Stop bit = 1)
            TX_STOP_BIT: begin
                o_Tx_Serial <= 1'b1;
                
                if (r_Clock_Count < CLKS_PER_BIT-1) begin
                    r_Clock_Count <= r_Clock_Count + 1;
                    r_SM_Main     <= TX_STOP_BIT;
                end
                else begin
                    o_Tx_Done     <= 1'b1;     // Signal transmission complete
                    r_Clock_Count <= 0;
                    r_SM_Main     <= CLEANUP;
                end
            end
            
            // Stay here 1 clock cycle
            CLEANUP: begin
                o_Tx_Active <= 1'b0;
                o_Tx_Done   <= 1'b0;
                r_SM_Main   <= IDLE;
            end
            
            default: begin
                r_SM_Main <= IDLE;
            end
            
        endcase
    end
    
endmodule