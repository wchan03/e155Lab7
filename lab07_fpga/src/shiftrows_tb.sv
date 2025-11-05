// Wava Chan
// wchan@g.hmc.edu
// Nov. 2025
// Testbench for AddRoundKeyModule

`timescale 1ns/1ns

module testbench_shiftRows();
    //set up test signals
    logic clk, done;
    logic [127:0] a, y, y_exp; 

    //instantiate dut
    ShiftRows dut(.a(a), .clk(clk), .y(y));

    always
        begin
            clk = 1; #5;
            clk = 0; #5;
        end
    
    initial 
        begin
            a = 128'h6c0edb347caa45ed33249ca502834bfb; //round 7 from AES animation video
            y_exp = 128'h6caa9cfb7c244b343383dbed020e45a5;

                #20; 
            
            a = 128'hfac3f2ef8d133951d67df3f36cb5e4ed; //round 8 example
            y_exp = 128'hfa13f3ed8d7de4efd6b5f2516cc339f3;

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