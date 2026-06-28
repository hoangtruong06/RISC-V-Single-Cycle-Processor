`timescale 1ns / 1ps

module tb_riscv();
    reg clk = 0;
    reg rst;
    always #5 clk = ~clk;

    riscv_top DUT (.clk(clk), .rst(rst));

    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        // Run for enough cycles (10 loop iterations x ~5 inst + setup)
        repeat (200) @(posedge clk);

        $display("==========================================");
        $display("  RISC-V Processor - Final Register State");
        $display("==========================================");
        $display("  PC  = 0x%08H", DUT.pc);
        $display("  x0  = %0d (hardwired 0)", DUT.rf.registers[0]);
        $display("  x1  = %0d (i, expect 11)",  DUT.rf.registers[1]);
        $display("  x2  = %0d (limit, expect 11)", DUT.rf.registers[2]);
        $display("  x3  = %0d (step, expect 1)",   DUT.rf.registers[3]);
        $display("  x4  = %0d (SLT temp)",         DUT.rf.registers[4]);
        $display("  x5  = %0d (SUM, expect 55)",   DUT.rf.registers[5]);
        $display("==========================================");

        if (DUT.rf.registers[5] === 32'd55)
            $display("  >>> x5 = 55: PROGRAM CORRECT! <<<");
        else
            $display("  >>> x5 = %0d: INCORRECT (expected 55) <<<",
                     DUT.rf.registers[5]);

        $display("==========================================");
        $finish();
    end

    // Timeout watchdog
    initial begin
        #50000;
        $display("TIMEOUT");
        $finish();
    end

    // Instruction trace (uncomment for debugging)
    // always @(posedge clk) begin
    //     if (!rst)
    //         $display("t=%4t PC=%03H inst=%08H x1=%0d x5=%0d alu=%0d",
    //                  $time, DUT.pc, DUT.instruction,
    //                  DUT.rf.registers[1], DUT.rf.registers[5],
    //                  DUT.alu_result);
    // end
endmodule
