`timescale 1ns/1ps

module uart_loopback_tb;

    parameter CLKS_PER_BIT = 16;

    reg clk = 0;
    reg rst = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;

    wire tx;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;

    integer pass_count = 0;
    integer i;
    reg [7:0] test_data [0:3];

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) receiver (
        .clk(clk),
        .rst(rst),
        .rx(tx),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rx_valid) begin
            if (rx_data !== test_data[pass_count])
                $fatal(1, "FAIL: Byte %0d expected %02h, got %02h",
                       pass_count, test_data[pass_count], rx_data);

            $display("PASS: Byte %0d received = 0x%02h",
                     pass_count + 1, rx_data);

            pass_count <= pass_count + 1;
        end
    end

    initial begin
        $dumpfile("sim/uart_loopback.vcd");
        $dumpvars(0, uart_loopback_tb);

        test_data[0] = 8'hA5;
        test_data[1] = 8'h3C;
        test_data[2] = 8'h55;
        test_data[3] = 8'hFF;

        $display("UART Multi-Byte Loopback Test Started");

        repeat (4) @(negedge clk);
        rst = 0;

        for (i = 0; i < 4; i = i + 1) begin
            wait (tx_busy == 0);
            @(negedge clk);

            tx_data = test_data[i];
            tx_start = 1;

            @(negedge clk);
            tx_start = 0;

            wait (pass_count == i + 1);
            repeat (3) @(negedge clk);
        end

        $display("ALL 4 UART LOOPBACK TESTS PASSED");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "TIMEOUT: Multi-byte test did not complete");
    end

endmodule