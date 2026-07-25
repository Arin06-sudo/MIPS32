
module datapath(
    input clk1, clk2, reset,
    // Interfaces to Controller
    output [5:0] Opcode_out,
    input        Ctrl_RegWrite, Ctrl_MemRead, Ctrl_MemWrite, 
    input        Ctrl_Branch, Ctrl_ALUSrc, Ctrl_Halt
);

    // --- PIPELINE REGISTERS ---
    // IF/ID
    reg [31:0] PC;
    reg [31:0] IF_ID_IR, IF_ID_NPC;
    
    // ID/EX (Includes Control Signals)
    reg [31:0] ID_EX_A, ID_EX_B, ID_EX_Imm, ID_EX_IR, ID_EX_NPC;
    reg        ID_EX_RegWrite, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_Branch, ID_EX_ALUSrc, ID_EX_Halt;
    
    // EX/MEM
    reg [31:0] EX_MEM_ALUOut, EX_MEM_B, EX_MEM_IR;
    reg        EX_MEM_cond;
    reg        EX_MEM_RegWrite, EX_MEM_MemRead, EX_MEM_MemWrite, EX_MEM_Branch, EX_MEM_Halt;
    
    // MEM/WB
    reg [31:0] MEM_WB_ALUOut, MEM_WB_IR;
    reg        MEM_WB_RegWrite, MEM_WB_MemRead, MEM_WB_Halt;


    // --- INTERNAL WIRES ---
    reg [31:0] ALU_InA, ALU_InB;
    reg TAKEN_BRANCH;
    reg HALTED;
    reg flush_next_cycle; /* since our memory is synchronous read, it takes one clo
    ck cycle to give the correct output hence we have to keep IF_ID_IR flushed whenever branching occur so that
    we only capture the correct instruction*/
    assign Opcode_out = IF_ID_IR[31:26]; // Send Opcode to Controller
    
    wire cond_out;
    wire [31:0] alu_out;
    // Wires to catch outputs from the Register Bank
    wire [31:0] reg_read_data_1; 
    wire [31:0] reg_read_data_2;
    
    wire [1:0] Fwda;
    wire [1:0] Fwdb;
    
    // Wires to catch outputs from Memory
    wire [31:0] mem_instr_out; // Instruction from Port A
    wire [31:0] mem_data_out;  // Data from Port B
    wire [31:0] fetch_address;
    assign fetch_address = ((EX_MEM_IR[31:26] == 6'b001110) && (EX_MEM_cond == 1)) ||((EX_MEM_IR[31:26] == 6'b001101) && (EX_MEM_cond == 0))?EX_MEM_ALUOut:PC;
    
    //instantiating cond
    reg [31:0] cond_input;
    cond c1(.A(cond_input),.A_cond(cond_out));
    
    //instantiating ALU
    ALU a1(.A(ALU_InA),.B(ALU_InB),.C(alu_out),.opcode(ID_EX_IR[31:26]));
    
    //instantiating register bank
    reg_bank r1(
          .clk(clk1),
          .addr_wr((MEM_WB_MemRead||MEM_WB_IR[31:26] >= 6'b001010)?MEM_WB_IR[20:16] : MEM_WB_IR[15:11]),//MEM_WB_IR[31:26] < 6'b001010 then we get the R-R type instrcutions, which requires rd = [15:11]
          .Data_in((MEM_WB_MemRead)?mem_data_out : MEM_WB_ALUOut),
 
          .addr_rd1(IF_ID_IR[25:21]),
          .Data_out1(reg_read_data_1),
          .addr_rd2(IF_ID_IR[20:16]),
          .Data_out2(reg_read_data_2),
          .wr(MEM_WB_RegWrite&&!HALTED));
                   
    //instantiating dual port memory
    dual_port_memory m1(
             .clka(clk1),
            .addra(fetch_address),
            .douta(mem_instr_out),
            .wea(1'b0),
            
            .clkb(clk2),
            .addrb(EX_MEM_ALUOut),
            .dinb(EX_MEM_B),
            .doutb(mem_data_out),
            .web(EX_MEM_MemWrite&&!HALTED)
    );
    
    forwarding_unit f1(
        .Rs1(ID_EX_IR[25:21]),
        .Rs2(ID_EX_IR[20:16]),
        .Rd_mem((EX_MEM_IR[31:26]>=6'b001000)? EX_MEM_IR[20:16]:EX_MEM_IR[15:11]),
        .Rd_wb((MEM_WB_IR[31:26]>=6'b001000)? MEM_WB_IR[20:16]:MEM_WB_IR[15:11]),
        .mem_regwrite(EX_MEM_RegWrite),
        .wb_regwrite(MEM_WB_RegWrite),
        .Fwda(Fwda),
        .Fwdb(Fwdb)
     );
     
     
    // --- STAGE 1: IF (clk1) ---
    always @(posedge clk1 or posedge reset) begin
        if (reset) begin
             PC <= 0;
             TAKEN_BRANCH <= 0;
             HALTED <= 0;
             IF_ID_IR <= 0;
             IF_ID_NPC <=0;
             EX_MEM_IR <=0;
             EX_MEM_cond <=0;
             ALU_InA <= 0;
             ALU_InB <= 0;
             ID_EX_A<=0;
             ID_EX_B<=0;
             ID_EX_Imm<=0;
             flush_next_cycle<=0;
  
        end else if (!HALTED) begin
             // Branch Logic (Resolved in Mem stage in your original code)
             if (((EX_MEM_IR[31:26] == 6'b001110) && (EX_MEM_cond == 1)) || // BEQZ
                 ((EX_MEM_IR[31:26] == 6'b001101) && (EX_MEM_cond == 0))) begin // BNEQZ
                 
                 TAKEN_BRANCH <= 1;
                 PC <= EX_MEM_ALUOut;
                 IF_ID_NPC <= EX_MEM_ALUOut + 1;
                 IF_ID_IR <= 32'b0;
                 flush_next_cycle <= 1;
                 
             end else if (flush_next_cycle) begin
                 
                 TAKEN_BRANCH <= 0;
                 IF_ID_IR <= 32'b0; // Flush the garbage delayed instruction
                 flush_next_cycle <= 0; // Turn the flag off
                 
                 IF_ID_NPC <= PC+1;
                 PC <= PC+1; // Keep the PC moving to fetch the next instruction
                 
             // 3. Normal execution
             end else begin
                         
                 IF_ID_NPC <= PC+1;
             
                 PC <= PC + 1;
                 IF_ID_IR <= mem_instr_out;
                 TAKEN_BRANCH <= 0;
             end
        end
    end

    // --- STAGE 2: ID (clk2) ---
    always @(negedge clk2) begin
        if (!HALTED)begin
        
            if(IF_ID_IR[25:21] == 5'b00000) 
                ID_EX_A <= 32'b0;
            else 
                ID_EX_A <= reg_read_data_1; // <--- The crucial step

            if(IF_ID_IR[20:16] == 5'b00000) 
                ID_EX_B <= 32'b0;
            else 
                ID_EX_B <= reg_read_data_2; // <--- The crucial step
                
                
            ID_EX_Imm <= {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};
            
            // Pass Data & Control Signals
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;
            
            // Latch Control Signals from Controller
            ID_EX_RegWrite <= Ctrl_RegWrite;
            ID_EX_MemRead  <= Ctrl_MemRead;
            ID_EX_MemWrite <= Ctrl_MemWrite;
            ID_EX_Branch   <= Ctrl_Branch;
            ID_EX_ALUSrc   <= Ctrl_ALUSrc;
            ID_EX_Halt     <= Ctrl_Halt;
        end
    end
    // Forwarding unit
    always@(*) begin
        
        case (Fwda)
            2'b00: ALU_InA = ID_EX_A;           // Normal (Register File)
            2'b10: ALU_InA = (EX_MEM_MemRead) ? mem_data_out : EX_MEM_ALUOut;     // Forward from MEM (Priority 1)
            2'b01: ALU_InA = (MEM_WB_MemRead) ? mem_data_out : MEM_WB_ALUOut; // Forward from WB (Priority 2)
            default: ALU_InA = ID_EX_A;
        endcase
        cond_input = ALU_InA;
        

        if(ID_EX_Branch&&!ID_EX_ALUSrc) begin //branch
              ALU_InA = ID_EX_NPC;
              ALU_InB = ID_EX_Imm;        
        end
        
        else if(ID_EX_RegWrite&&!ID_EX_ALUSrc) begin // R-type
 
            case (Fwdb)
                2'b00: ALU_InB = ID_EX_B;
                2'b10: ALU_InB = (EX_MEM_MemRead) ? mem_data_out : EX_MEM_ALUOut;
                2'b01: ALU_InB = (MEM_WB_MemRead) ? mem_data_out : MEM_WB_ALUOut;
                default: ALU_InB = ID_EX_B;
            endcase

        end

        else begin

            ALU_InB = ID_EX_Imm;
        end
        
    end
    
    
    // --- STAGE 3: EX (clk1) ---

    always @(posedge clk1) begin
        if (!HALTED) begin
            
            // NEW PIPELINE FLUSH LOGIC:
            // Check if the instruction that just finished EX was a taken branch.
            // If it was, we MUST squash the next instruction (like HLT) from executing.
            if (((EX_MEM_IR[31:26] == 6'b001110) && (EX_MEM_cond == 1)) ||
                ((EX_MEM_IR[31:26] == 6'b001101) && (EX_MEM_cond == 0))) begin
                
                EX_MEM_ALUOut   <= 0;
                EX_MEM_RegWrite <= 0;
                EX_MEM_MemRead  <= 0;
                EX_MEM_MemWrite <= 0;
                EX_MEM_Halt     <= 0;
                EX_MEM_IR       <= 0;
                EX_MEM_cond     <= 0;
                EX_MEM_B        <= 0;
                
            end else begin
                // ... YOUR EXISTING EX STAGE LOGIC ...
                if(ID_EX_MemWrite)begin
                    case(Fwdb)
                        2'b00: EX_MEM_B <= ID_EX_B;
                        2'b10: EX_MEM_B <= EX_MEM_ALUOut;
                        2'b01: EX_MEM_B <= (MEM_WB_MemRead) ? mem_data_out : MEM_WB_ALUOut;
                        default: EX_MEM_B <= ID_EX_B;
                    endcase
                end
                else begin
                    EX_MEM_B <= ID_EX_B;
                end
                
                EX_MEM_ALUOut   <= alu_out;
                EX_MEM_RegWrite <= ID_EX_RegWrite;
                EX_MEM_MemRead  <= ID_EX_MemRead;
                EX_MEM_MemWrite <= ID_EX_MemWrite;
                EX_MEM_Halt     <= ID_EX_Halt;
                EX_MEM_IR       <= ID_EX_IR;
                EX_MEM_cond     <= cond_out;
            end
        end
    end    
    
        // --- STAGE 4: MEM (clk2) ---
        always @(negedge clk2) begin
            if (!HALTED) begin
            
                MEM_WB_ALUOut   <= EX_MEM_ALUOut;
                MEM_WB_IR       <= EX_MEM_IR;
                MEM_WB_RegWrite <= EX_MEM_RegWrite;
                MEM_WB_MemRead  <= EX_MEM_MemRead; // Needed to know if result comes from LMD or ALU
                MEM_WB_Halt     <= EX_MEM_Halt;
                
            end
        end
    
        // --- STAGE 5: WB (clk1) ---
    always @(posedge clk1) begin
        if (!HALTED&&!TAKEN_BRANCH) begin
            if(MEM_WB_Halt)
                HALTED <= 1;
                      
        end
    end
endmodule

