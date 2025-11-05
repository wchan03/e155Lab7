// Wava Chan
// wchan@g.hmc.edu
// Nov. 2025
// edited started code provided by E155
/////////////////////////////////////////////
// aes
//   Top level module with SPI interface and SPI core
/////////////////////////////////////////////

module aes(input  logic clk,
           input  logic sck, 
           input  logic sdi,
           output logic sdo,
           input  logic load,
           output logic done);
                    
    logic [127:0] key, plaintext, cyphertext;
            
    aes_spi spi(sck, sdi, sdo, done, key, plaintext, cyphertext);   
    aes_core core(clk, load, key, plaintext, done, cyphertext);
endmodule

/////////////////////////////////////////////
// aes_spi
//   SPI interface.  Shifts in key and plaintext
//   Captures ciphertext when done, then shifts it out
//   Tricky cases to properly change sdo on negedge clk
/////////////////////////////////////////////

module aes_spi(input  logic sck, 
               input  logic sdi,
               output logic sdo,
               input  logic done,
               output logic [127:0] key, plaintext,
               input  logic [127:0] cyphertext);

    logic         sdodelayed, wasdone;
    logic [127:0] cyphertextcaptured;
               
    // assert load
    // apply 256 sclks to shift in key and plaintext, starting with plaintext[127]
    // then deassert load, wait until done
    // then apply 128 sclks to shift out cyphertext, starting with cyphertext[127]
    // SPI mode is equivalent to cpol = 0, cpha = 0 since data is sampled on first edge and the first
    // edge is a rising edge (clock going from low in the idle state to high).
    always_ff @(posedge sck)
        if (!wasdone)  {cyphertextcaptured, plaintext, key} = {cyphertext, plaintext[126:0], key, sdi};
        else           {cyphertextcaptured, plaintext, key} = {cyphertextcaptured[126:0], plaintext, key, sdi}; 
    
    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
        sdodelayed = cyphertextcaptured[126];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? cyphertext[127] : sdodelayed;
endmodule

/////////////////////////////////////////////
// aes_core
//   top level AES encryption module
//   when load is asserted, takes the current key and plaintext
//   generates cyphertext and asserts done when complete 11 cycles later
// 
//   See FIPS-197 with Nk = 4, Nb = 4, Nr = 10
//
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

