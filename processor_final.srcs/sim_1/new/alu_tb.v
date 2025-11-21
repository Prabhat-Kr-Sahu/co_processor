module pipelined_alu_tb();
    reg [31:0] read_data1_in, read_data2_in;
    reg [31:0] ex_mem_alu_result_in, mem_wb_result_in;
    reg [1:0] forwardA, forwardB;
    reg [5:0] alu_control;
    reg [31:0] imm_val_r;
    reg [4:0] shamt;
    reg alu_src;
    
    wire [31:0] result;
    
    // Instantiate the Unit Under Test (UUT)
    pipelined_alu uut(
        .read_data1_in(read_data1_in),
        .read_data2_in(read_data2_in),
        .ex_mem_alu_result_in(ex_mem_alu_result_in),
        .mem_wb_result_in(mem_wb_result_in),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .alu_control(alu_control),
        .imm_val_r(imm_val_r),
        .shamt(shamt),
        .alu_src(alu_src),
        .result(result)
    );
    
    initial begin
        // Initialize
        read_data1_in = 32'h10;
        read_data2_in = 32'h20;
        ex_mem_alu_result_in = 32'h100;
        mem_wb_result_in = 32'h200;
        forwardA = 2'b00;
        forwardB = 2'b00;
        alu_control = 6'b000001;  // ADD
        imm_val_r = 32'h5;
        shamt = 5'h2;
        alu_src = 1'b0;
        
        #10;
        
        // Test Case 1: No forwarding - simple ADD
        $display("=== Test Case 1: No forwarding ADD ===");
        $display("Result: %h (Expected: 30)", result);
        if (result == 32'h30) $display("Test 1 PASS"); else $display("Test 1 FAIL");
        
        // Test Case 2: Forward from EX/MEM to src1
        $display("\n=== Test Case 2: Forward EX/MEM to src1 ===");
        forwardA = 2'b10;  // Forward from EX/MEM
        #1;
        $display("Result: %h (Expected: 120)", result);
        if (result == 32'h120) $display("Test 2 PASS"); else $display("Test 2 FAIL");
        
        // Test Case 3: Forward from MEM/WB to src2
        $display("\n=== Test Case 3: Forward MEM/WB to src2 ===");
        forwardA = 2'b00;  // Reset src1 forwarding
        forwardB = 2'b01;  // Forward from MEM/WB
        #1;
        $display("Result: %h (Expected: 210)", result);
        if (result == 32'h210) $display("Test 3 PASS"); else $display("Test 3 FAIL");
        

        // Test Case 4: Use immediate instead of rs2
        $display("\n=== Test Case 4: ADDI with immediate ===");
        forwardB = 2'b00;  // Reset src2 forwarding
        alu_src = 1'b1;    // Use immediate
        alu_control = 6'b001011;  // ADDI
        #1;
        $display("Result: %h (Expected: 15)", result);
        if (result == 32'h15) $display("Test 4 PASS"); else $display("Test 4 FAIL");
        
        // Test Case 5: Branch comparison with forwarding
        $display("\n=== Test Case 5: BEQ with forwarding ===");
        alu_src = 1'b0;    // Use register
        alu_control = 6'b011100;  // BEQ
        forwardA = 2'b10;  // Forward 100 to src1
        forwardB = 2'b10;  // Forward 100 to src2
        #1;
        $display("Result: %h (Expected: 1 - equal)", result);
        if (result == 32'h1) $display("Test 5 PASS"); else $display("Test 5 FAIL");
        
        // --- NEW TEST CASE ---
        // Test Case 6: Multiplication
        $display("\n=== Test Case 6: Multiplication ===");
        read_data1_in = 32'h6;
        read_data2_in = 32'h7;
        alu_src = 1'b0;    // Use register
        forwardA = 2'b00;  // No forwarding
        forwardB = 2'b00;  // No forwarding
        // NOTE: This assumes '6'b011000' is the control code for MULTIPLY.
        // Please change this value if your ALU design uses a different code.
        alu_control = 6'b011000;  // Assumed MULT code
        #1;
        $display("Result: %h (Expected: 2A)", result); // 6 * 7 = 42 (0x2A)
        if (result == 32'h2A) $display("Test 6 PASS"); else $display("Test 6 FAIL");
        
        // --- NEW TEST CASE ---
        // Test Case 7: 5-Instruction Dependent Multiplication Chain
        // This single case simulates a chain of 5 dependent MULs,
        // testing the EX/MEM -> EX forwarding path repeatedly.
        $display("\n=== Test Case 7: 5-Instruction Dependent MUL Chain ===");

        // --- Chain 1 (Old Test 7) ---
        // State: T6 result (42) is in EX/MEM.
        // Exec: 42 * 2 = 84 (0x54)
        ex_mem_alu_result_in = 32'h2A; // Result from T6 (6*7)
        read_data1_in = 32'hAAAA;   // Old reg value (should be ignored)
        read_data2_in = 32'h2;      // New operand
        alu_src = 1'b0;    // Use register
        forwardA = 2'b10;  // FORWARD the result (0x2A) from EX/MEM to src1
        forwardB = 2'b00;  // No forwarding for src2
        alu_control = 6'b011000;  // MUL operation
        #1;
        $display("Chain 1 Result: %h (Expected: 54)", result); 
        if (result == 32'h54) $display("Test 7.1 PASS"); else $display("Test 7.1 FAIL");

        // --- Chain 2 (Old Test 8) ---
        // State: T7 result (84) in EX/MEM, T6 result (42) in MEM/WB
        // Exec: 84 * 3 = 252 (0xFC)
        ex_mem_alu_result_in = 32'h54; // Result from previous (84)
        mem_wb_result_in = 32'h2A;   // Result from 2-ago (42)
        read_data2_in = 32'h3;      // New operand
        // forwardA = 2'b10; (still set)
        #1;
        $display("Chain 2 Result: %h (Expected: FC)", result); 
        if (result == 32'hFC) $display("Test 7.2 PASS"); else $display("Test 7.2 FAIL");
        
        // --- Chain 3 (Old Test 9) ---
        // State: T8 result (252) in EX/MEM, T7 result (84) in MEM/WB
        // Exec: 252 * 4 = 1008 (0x3F0)
        ex_mem_alu_result_in = 32'hFC; // Result from previous (252)
        mem_wb_result_in = 32'h54;   // Result from 2-ago (84)
        read_data2_in = 32'h4;      // New operand
  	    // forwardA = 2'b10; (still set)
        #1;
        $display("Chain 3 Result: %h (Expected: 3F0)", result); 
        if (result == 32'h3F0) $display("Test 7.3 PASS"); else $display("Test 7.3 FAIL");
        
        // --- Chain 4 (Old Test 10) ---
        // State: T9 result (1008) in EX/MEM, T8 result (252) in MEM/WB
        // Exec: 1008 * 5 = 5040 (0x13B0)
        ex_mem_alu_result_in = 32'h3F0; // Result from previous (1008)
        mem_wb_result_in = 32'hFC;    // Result from 2-ago (252)
        read_data2_in = 32'h5;       // New operand
      	// forwardA = 2'b10; (still set)
        #1;
        $display("Chain 4 Result: %h (Expected: 13B0)", result); 
        if (result == 32'h13B0) $display("Test 7.4 PASS"); else $display("Test 7.4 FAIL");
        
        // --- Chain 5 (Old Test 11) ---
        // State: T10 result (5040) in EX/MEM, T9 result (1008) in MEM/WB
        // Exec: 5040 * 6 = 30240 (0x7620)
        ex_mem_alu_result_in = 32'h13B0; // Result from previous (5040)
        mem_wb_result_in = 32'h3F0;    // Result from 2-ago (1008)
        read_data2_in = 32'h6;        // New operand
      	// forwardA = 2'b10; (still set)
        #1;
        $display("Chain 5 Result: %h (Expected: 7620)", result); 
        if (result == 32'h7620) $display("Test 7.5 PASS"); else $display("Test 7.5 FAIL");
        
        $finish;
    end
    
endmodule