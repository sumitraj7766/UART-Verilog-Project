
`timescale 1ns/1ps

module uart_top_tb;

    parameter CLKS_PER_BIT = 16;

    reg clk = 0;
    reg rst = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;

    wire tx_pin;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
    wire framing_error;

    reg [7:0] test_bytes [0:3];
    integer received_count = 0;
    integer i;

    uart_top #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_pin(tx_pin),
        .tx_busy(tx_busy),
        .rx_pin(tx_pin),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .framing_error(framing_error)
    );

    always #5 clk = ~clk;

    // Capture every received byte
    always @(posedge clk) begin
        if (!rst && rx_valid) begin
            if (received_count > 3)
                $fatal(1, "FAIL: Unexpected extra received byte");

            if (rx_data !== test_bytes[received_count])
                $fatal(1, "FAIL: Expected %h, received %h",
                       test_bytes[received_count], rx_data);

            if (framing_error)
                $fatal(1, "FAIL: Unexpected framing error");

            $display("PASS: Received %h", rx_data);
            received_count = received_count + 1;
        end

        if (!rst && framing_error)
            $fatal(1, "FAIL: Unexpected framing error");
    end

    initial begin
        $dumpfile("sim/uart_top.vcd");
        $dumpvars(0, uart_top_tb);

        test_bytes[0] = 8'hA5;
        test_bytes[1] = 8'h3C;
        test_bytes[2] = 8'h55;
        test_bytes[3] = 8'hFF;

        $display("UART Top-Level Test Started");

        repeat (4) @(negedge clk);
        rst = 0;

        for (i = 0; i < 4; i = i + 1) begin
            // Wait until transmitter is idle
            wait (tx_busy == 1'b0);
            @(negedge clk);

            tx_data = test_bytes[i];
            tx_start = 1'b1;

            @(negedge clk);
            tx_start = 1'b0;

            // Allow enough time for the complete UART frame
            wait (tx_busy == 1'b1);
            wait (tx_busy == 1'b0);
            repeat (CLKS_PER_BIT * 3) @(negedge clk);
        end

        // Allow final receiver status to settle
        repeat (CLKS_PER_BIT * 2) @(negedge clk);

        if (received_count != 4)
            $fatal(1, "FAIL: Expected 4 bytes, received %0d",
                   received_count);

        $display("ALL UART TOP-LEVEL TESTS PASSED");
        $finish;
    end

    initial begin
        #20000;
        $fatal(1, "TIMEOUT: UART top-level test did not complete");
    end

endmodule
