`timescale 1ns/1ps

module uart_tx_tb;

    parameter CLKS_PER_BIT = 16;

    reg clk = 0;
    reg rst = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;

    wire tx;
    wire tx_busy;

    integer i;
    reg [7:0] expected_data;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Generate 100 MHz clock: period = 10 ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/uart_tx.vcd");
        $dumpvars(0, uart_tx_tb);

        expected_data = 8'hA5;

        $display("UART TX Test Started");

        // Reset
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Start transmission
        tx_data = expected_data;
        tx_start = 1;
        @(negedge clk);
        tx_start = 0;

        // Wait for start bit and check its center
        repeat (CLKS_PER_BIT/2) @(posedge clk);
        #1;
        if (tx !== 1'b0)
            $fatal(1, "FAIL: Start bit incorrect");

        // Move to the center of the first data bit
        repeat (CLKS_PER_BIT) @(posedge clk);
        #1;

        for (i = 0; i < 8; i = i + 1) begin
            if (tx !== expected_data[i])
                $fatal(1, "FAIL: Data bit %0d incorrect", i);

            $display("PASS: Data bit %0d = %b", i, tx);

            repeat (CLKS_PER_BIT) @(posedge clk);
            #1;
        end

        // Stop bit
        if (tx !== 1'b1)
            $fatal(1, "FAIL: Stop bit incorrect");

        $display("PASS: Stop bit = 1");

        wait (tx_busy == 0);
        $display("ALL UART TX TESTS PASSED");

        #20;
        $finish;
    end

endmodule