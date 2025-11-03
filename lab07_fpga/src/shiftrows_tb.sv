// Wava Chan
// wchan@g.hmc.edu
// Nov. 2025
// Testbench for AddRoundKeyModule

`timescale 1ns/1ns

module testbench_shiftRows();
    //set up test signals
    logic clk, done;
    logic [127:0] roundKey, a, y, y_exp; 

    //instantiate dut
    ShiftRows dut(.key(a), .roundKey(roundKey) .clk(clk), .y(y));

    always
        begin
            clk = 1; #5;
            clk = 0; #5;
        end
    
    initial 
        begin
            a = 128'
            roundKey = 128'
            y_exp = 128'

                #20; 
            
            a = 128'
            roundKey = 128'
            y_exp = 128'

            done = 1;

        end
    
        // wait until done and then check the result
    always @(posedge clk) begin
      if (done) begin
        if (y == y_exp)
            $display("Testbench ran successfully");
        else $display("Error: cyphertext = %h, expected %h",
            y, y_exp);
        $stop();
      end
    end
endmodule 