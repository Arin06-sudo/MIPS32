
module reg_bank(input [4:0] addr_wr,
                input [4:0] addr_rd1, 
                input [4:0] addr_rd2, 
                input clk, 
                input wr,
                input [31:0] Data_in,
                output reg [31:0] Data_out1,
                output reg [31:0] Data_out2);

    reg [31:0] Reg [0:31];
    
    integer k;
    initial begin
        // Corrected limit: k < 32 to include Reg[31]
        for (k=0; k<32; k=k+1) 
            Reg[k] = k; 
        
        // Ensure Reg[0] is strictly 0
        Reg[0] = 32'b0;
    end
        
    always@(posedge clk) begin
        // CRITICAL FIX: Prevent writing to Register 0
        if(wr && addr_wr != 5'b00000)
            Reg[addr_wr] <= Data_in;
    end
    
    always@(*) begin
        // Optional safety: Force read of Reg[0] to be 0
        Data_out1 = (addr_rd1 == 0) ? 32'b0 : Reg[addr_rd1];
        Data_out2 = (addr_rd2 == 0) ? 32'b0 : Reg[addr_rd2];
    end
          
endmodule
