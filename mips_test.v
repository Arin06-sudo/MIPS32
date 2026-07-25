
module mips_test;

    reg clk1,clk2,reset;
  
  
    mips_top m1 (.clk1(clk1),.clk2(clk2),.reset(reset));
    
    initial begin
        reset = 1;
    end
    
    initial begin
        clk1 = 0; clk2 = 0;
        forever
            begin
                #5 clk1 = 1; #5 clk1 = 0;
                #5 clk2 = 1; #5 clk2 = 0;
            end
     end
     
    initial begin
     
        #20 reset = 0;
        
        #6000 $finish;
        
    end
    
endmodule