module aes_core(input  logic         clk, 
                input  logic         load,
                input  logic [127:0] key, 
                input  logic [127:0] plaintext, 
                output logic         done, 
                output logic [127:0] cyphertext);

    //set up intermediate logic
    logic [127:0] rk_in, rk_out, roundKey;
	  logic [7:0] rcon = 8'h01; 
    logic [127:0] temptext, y0, y1, y2, y3, a0, a1, a2, a3;
    int counter;



    //set up FSM
    typedef enum logic [7:0] {idle, ARK0, ARK0Delay, SB1, SB1Delay, SR1, SR1Delay, MC1, MC1Delay, ARK1, ARK1Delay, SB2, SB2Delay, SR2, SR2Delay, ARK2, ARK2Delay, finished}
    statetype;
      statetype state, nextstate; //TODO delay states for each state?
	
	//state register
    always_ff @(posedge clk) begin
      if (load)  state <= idle;
      else        state <= nextstate;
	end

    always_comb begin
      case(state)
        idle: begin//reset state
			  nextstate = ARK0;
        end
        ARK0: nextstate = ARK0Delay;
        ARK0Delay: begin
          nextstate = SB1;
        end
        SB1: nextstate = SB1Delay;
        SB1Delay: begin
          nextstate = SR1;
        end
        SR1: nextstate = SR1Delay;
        SR1Delay: begin
          nextstate = MC1;
        end
        MC1: nextstate = MC1Delay;
        MC1Delay: begin
          nextstate = ARK1;
        end
        ARK1: nextstate = ARK1Delay;
        ARK1Delay: begin //TODO unsure of this logic
          if(counter < 10) nextstate = SB1; //loop if less than 10 rounds
          else nextstate = SB2; //move onto final round
        end
        SB2: begin
          nextstate = SB2Delay;
        end
        SB2Delay: begin
          nextstate = SR2;
        end
        SR2: nextstate = SR2Delay;
        SR2Delay: begin
          nextstate = ARK2;
        end
        ARK2: nextstate = ARK2Delay;
        ARK2Delay: begin
          nextstate = finished;
        end
        finished: begin
			nextstate = finished;
		end
        default: nextstate = idle;
      endcase
	 end

    //assign output logic
    always_ff@(posedge clk) begin
      case(state)
        idle: begin//reset state
			    counter <= 0;
          roundKey <= plaintext; //input to round 1 = plaintext + key
          a3 <= key;
        end
        ARK0: begin
          counter <= counter + 1;
		      //rk_in <= key; //initial roundKey calculated with input key
          //roundKey <= rk_out;
          //a3 <= key; //assign input into AddRoundKey
        end
        ARK0Delay: begin
          //a3 <= key;
          //roundKey <= rk_out;
        end
        SB1: begin
          a0 <= y3; //output of AddRoundKey -> input of SubBytes
        end
        SB1Delay: begin
        end
        SR1: begin
          a1 <= y0; //output of SubBytes -> input of ShiftRows
        end
        MC1: begin
          a2 <= y1; //output of ShiftRows -> input of mixcolumns
        end
        ARK1: begin
          counter <= counter + 1; //TODO should this happen before or after rcon calcs?
          //rcon calculations
          if(counter == 8) rcon <= 8'h1b;
          //else if(counter == 10) rcon <= 8'h36;
          else rcon <= rcon *2;
          //calculate next round key
          rk_in <= roundKey; //old out should be new in 
          roundKey <= rk_out;
          //a3 <= y2; //output of mixcolumns -> input of AddRoundKey
        end
        ARK1Delay: begin
          a3 <= y2; //output of mixcolumns -> input of AddRoundKey
        end
        SB2: begin
          a0 <= y3; //output of RoundKey -> input of SubBytes
        end
        SB2Delay: begin
        end
        SR2: begin
          a2 <= y0;
        end
        ARK2: begin
          counter <= counter + 1;
          rk_in <= roundKey; //final round key
		      roundKey <= rk_out;
	        rcon = 7'h36;
          a3 <= y2;
        end
        finished: begin
           //done <= 1;
           temptext <= y3; //output of AddRoundKey as our final text value
           //TODO : assign cyphertext
        end
      endcase
	 end


    //modules

    //KeyExpansion ke(key, clk, rk1, rk2, rk3, rk4, rk5, rk6, rk7, rk8, rk9, rk10); //can't calculate them all at once
    RoundKey rk(.inputKey(rk_in), .rcon(rcon), .clk(clk), .nextKey(rk_out)); //TODO: rcon might not work out for u queen
    SubBytes sb(.a(a0), .clk(clk), .y(y0));
    ShiftRows sr(.a(a1), .clk(clk), .y(y1));
    mixcolumns mc(.a(a2), .y(y2));
	  AddRoundKey ark(.key(a3), .roundKey(roundKey), .clk(clk), .y(y3));

    //assert done, assign cyphertext
    assign done = (state == finished);
    assign cyphertext = temptext; 

    /*
    TODO: questions
    1. do i need a delay state for every function?
    2. how do i arrainge the variables?
    */    
endmodule

/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Combinational version which is mapped to LUTs (logic cells)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////

module sbox(input  logic [7:0] a,
            output logic [7:0] y);
            
  // sbox implemented as a ROM
  // This module is combinational and will be inferred using LUTs (logic cells)
  logic [7:0] sbox[0:255];

  initial   $readmemh("sbox.txt", sbox);
  assign y = sbox[a];
