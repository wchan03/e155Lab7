// Wava Chan
// wchan@g.hmc.edu
// Nov. 2025
// Testbench for AddRoundKeyModule

`timescale 1ns/1ns

module testbench_addroundkey();
    //set up test signals
    logic clk, done;
    logic [127:0] a, y, y_exp, roundKey; 

    //instantiate dut
    //AddRoundKey dut(.a(a), .clk(clk), .y(y));
    AddRoundKey dut(.key(a), .roundKey(roundKey), .clk(clk), .y(y));

    always
        begin
            clk = 1; #5;
            clk = 0; #5;
        end
    //   The key and message are 128-bit values packed into an array of 16 bytes as
//   shown below
//        [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
//        [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
//        [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
//        [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3
//
//   Equivalently, the values are packed into four words as given
//        [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]
/////////////////////////////////////////////
    initial //using example from the video
        begin
            done = 0;
            #20;
            a = 128'h6b85d3f040adbb828ad89131cdc42cb3;
            roundKey = 128'ha0fafe1788542cb123a339392a6c7605;
            y_exp = 128'hcb7f2de7c8f99733a97ba808e7a85ab6;
            #20;
            done = 1;

                #20; 
            
            //a = 128'
            //roundKey = 128'
            //y_exp = 128'
            done = 0;
                #20

            a = 128'h046681e5e0cb199a48f8d37a2806264c;
	        roundKey = 128'ha0fafe1788542cb123a339392a6c7605;
	        y_exp = 128'ha49c7ff2689f352b6b5bea43026a5049;
            #20;
            done = 1;

            #20; 
            done = 0;

        end
    
        // wait until done and then check the result
    always @(posedge clk) begin
      if (done) begin
        if (y == y_exp)
            $display("Testbench ran successfully");
        else $display("Error: cyphertext = %h, expected %h",
            y, y_exp);
        //$stop();
      end
    end

endmodule