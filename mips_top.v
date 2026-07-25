
module mips_top(input clk1, input clk2, input reset);

    wire [5:0] opcode;
    wire reg_write, mem_read, mem_write, branch, alu_src, halt;

    // Instantiate Controller
    controller ctrl (
        .Opcode(opcode),
        .RegWrite(reg_write),
        .MemRead(mem_read),
        .MemWrite(mem_write),
        .Branch(branch),
        .ALUSrc(alu_src),
        .Halt(halt)
    );

    // Instantiate Datapath
    datapath dp (
        .clk1(clk1), 
        .clk2(clk2), 
        .reset(reset),
        .Opcode_out(opcode), // Output from Datapath (IF/ID register) to Controller
        .Ctrl_RegWrite(reg_write),
        .Ctrl_MemRead(mem_read),
        .Ctrl_MemWrite(mem_write),
        .Ctrl_Branch(branch),
        .Ctrl_ALUSrc(alu_src),
        .Ctrl_Halt(halt)
    );

endmodule
