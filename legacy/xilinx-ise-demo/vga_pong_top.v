
`define SLOW_FACTOR 40
`define HEIGHT 6
`define WIDTH 7

module vga_pong_top(clock40m, reset, right_in_not, left_in_not, c_start_not, a_b_not, down_in_not, up_in_not, vga_hsync , vga_vsync, vga_red0, vga_green0, vga_blue0, vga_red1, vga_green1, vga_blue1);

  input clock40m, reset; // 50 MHz clock and synchronous reset
  input right_in_not, left_in_not, c_start_not, a_b_not, down_in_not, up_in_not; // Gamepad inputs
  output vga_hsync, vga_vsync; // sync signals for monitor
  output vga_red0, vga_green0, vga_blue0, vga_red1, vga_green1, vga_blue1; // Output color signals to the VGA

  wire right_in, left_in, c_start, a_b, down_in, up_in;
  wire clock;
  wire lup, ldn, lhit, rup, rdn, rhit; // debounced signals from the gamepad
  wire [9:0] YPos;	// [0..479] 
  wire [10:0] XPos;	// [0...1287]
  wire Valid, reset_q; // delayed reset
  wire select_d;
  wire [7:0] tcgrom_d, tcgrom_q; // output of the character generation ROM
  wire [5:0] char_selection_d, char_selection_q; // input to the character generation ROM
  reg color;
  wire ball, game_area, l_paddle, r_paddle; // 1 if X,Y correspond to this part of the screen
  wire [3:0] score_l, score_r; // Scores (0 to 9)
  wire [`HEIGHT-1:0] posy, padl, padr;
  wire [`WIDTH-1:0] posx;
  wire [`HEIGHT+3:0] l_diff, r_diff;
  wire vga_hsync_d, vga_hsync_q, vga_vsync_d, vga_vsync_q; 
  wire [1:0] vga_red_d, vga_green_d, vga_blue_d;
  wire [1:0] vga_red_q, vga_green_q, vga_blue_q;
  reg [5:0] char_selection;
  wire l_flash, r_flash;
  
  
  
  assign right_in = ~right_in_not;
  assign left_in = ~left_in_not; 
  assign c_start = ~c_start_not; 
  assign a_b = ~a_b_not; 
  assign down_in = ~down_in_not; 
  assign up_in = ~up_in_not; 
  
  
  // Instantiate the module
