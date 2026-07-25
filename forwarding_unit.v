
module forwarding_unit(
    input[4:0] Rs1,
    input[4:0] Rs2,
    input[4:0] Rd_mem,
    input[4:0] Rd_wb,
    input mem_regwrite,
    input wb_regwrite,
    output reg [1:0] Fwda,Fwdb
);

    always@(*) begin // for all types of operation
        if(mem_regwrite&&Rd_mem!=5'b0&&Rd_mem==Rs1) 
            Fwda = 2'b10;
        else if(wb_regwrite&&Rd_wb!=5'b0&&Rd_wb==Rs1)
            Fwda = 2'b01;
        else
            Fwda = 2'b00;
    end
    
    always@(*) begin // for R-R operation
        if(mem_regwrite&&Rd_mem!=5'b0&&Rd_mem==Rs2) 
            Fwdb = 2'b10;
        else if(wb_regwrite&&Rd_wb!=5'b0&&Rd_wb==Rs2)
            Fwdb = 2'b01;
        else
            Fwdb = 2'b00;

    end
endmodule    
