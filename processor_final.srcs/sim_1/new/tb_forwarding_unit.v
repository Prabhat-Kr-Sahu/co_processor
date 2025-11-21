`timescale 1ns/1ps

module tb_forwarding_unit;

    // Inputs to the DUT
    reg         ex_mem_reg_write;
    reg         mem_wb_reg_write;
    reg  [4:0]  id_ex_rs1;
    reg  [4:0]  id_ex_rs2;
    reg  [4:0]  ex_mem_rd;
    reg  [4:0]  mem_wb_rd;

    // Outputs from the DUT
    wire [1:0]  forwardA;
    wire [1:0]  forwardB;

    // Instantiate the forwarding unit
    forwarding_unit dut (
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );
    
    // Test sequence
    // ...existing code...
    // Test sequence
    initial begin
        $display("Starting Forwarding Unit Testbench for Dependent Multiplications");

        $display("=====================================================================");

        // --- Cycle 0: Initial State ---
        $display("\n--- Cycle 0: Pipeline empty ---");
// ...existing code...
        mem_wb_rd <= 5'b0; mem_wb_reg_write <= 0;
        #10;

        // --- Cycle 1: 'addi x5' in EX stage ---
// ...existing code...
        mem_wb_reg_write <= 0;
        #10;

        // --- Cycle 2: 'addi x6' in EX, 'addi x5' in MEM ---
        $display("\n--- Cycle 2: addi x6 (in EX), addi x5 (in MEM) ---");
        ex_mem_rd <= 5; ex_mem_reg_write <= 1; // x5 from previous cycle is now at MEM stage input
        mem_wb_reg_write <= 0;
        #10;
        
        // --- Cycle 3: 'mul x7, x5, x6' in EX stage ---
        $display("\n--- Cycle 3: mul x7, x5, x6 (in EX) ---");
        $display("HAZARD: Reading x5 and x6. x5 is in MEM/WB, x6 is in EX/MEM.");
        id_ex_rs1 <= 5; id_ex_rs2 <= 6;        // mul reads x5, x6
        ex_mem_rd <= 6; ex_mem_reg_write <= 1; // addi x6 result
        mem_wb_rd <= 5; mem_wb_reg_write <= 1; // addi x5 result
        #10;
        if (forwardA !== 2'b01) $fatal(1, "FAIL: forwardA should be 2'b01 (MEM->EX), but was %b", forwardA);
        if (forwardB !== 2'b10) $fatal(1, "FAIL: forwardB should be 2'b10 (EX->EX), but was %b", forwardB);
        $display("PASS: forwardA = %b, forwardB = %b. Correctly forwarding from MEM and EX.", forwardA, forwardB);

        // --- Cycle 4: 'mul x8, x7, x5' in EX stage ---
        $display("\n--- Cycle 4: mul x8, x7, x5 (in EX) ---");
        $display("HAZARD: Reading x7. x7 is in EX/MEM. x5 is available in RegFile.");
        id_ex_rs1 <= 7; id_ex_rs2 <= 5;        // mul reads x7, x5
        ex_mem_rd <= 7; ex_mem_reg_write <= 1; // mul x7 result
        mem_wb_rd <= 6; mem_wb_reg_write <= 1; // addi x6 result
        #10;
        if (forwardA !== 2'b10) $fatal(1, "FAIL: forwardA should be 2'b10 (EX->EX), but was %b", forwardA);
        if (forwardB !== 2'b00) $fatal(1, "FAIL: forwardB should be 2'b00 (No Hazard), but was %b", forwardB);
        $display("PASS: forwardA = %b, forwardB = %b. Correctly forwarding from EX for rs1.", forwardA, forwardB);

        // --- Cycle 5: 'mul x9, x8, x7' in EX stage ---
        $display("\n--- Cycle 5: mul x9, x8, x7 (in EX) ---");
        $display("HAZARD: Reading x8 and x7. x8 is in EX/MEM. x7 is in MEM/WB.");
        $display("This tests EX hazard priority over MEM hazard.");
        id_ex_rs1 <= 8; id_ex_rs2 <= 7;        // mul reads x8, x7
        ex_mem_rd <= 8; ex_mem_reg_write <= 1; // mul x8 result
        mem_wb_rd <= 7; mem_wb_reg_write <= 1; // mul x7 result
        #10;
        if (forwardA !== 2'b10) $fatal(1, "FAIL: forwardA should be 2'b10 (EX->EX), but was %b", forwardA);
        if (forwardB !== 2'b01) $fatal(1, "FAIL: forwardB should be 2'b01 (MEM->EX), but was %b", forwardB);
        $display("PASS: forwardA = %b, forwardB = %b. Correctly forwarding from EX for rs1 and MEM for rs2.", forwardA, forwardB);

        // --- Cycle 6: Pipeline bubble/nop in EX stage ---
        $display("\n--- Cycle 6: NOP in EX ---");
        id_ex_rs1 <= 0; id_ex_rs2 <= 0;
        ex_mem_rd <= 9; ex_mem_reg_write <= 1; // mul x9 result
        mem_wb_rd <= 8; mem_wb_reg_write <= 1; // mul x8 result
        #10;
        if (forwardA !== 2'b00) $fatal(1, "FAIL: forwardA should be 2'b00 for NOP, but was %b", forwardA);
        if (forwardB !== 2'b00) $fatal(1, "FAIL: forwardB should be 2'b00 for NOP, but was %b", forwardB);
        $display("PASS: forwardA = %b, forwardB = %b. Correctly idle.", forwardA, forwardB);
        
        $display("\nAll test cases passed!");
        $finish;
    end

    
    // Optional: Monitor to see changes
    initial begin
        $monitor("Time=%0t | id_ex_rs1=%d, id_ex_rs2=%d | ex_mem_rd=%d, ex_mem_wr=%b | mem_wb_rd=%d, mem_wb_wr=%b || forwardA=%b, forwardB=%b",
                 $time, id_ex_rs1, id_ex_rs2, ex_mem_rd, ex_mem_reg_write, mem_wb_rd, mem_wb_reg_write, forwardA, forwardB);
    end

endmodule