`timescale 1ns/1ps

module uart_rx_error_tb;

    parameter CLKS_PER_BIT = 16;

    reg clk = 0;
    reg rst = 1;
    reg rx = 1;

    wire [7:0] rx_data;
    wire rx_valid;
    wire framing_error;

    reg error_detected = 0;

    integer i;

    // UART Receiver Under Test
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );

    always #5 clk = ~clk;

    // Monitor receiver status
    always @(posedge clk) begin
        if (!rst && rx_valid)
            $fatal(1, "FAIL: Invalid frame was accepted");

        if (!rst && framing_error) begin
            error_detected <= 1'b1;
            $display("PASS: Framing error detected");
        end
    end

    initial begin
        $dumpfile("sim/uart_rx_error.vcd");
        $dumpvars(0, uart_rx_error_tb);

        $display("UART RX Framing Error Test Started");

        // Reset receiver
        repeat (4) @(negedge clk);
        rst = 0;

        // Start bit
        rx = 0;
        repeat (CLKS_PER_BIT) @(negedge clk);

        // Send 0xA5, least-significant bit first
        for (i = 0; i < 8; i = i + 1) begin
            rx = (8'hA5 >> i) & 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);
        end

        // Invalid stop bit: LOW instead of HIGH
        rx = 0;
        repeat (CLKS_PER_BIT) @(negedge clk);

        // Return to idle and allow receiver to settle
        rx = 1;
        repeat (CLKS_PER_BIT + 4) @(negedge clk);

        // Check that framing error was actually detected
        if (!error_detected)
            $fatal(1, "FAIL: Framing error was not detected");

        $display("PASS: Invalid stop bit was rejected");
        $display("ALL FRAMING ERROR TESTS PASSED");

        $finish;
    end

    // Timeout protection
    initial begin
        #5000;
        $fatal(1, "TIMEOUT: Framing error test did not complete");
    end

endmodule