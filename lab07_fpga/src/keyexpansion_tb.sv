// Wava Chan
// wchan@g.hmc.edu
// Nov. 2025
// Testbench for AddRoundKeyModule

`timescale 1ns/1ns

module testbench_keyExpansion();
    //set up test signals
    logic clk, done;
    logic [127:0] key, nextKey; 
    logic [7:0] rcon;
    logic [127:0] rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10;
    logic [127:0] rk1_exp, rk2_exp, rk3_exp, rk4_exp, rk5_exp, rk6_exp, rk7_exp, rk8_exp, rk9_exp, rk10_exp;

    //instantiate dut
    RoundKey dut(.inputKey(key), .rcon(rcon), .clk(clk), .nextKey(nextKey));
    always
        begin
            clk = 1; #5;
            clk = 0; #5;
        end
    
    // using example 1 from https://www.kavaliro.com/wp-content/uploads/2014/03/AES.pdf
    initial 
        begin
            /*
	        rk1_exp = 128'hE232FCF191129188B159E4E6D679A293;
            rk2_exp = 128'h56082007C71AB18F76435569A03AF7FA;
            rk3_exp = 128'hD2600DE7157ABC686339E901C3031EFB;
	        rk4_exp = 128'hA11202C9B468BEA1D75157A01452495B;
            rk5_exp = 128'hB1293B3305418592D210D232C6429B69;
            rk6_exp = 128'hBD3DC2B7B87C47156A6C9527AC2E0E4E;
            rk7_exp = 128'hCC96ED1674EAAA031E863F24B2A8316A;
            rk8_exp = 128'h8E51EF21FABB4522E43D7A0656954B6C;
            rk9_exp = 128'hBFE2BF904559FAB2A16480B4F7F1CBD8;
            rk10_exp = 128'h28FDDEF86DA4244ACCC0A4FE3B316F26;
            */
            rk1_exp = 128'ha0fafe1788542cb123a339392a6c7605;
            rk2_exp = 128'hf2c295f27a96b9435935807a7359f67f;
            rk3_exp = 128'h3d80477d4716fe3e1e237e446d7a883b;
            rk4_exp = 128'hef44a541a8525b7fb671253bdb0bad00;
            rk5_exp = 128'hd4d1c6f87c839d87caf2b8bc11f915bc;
            rk6_exp = 128'h6d88a37a110b3efddbf98641ca0093fd;
            rk7_exp = 128'h4e54f70e5f5fc9f384a64fb24ea6dc4f;
            rk8_exp = 128'head27321b58dbad2312bf5607f8d292f;
            rk9_exp = 128'hac7766f319fadc2128d12941575c006e;
            rk10_exp = 128'hd014f9a8c9ee2589e13f0cc8b6630ca6;



        //key = 128'h5468617473206d79204b756e67204675;
        key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
	    rcon = 8'h01;
		#20;
	    assert(nextKey == rk1_exp) $display ("round 1 key correct");
       		else $display("Error: round key 1 = %h, expected %h", nextKey, rk1_exp);
		
		#20;

	    key = nextKey; //ensure no error propagation
	    rcon = 8'h02;
		#20;
	    assert(nextKey == rk2_exp) $display ("round 2 key correct");
       		else $display("Error: round key 2 = %h, expected %h", nextKey, rk2_exp);
		
		#20;

	    key = nextKey;
	    rcon = 8'h04;
		#20;
	    assert(nextKey == rk3_exp) $display ("round 3 key correct");
       		else $display("Error: round key 3 = %h, expected %h", nextKey, rk3_exp);
		
                #20; 

	    key = nextKey;
	    rcon = 8'h08;
		#20;
	    assert(nextKey == rk4_exp) $display ("round 4 key correct");
       		else $display("Error: round key 4 = %h, expected %h", nextKey, rk4_exp);
		
                #20; 

	    key = nextKey;
	    rcon = 8'h10;
		#20;
	    assert(nextKey == rk5_exp) $display ("round 5 key correct");
       		else $display("Error: round key 5 = %h, expected %h", nextKey, rk5_exp);
		
                #20;

	    key = nextKey;
	    rcon = 8'h20;
		#20;
	    assert(nextKey == rk6_exp) $display ("round 6 key correct");
       		else $display("Error: round key 6 = %h, expected %h", nextKey, rk6_exp);
		
                #20;

	    key = nextKey;
	    rcon = 8'h40;
		#20;
	    assert(nextKey == rk7_exp) $display ("round 7 key correct");
       		else $display("Error: round key 7 = %h, expected %h", nextKey, rk7_exp);
		
                #20;

	    key = nextKey;
	    rcon = 8'h80;
		#20;
	    assert(nextKey == rk8_exp) $display ("round 8 key correct");
       		else $display("Error: round key 8 = %h, expected %h", nextKey, rk8_exp);
		
                #20;

	    key = nextKey;
	    rcon = 8'h1b;
		#20;
	    assert(nextKey == rk9_exp) $display ("round 9 key correct");
       		else $display("Error: round key 9 = %h, expected %h", nextKey, rk9_exp);
		
                #20;

	    key = nextKey;
	    rcon = 8'h36;
		#20;
	    assert(nextKey == rk10_exp) $display ("round 10 key correct");
       		else $display("Error: round key 10 = %h, expected %h", nextKey, rk10_exp);
		
                #20;
        

            done = 1;

        end
    
        // wait until done and then check the result
/*
    always @(posedge clk) begin
      if (done) begin
        if (nextKey == rk1_exp)
            $display("round 1 key correct");
        else $display("Error: round key 1 = %h, expected %h",
            rk1, rk1_exp);
        if (rk2 == rk2_exp)
            $display("round 2 key correct");
        else $display("Error: round key 2 = %h, expected %h",
            rk2, rk2_exp);
        if (rk3 == rk3_exp)
            $display("round 3 key correct");
        else $display("Error: round key 3 = %h, expected %h",
            rk3, rk3_exp);
        if (rk4 == rk4_exp)
            $display("round 4 key correct");
        else $display("Error: round key 4 = %h, expected %h",
            rk4, rk4_exp);
        if (rk5 == rk5_exp)
            $display("round 5 key correct");
        else $display("Error: round key 5 = %h, expected %h",
            rk5, rk5_exp);
        if (rk6 == rk6_exp)
            $display("round 6 key correct");
        else $display("Error: round key 6 = %h, expected %h",
            rk6, rk6_exp);
        if (rk7 == rk7_exp)
            $display("round 7 key correct");
        else $display("Error: round key 7 = %h, expected %h",
            rk7, rk7_exp);
        if (rk8 == rk8_exp)
            $display("round 8 key correct");
        else $display("Error: round key 8 = %h, expected %h",
            rk8, rk8_exp);
        if (rk9 == rk9_exp)
            $display("round 9 key correct");
        else $display("Error: round key 9 = %h, expected %h",
            rk9, rk9_exp);
        if (rk10 == rk10_exp)
            $display("round 10 key correct");
        else $display("Error: round key 10 = %h, expected %h",
            rk10, rk10_exp);
        $stop();
      end
    end
*/
endmodule 