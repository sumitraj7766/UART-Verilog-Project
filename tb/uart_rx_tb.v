`timescale 1ns/1ps

module uart_rx_tb;

    parameter CLKS_PER_BIT = 16;

    reg clk = 0;
    reg rst = 1;
    reg rx = 1;

    wire [7:0] rx_data;
    wire rx_valid;

    reg [7:0] expected_data = 8'hA5;
    integer i;
    reg received = 0;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    // 100 MHz clock: 10 ns period
    always #5 clk = ~clk;

    // Check received data when rx_valid is asserted
    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_data !== expected_data)
                $fatal(1, "FAIL: Expected %h, received %h",
                       expected_data, rx_data);

            received <= 1'b1;
            $display("PASS: Received byte = 0x%02h", rx_data);
        end
    end

    initial begin
        $dumpfile("sim/uart_rx.vcd");
        $dumpvars(0, uart_rx_tb);

        $display("UART RX Test Started");

        // Reset receiver
        repeat (4) @(negedge clk);
        rst = 0;

        // Start bit
        rx = 0;
        repeat (CLKS_PER_BIT) @(negedge clk);

        // Data bits, LSB first
        for (i = 0; i < 8; i = i + 1) begin
            rx = expected_data[i];
            repeat (CLKS_PER_BIT) @(negedge clk);
        end

        // Stop bit
        rx = 1;
        repeat (CLKS_PER_BIT + 4) @(negedge clk);

        if (!received)
            $fatal(1, "FAIL: Receiver did not report valid data");

        $display("ALL UART RX TESTS PASSED");

        #20;
        $finish;
    end

endmodule