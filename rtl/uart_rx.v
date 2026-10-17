`timescale 1ns/1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 16
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        framing_error
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;

    // Synchronize asynchronous RX input
    reg rx_sync1, rx_sync2;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            rx_data       <= 0;
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;
        end else begin
            // One-cycle status pulses
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;

            case (state)

                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx_sync2 == 1'b0)
                        state <= START;
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT/2 - 1)) begin
                        clk_count <= 0;

                        if (rx_sync2 == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        rx_data[bit_index] <= rx_sync2;

                        if (bit_index == 7) begin
                            bit_index <= 0;
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 0;
                        state <= IDLE;

                        if (rx_sync2 == 1'b1) begin
                            rx_valid <= 1'b1;
                        end else begin
                            framing_error <= 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= IDLE;
                    clk_count <= 0;
                    bit_index <= 0;
                end

            endcase
        end
    end

endmodule