dcm50m inst_dcm50m (
    .CLKIN_IN(clock40m), 
    .CLKFX_OUT(clock), 
    .CLK0_OUT()
    );
  
  // Get the inputs from the gamepad
  Gamepad in(clock, ~reset, right_in, left_in, c_start, a_b, down_in, up_in, rhit, lhit, rup, rdn, ldn, lup);
  
  // Instantiate the pong module
  Pong ping(clock, ~reset_q, lup, ldn, lhit, rup, rdn, rhit, posx, posy, padl, padr, score_l, score_r, l_flash, r_flash);

  //--------------------------------------------------
  // Display the correct character in the locations
  // chosen for the title and the scores
  //--------------------------------------------------
  always @(YPos or XPos or score_l or score_r or l_flash or r_flash)
    begin
		////	line 1 
      if (YPos[9:6] == 4'b0000)
        if (XPos[10:6] == 5'b00100)
          char_selection = 6'b010000;//P
        else if (XPos[10:6] == 5'b00101)
          char_selection = 6'b001111;//O
        else if (XPos[10:6] == 5'b00110)
        	 char_selection = 6'b001110;//N
        else if (XPos[10:6] == 5'b00111)
        	 char_selection = 6'b000111;//G
        else if (XPos[10:6] == 5'b01000)
         	char_selection = 6'b100000;//_
        else if (XPos[10:6] == 5'b01001)
         	char_selection = 6'b000111;//G
        else if (XPos[10:6] == 5'b01010)
      	  char_selection = 6'b000001;//A
        else if (XPos[10:6] == 5'b01011)
      	  char_selection = 6'b001101;//M
        else if (XPos[10:6] == 5'b01100)
          char_selection = 6'b000101;//E
        else
          char_selection = 6'b100000;
      ////	line 4 
      else if (YPos[9:6] == 4'b0011)
        if (XPos[10:6] == 5'b00100)
          char_selection = 6'b000110;//F
        else if (XPos[10:6] == 5'b00101)
          char_selection = 6'b010000;//P
        else if (XPos[10:6] == 5'b00110)
        	 char_selection = 6'b000111;//G
        else if (XPos[10:6] == 5'b00111)
        	 char_selection = 6'b000001;//A
        else if (XPos[10:6] == 5'b01000)
         	char_selection = 6'b100000;//
        else if (XPos[10:6] == 5'b01001)
         	char_selection = 6'b000100;//D
        else if (XPos[10:6] == 5'b01010)
      	  char_selection = 6'b010011;//S
        else if (XPos[10:6] == 5'b01011)
      	  char_selection = 6'b010000;//P
        else
          char_selection = 6'b100000;

		////	line 2 
      else if (YPos[9:6] == 4'b0001)
		  if (XPos[10:6] == 5'b00000)
          char_selection = 6'b010111;//W
		  else if (XPos[10:6] == 5'b00001)
          char_selection = 6'b010111;//W
		  else if (XPos[10:6] == 5'b00010)
          char_selection = 6'b010111;//W
        else if (XPos[10:6] == 5'b00011)
      	  char_selection = 6'b101110;//.		
        else if (XPos[10:6] == 5'b00100)
          char_selection = 6'b000100;//D
        else if (XPos[10:6] == 5'b00101)
          char_selection = 6'b010011;//S
        else if (XPos[10:6] == 5'b00110)
        	 char_selection = 6'b010000;//P
        else if (XPos[10:6] == 5'b00111)
        	 char_selection = 6'b000011;//C
        else if (XPos[10:6] == 5'b01000)
         	char_selection = 6'b001111;//O
        else if (XPos[10:6] == 5'b01001)
         	char_selection = 6'b010010;//R
        else if (XPos[10:6] == 5'b01010)
      	  char_selection = 6'b000101;//E
        else if (XPos[10:6] == 5'b01011)
      	  char_selection = 6'b101110;//.
        else if (XPos[10:6] == 5'b01100)
          char_selection = 6'b001001;//I
        else if (XPos[10:6] == 5'b01101)
         	char_selection = 6'b010010;//R			 
        else
          char_selection = 6'b100000;			 
		////	 line 7
      else if (YPos[9:6] == 4'b0110)
		  if (XPos[10:6] == 5'b00000)
          char_selection = 6'b010111;//W
		  else if (XPos[10:6] == 5'b00001)
          char_selection = 6'b010111;//W
		  else if (XPos[10:6] == 5'b00010)
          char_selection = 6'b010111;//W
        else if (XPos[10:6] == 5'b00011)
      	  char_selection = 6'b101110;//.		
        else if (XPos[10:6] == 5'b00100)
          char_selection = 6'b000100;//D
        else if (XPos[10:6] == 5'b00101)
          char_selection = 6'b010011;//S
        else if (XPos[10:6] == 5'b00110)
        	 char_selection = 6'b010000;//P
        else if (XPos[10:6] == 5'b00111)
        	 char_selection = 6'b000011;//C
        else if (XPos[10:6] == 5'b01000)
         	char_selection = 6'b001111;//O
        else if (XPos[10:6] == 5'b01001)
         	char_selection = 6'b010010;//R
        else if (XPos[10:6] == 5'b01010)
      	  char_selection = 6'b000101;//E
        else if (XPos[10:6] == 5'b01011)
      	  char_selection = 6'b101110;//.
        else if (XPos[10:6] == 5'b01100)
          char_selection = 6'b001001;//I
        else if (XPos[10:6] == 5'b01101)
         	char_selection = 6'b010010;//R			 
        else
          char_selection = 6'b100000;
		/// line 5
      else if (YPos[9:6] == 4'b0100)
        if (XPos[10:6] == 5'b00001) 
          char_selection = l_flash ? 6'b100000 : {2'b11, score_l[3:0]};
        else if (XPos[10:6] == 5'b01110)
          char_selection = r_flash ? 6'b100000 : {2'b11, score_r[3:0]};
			////
        else if (XPos[10:6] == 5'b00100)
          char_selection = 6'b010011;//S
        else if (XPos[10:6] == 5'b00101)
          char_selection = 6'b010000;//P
        else if (XPos[10:6] == 5'b00110)
        	 char_selection = 6'b000001;//A
        else if (XPos[10:6] == 5'b00111)
        	 char_selection = 6'b010010;//R
        else if (XPos[10:6] == 5'b01000)
         	char_selection = 6'b010100;//T
        else if (XPos[10:6] == 5'b01001)
         	char_selection = 6'b000001;//A
        else if (XPos[10:6] == 5'b01010)
      	  char_selection = 6'b001110;//N
        else if (XPos[10:6] == 5'b01011)
      	  char_selection = 6'b110011;//3			 
			//// 
        else
          char_selection = 6'b100000;
      else
        char_selection = 6'b100000;
    end

  // Register the output of the character generator
  assign char_selection_d = char_selection;
	
  // Register the output of the tcgrom
  tcgrom tcgrom(.addr({char_selection_q, YPos[5:3]}), .data(tcgrom_d));

  always @(XPos or tcgrom_q)
    begin  	
      case (XPos[5:3])
        3'h0 : color = tcgrom_q[7];
        3'h1 : color = tcgrom_q[6];
        3'h2 : color = tcgrom_q[5];
        3'h3 : color = tcgrom_q[4];
        3'h4 : color = tcgrom_q[3];
        3'h5 : color = tcgrom_q[2];
        3'h6 : color = tcgrom_q[1];
        3'h7 : color = tcgrom_q[0];	 	      	 	      
      endcase 
    end  
    
  //--------------------------------------------------
  // Detect other positions on the screen :
  // the game area, the ball, the paddles
  //--------------------------------------------------
  assign game_area = ((YPos[9:6] == 4'b0100) | (YPos[9:6] == 4'b0011)) &
	             ((XPos[10:8] == 3'b001) | (XPos[10:8] == 3'b010));
  assign ball = (({2'b00, posx}+9'd64)==XPos[10:2]) &
                (({3'b000, posy}+9'd96)==YPos[9:1]);
  assign l_diff = YPos[9:1] - 9'd92  - {2'b00,padl};
  assign l_paddle = ((XPos[10:5] == 6'b000111) &
                    (l_diff[9:3] == 7'd0));
  assign r_diff = YPos[9:1] - 9'd92  - {2'b00,padr};
  assign r_paddle = ((XPos[10:5] == 6'b011000) &
                    (r_diff[9:3] == 7'd0));

  //--------------------------------------------------
  // Assign colors depending on the parts of the screen
  //-------------------------------------------------- 
  assign vga_red_d = {2{(ball | l_paddle | r_paddle)}};
  assign vga_blue_d = {2{color}};
  assign vga_green_d = {2{(game_area & ~ball)}};

  //--------------------------------------------------
  // Call the VGA interface (generates XPos, YPos, valid and the sync signals
  //-------------------------------------------------- 

  sync_gen50 syncVGA( .clk(clock), .CounterX(XPos), .CounterY(YPos), .Valid(Valid),
                      .vga_h_sync(vga_hsync_d), .vga_v_sync(vga_vsync_d));


  assign vga_vsync = vga_vsync_q;
  assign vga_hsync = vga_hsync_q;
  assign vga_red1 = vga_red_q[1];
  assign vga_red0 = vga_red_q[0];
  assign vga_green1 = vga_green_q[1];
  assign vga_green0 = vga_green_q[0];
  assign vga_blue1 = vga_blue_q[1];
  assign vga_blue0 = vga_blue_q[0];

   // Output flops
   DFF #(1) reset_reg (.clk(clock), .en(1'b1), .in(reset), .out(reset_q));
   DFF #(8) tcgrom_reg (.clk(clock), .en(1'b1), .in(tcgrom_d), .out(tcgrom_q));
   DFF #(6) char_selection_reg (.clk(clock), .en(1'b1), .in(char_selection_d), 
   	.out(char_selection_q));
   DFF vga_vsync_reg (.clk(clock), .en(1'b1), .in(vga_vsync_d), .out(vga_vsync_q));
   DFF vga_hsync_reg (.clk(clock), .en(1'b1), .in(vga_hsync_d), .out(vga_hsync_q));
   DFF #(2) vga_red_reg (.clk(clock), .en(1'b1), .in(vga_red_d), .out(vga_red_q));
   DFF #(2) vga_green_reg (.clk(clock), .en(1'b1), .in(vga_green_d), .out(vga_green_q));
   DFF #(2) vga_blue_reg (.clk(clock), .en(1'b1), .in(vga_blue_d), .out(vga_blue_q));  

endmodule