endmodule

/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Synchronous version which is mapped to embedded block RAMs (EBR)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////
module sbox_sync(
	input		logic [7:0] a,
	input	 	logic 			clk,
	output 	logic [7:0] y);
            
  // sbox implemented as a ROM
  // This module is synchronous and will be inferred using BRAMs (Block RAMs)
  logic [7:0] sbox [0:255];

  initial   $readmemh("sbox.txt", sbox);
	
	// Synchronous version
	always_ff @(posedge clk) begin
		y <= sbox[a];
	end
endmodule

/////////////////////////////////////////////
// mixcolumns
//   Even funkier action on columns
//   Section 5.1.3, Figure 9
//   Same operation performed on each of four columns
/////////////////////////////////////////////

module mixcolumns(input  logic [127:0] a,
                  output logic [127:0] y);

  mixcolumn mc0(a[127:96], y[127:96]);
  mixcolumn mc1(a[95:64],  y[95:64]);
  mixcolumn mc2(a[63:32],  y[63:32]);
  mixcolumn mc3(a[31:0],   y[31:0]);
endmodule

/////////////////////////////////////////////
// mixcolumn
//   Perform Galois field operations on bytes in a column
//   See EQ(4) from E. Ahmed et al, Lightweight Mix Columns Implementation for AES, AIC09
//   for this hardware implementation
/////////////////////////////////////////////

module mixcolumn(input  logic [31:0] a,
                 output logic [31:0] y);
                      
        logic [7:0] a0, a1, a2, a3, y0, y1, y2, y3, t0, t1, t2, t3, tmp;
        
        assign {a0, a1, a2, a3} = a;
        assign tmp = a0 ^ a1 ^ a2 ^ a3;
    
        galoismult gm0(a0^a1, t0);
        galoismult gm1(a1^a2, t1);
        galoismult gm2(a2^a3, t2);
        galoismult gm3(a3^a0, t3);
        
        assign y0 = a0 ^ tmp ^ t0;
        assign y1 = a1 ^ tmp ^ t1;
        assign y2 = a2 ^ tmp ^ t2;
        assign y3 = a3 ^ tmp ^ t3;
        assign y = {y0, y1, y2, y3};    
endmodule

/////////////////////////////////////////////
// galoismult
//   Multiply by x in GF(2^8) is a left shift
//   followed by an XOR if the result overflows
//   Uses irreducible polynomial x^8+x^4+x^3+x+1 = 00011011
/////////////////////////////////////////////

