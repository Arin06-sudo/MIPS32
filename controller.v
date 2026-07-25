
module controller(
    input  [5:0] Opcode,
    output reg   RegWrite,
    output reg   MemRead,
    output reg   MemWrite,
    output reg   Branch,
    output reg   ALUSrc,   // 0 = RegB, 1 = Immediate
    output reg   Halt
    // Note: ALUOp is often a separate signal, but for this simple ISA 
    // we can pass the Opcode down to the ALU directly or decode it there.
);

    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
              SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000, 
              SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
              BNEQZ=6'b001101, BEQZ=6'b001110;

    always @(*) begin
        // Defaults
        RegWrite = 0; MemRead = 0; MemWrite = 0; 
        Branch = 0; ALUSrc = 0; Halt = 0;

        case(Opcode)
            ADD, SUB, AND, OR, SLT, MUL: begin // R-Type
                RegWrite = 1;
                ALUSrc   = 0;
            end
            ADDI, SUBI, SLTI: begin // Immediate ALU
                RegWrite = 1;
                ALUSrc   = 1;
            end
            LW: begin
                RegWrite = 1;
                MemRead  = 1;
                ALUSrc   = 1;
            end
            SW: begin
                MemWrite = 1;
                ALUSrc   = 1;
            end
            BEQZ, BNEQZ: begin
                Branch   = 1;
                ALUSrc   = 0;
            end
            HLT: begin
                Halt     = 1;
            end
        endcase
    end
endmodule

