
`timescale 1ns/1ps

module uart_top #(
    parameter CLKS_PER_BIT = 16
)(
    input  wire       clk,
    input  wire       rst,

    // Transmitter interface
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output wire       tx_pin,
    output wire       tx_busy,

    // Receiver interface
    input  wire       rx_pin,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       framing_error
);

    // UART Transmitter
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx_pin),
        .tx_busy(tx_busy)
    );

    // UART Receiver
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) receiver (
        .clk(clk),
        .rst(rst),
        .rx(rx_pin),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );

endmodule