module galoismult(input  logic [7:0] a,
                  output logic [7:0] y);

    logic [7:0] ashift;
    
    assign ashift = {a[6:0], 1'b0};
    assign y = a[7] ? (ashift ^ 8'b00011011) : ashift;
endmodule



//my functions

module SubBytes(input logic [127:0] a,
                input logic clk,
                output logic [127:0] y);
  //apply sbox_sync to every byte
  sbox_sync b0(a[7:0], clk, y[7:0]);
  sbox_sync b1(a[15:8], clk, y[15:8]);
  sbox_sync b2(a[23:16], clk, y[23:16]);
  sbox_sync b3(a[31:24], clk, y[31:24]);
  sbox_sync b4(a[39:32], clk, y[39:32]);
  sbox_sync b5(a[47:40], clk, y[47:40]);
  sbox_sync b6(a[55:48], clk, y[55:48]);
  sbox_sync b7(a[63:56], clk, y[63:56]);
  sbox_sync b8(a[71:64], clk, y[71:64]);
  sbox_sync b9(a[79:72], clk, y[79:72]);
  sbox_sync b10(a[87:80], clk, y[87:80]);
  sbox_sync b11(a[95:88], clk, y[95:88]);
  sbox_sync b12(a[103:96], clk, y[103:96]);
  sbox_sync b13(a[111:104], clk, y[111:104]);
  sbox_sync b14(a[119:112], clk, y[119:112]);
  sbox_sync b15(a[127:120], clk, y[127:120]);

endmodule

module ShiftRows(input logic [127:0] a,
                input logic clk,
                output logic [127:0] y);
  // to shift rows
  // move front byte at row 0 to the back 0 times
  // move front byte at row 1 to the back 1 times
  // so on for rows 2 and 3
  // row 0: b0, b4, b8, b12 (as is)
  logic [7:0] b0, b1, b2, b3, b4, b5, b6, b7, b8;
  logic [7:0] b9, b10, b11, b12, b13, b14, b15;
  assign y[127:120] = a[127:120];
  assign y[95:88] = a[95:88];
  assign y[63:56] = a[63:56];
  assign y[31:24] = a[31:24]; 

  // row 1: b1, b5, b9. b13
  // should be: b5, b9, b13, b1
  assign y[119:112] = a[87:80];
  assign y[87:80] = a[55:48];
  assign y[55:48] = a[23:16];
  assign y[23:16] = a[119:112];
  
  // row 2: b2, b6, b10, b14
  // should be: b10, b14, b2, b6
  assign y[111:104] = a[47:40];
  assign y[79:72] = a[15:8];
  assign y[47:40] = a[111:104];
  assign y[15:8] = a[79:72];

  // row 3: b3, b7, b11, b15
  // should be: b15, b3, b7, b11
  assign y[103:96] = a[7:0];
  assign y[71:64] = a[103:96];
  assign y[39:32] = a[71:64];
  assign y[7:0] = a[39:32];

endmodule


module AddRoundKey(input logic [127:0] key, roundKey,
                   input logic clk,
                   output logic [127:0] y);
  assign y = key ^ roundKey; 
endmodule


module RoundKey(input logic [127:0] inputKey,
		            input logic [7:0] rcon, 
                input logic clk,
                output logic [127:0] nextKey);
  //unpack input key:
  logic [31:0] col0, col1, col2, col3;
  assign col3 = inputKey[31:0];
  assign col2 = inputKey[63:32];
  assign col1 = inputKey[95:64];
  assign col0 = inputKey[127:96];

  //setup output key logic
  logic [31:0] outCol0, outCol1, outCol2, outCol3;
  logic [31:0] oc0i; //out column 0 intermediate

  // calculate column 4
  logic [31:0] sbrc; //SubByteRotatedColumn
  RotWord oc0(col3, clk, oc0i); //rotate column 3 from input key
  subBytesColumn sbc(oc0i, clk, sbrc); // subBytes on the rotated col

  // subBytes(RotColumn) + RConCol1 + col0
  // add every thing individually
  assign outCol0[31:24] = sbrc[31:24] ^ rcon ^ col0[31:24]; //TODO: this only works for the first roundKey
  assign outCol0[23:0] = sbrc[23:0] ^ col0[23:0];
  
  assign outCol1 = outCol0 ^ col1;
  assign outCol2 = outCol1 ^ col2;
  assign outCol3 = outCol2 ^ col3;

  //get it all together
  assign nextKey = {outCol0, outCol1, outCol2, outCol3}; //TODO: correct syntax?? will this work?


endmodule

module RotWord(input logic [31:0] a,
              input logic clk,
              output logic [31:0] y);
  //move top of column to bottom
  assign y[7:0] = a[31:24];
  assign y[15:8] = a[7:0];
  assign y[23:16] = a[15:8];
  assign y[31:24] = a[23:16];
endmodule

module subBytesColumn(input logic [31:0] a,
                      input logic clk,
                      output logic [31:0] y);
  sbox_sync b0(a[7:0], clk, y[7:0]);
  sbox_sync b1(a[15:8], clk, y[15:8]);
  sbox_sync b2(a[23:16], clk, y[23:16]);
  sbox_sync b3(a[31:24], clk, y[31:24]);
endmodule