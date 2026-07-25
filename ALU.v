module ALU(
    input [5:0] opcode,
    input [31:0] A,
    input [31:0] B,
    output reg [31:0] C
);

    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
              SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000, 
              SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
              BNEQZ=6'b001101, BEQZ=6'b001110;
    
    always @(*) begin
        // 1. Default values to prevent Latch Inference
        C = 32'b0;
    

        case(opcode)
            // Arithmetic & Logic
            ADD, ADDI : C = A + B;
            SUB, SUBI : C = A - B;
            MUL       : C = A * B;
            OR        : C = A | B;
            AND       : C = A & B;
            
            // Set Less Than (A < B)
            // Note: 'B > A' works for unsigned, but ensure logic matches MIPS spec
            SLT, SLTI : C = (A < B) ? 32'b1 : 32'b0; 

            // Load/Store Address Calculation (Base + Offset) and New adress calculation
            // This was MISSING in your code
            LW, SW , BNEQZ ,BEQZ    : C = A + B; 


            // Default Case for safety
            default: C = 32'b0;
        endcase
    end        

endmodule
