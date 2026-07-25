
module dual_port_memory (
    // PORT A: Instruction Fetch (Using clk1)
    input           clka,   // Connect to clk1
    input   [31:0]  addra,  // Connect to PC
    output reg  [31:0]  douta,  // Connect to IF_ID_IR
    input           wea,    // Hardwire to 0 (Read Only) (used for inferring synthesis tool to RAM instead of ROM)

    // PORT B: Data Access (Using clk2)
    input           clkb,   // Connect to clk2
    input   [31:0]  addrb,  // Connect to ALU Result
    input   [31:0]  dinb,   // Connect to Register Data (for SW)
    output reg   [31:0]  doutb,  // Connect to MEM_WB_LMD
    input           web     // Connect to MemWrite signal
);

    reg [31:0] mem [0:1023];
    // sample instructions for verification and testing
    initial begin
          /*mem[0] = 32'h2801000a;  // ADDI  R1,R0,10 
          mem[1] = 32'h28020014;  // ADDI  R2,R0,20 
          mem[2] = 32'h28030019;  // ADDI  R3,R0,25           
          mem[3] = 32'h00222000;  // ADD   R4,R1,R2  
          mem[4] = 32'h00832800;  // ADD   R5,R4,R3 
          mem[5] = 32'hfc000000;  // HLT*/
        
        
        
        /*mem[0] = 32'h28010078;  // ADDI  R1,R0,120 
     
        mem[1] = 32'h20220000;  // LW    R2, 0(R1)
        mem[2] = 32'h2842002d;  // ADDI R2,R2,45
        mem[3] = 32'h24220001;  // SW    R2,1(R1) 
        mem[4] = 32'hfc000000;  // HLT   

        mem[120] = 85;*/
        
        /*mem[0] = 32'h280a00c8;  // ADDI  R10,R0,200 
        mem[1] = 32'h28020001;  // ADDI  R2,R0,1 
        mem[2] = 32'h21430000;  // LW    R3,0(R10) 
        mem[3] = 32'h14431000;  // Loop: MUL   R2,R2,R3 
        mem[4] = 32'h2c630001;  // SUBI  R3,R3,1    
        mem[5] = 32'h3460fffc;  // BNEQZ R3,Loop  (i.e. -4  offset) 
        mem[6] = 32'h2542fffe;  // SW    R2,-2(R10) 
        mem[7] = 32'hfc000000; // HLT 
        mem[200] = 7 ;*/
        
        mem[0] = 32'h2801000a;  // ADDI R1, R0, 10
        mem[1] = 32'h28220005;  // ADDI R2, R1, 5  (RAW Hazard: R1)

        // --- TEST 2: Double Forwarding (MEM-to-EX & EX-to-EX) ---
        mem[2] = 32'h00221800;  // ADD  R3, R1, R2 (RAW Hazard: R1, R2)
        

        // --- TEST 3: Forwarding directly into a Branch Condition ---
        mem[3] = 32'h28040002;  // ADDI R4, R0, 2
        mem[4] = 32'h2c840001;  // Loop: SUBI R4, R4, 1 
        
        // Branch Offset calculation: 
        // BNEQZ is at PC=5. Target is PC=4. Offset = Target - (PC + 1) = 4 - 6 = -2.
        // -2 in 16-bit 2's complement is 16'hfffe.
        mem[5] = 32'h3480fffd;  // BNEQZ R4, Loop (RAW Hazard: R4)

        // --- TEST 4: The Phantom Instruction (Flush Verification) ---
        mem[6] = 32'h28090063;  // ADDI R9, R0, 99 (Should NEVER execute)

        // --- TEST 5: Branch Not Taken (Fallthrough) ---
        mem[7] = 32'h2805004d;  // ADDI R5, R0, 77 
        
        mem[8] = 32'hfc000000;  // HLT 
        
    end
        
    always @(posedge clka)begin
        if(wea)
            mem[addra] <= 0;    
        else
            douta <= mem[addra];    
    end
    always @(posedge clkb)begin
        if(web)
            mem[addrb] <= dinb;
        else
            doutb <= mem[addrb];
            
    end
    
    

endmodule

