//--------------------------------------
// Pong game : factored state machine
//--------------------------------------
`define SLOW_FACTOR 25
//--------------------------------------
// Define contact on the paddle
//--------------------------------------
`define TOP 2'b10
`define BOTTOM 2'b00
`define MID 2'b01
//--------------------------------------
// Define vertical velocity
//--------------------------------------
`define UP 2'b10
`define DN 2'b00
`define HOR 2'b01
//--------------------------------------
// Define game size
//--------------------------------------
`define WIDTH 7
`define HEIGHT 6
//--------------------------------------
// Define flip-flop
//--------------------------------------
module DFF(clk, en, in, out);
  parameter n = 1 ;  // width
  input clk, en ;
  input [n-1:0] in ;
  output [n-1:0] out ;
  reg [n-1:0] out ;
  
  always @(posedge clk)
    if (en==1)
      out = in ;
endmodule

//--------------------------------------
// Get the x_position of the ball
//--------------------------------------
module Ball_pos_x(clk, slow_clk, vel_x, hit, serve, ball_x) ;
  input clk, slow_clk, vel_x, serve, hit;
  output [`WIDTH-1:0] ball_x ;

//  reg [`WIDTH-1:0] next_x1 ;
  wire [`WIDTH-1:0] next_x, next_x1 ;
  wire hit;

  // instantiate state register
  DFF #(`WIDTH) ball_state(clk, slow_clk, next_x, ball_x);
  
  // next_state equations
  // this is combinational logic
  
  assign next_x1 = ((~hit & ~vel_x) | (hit & vel_x)) ? (ball_x-1) : (ball_x+1);
  
  // add reset
  assign next_x = serve ? {1'b1, {(`WIDTH-1){1'b0}}} : next_x1 ;
  
endmodule

//--------------------------------------
// Get the y_position of the ball
//--------------------------------------
module Ball_pos_y(clk, slow_clk, vel_y, serve, boundary, ball_y) ;

  input clk, slow_clk, serve, boundary ;
  input [1:0] vel_y ;
  output [`HEIGHT-1:0] ball_y ;
  
  reg [`HEIGHT-1:0] next_y1;
  wire [`HEIGHT-1:0] next_y;
  
  // instantiate state registers
  DFF #(`HEIGHT) ball_state(clk, slow_clk, next_y, ball_y);
  
  // next-state equations
  // this is combinational logic

  always @(vel_y or boundary or ball_y) begin
    case({vel_y, boundary})
      {`DN,1'b0} : next_y1 = ball_y + 1 ;
      {`DN,1'b1} : next_y1 = ball_y - 1 ;
      {`UP,1'b0} : next_y1 = ball_y - 1 ;
      {`UP,1'b1} : next_y1 = ball_y + 1 ;
      default : next_y1 = ball_y;
    endcase
  end
  
  // add reset
  assign next_y = serve ? {1'b1, {(`HEIGHT-1){1'b0}}} : next_y1 ;
endmodule

//--------------------------------------
// Get the x_velocity of the ball
//--------------------------------------
module Velocity_x(clk, slow_clk, hit, serve, vel_x) ;
  input clk, slow_clk, hit, serve ;
  output vel_x;
  wire next_vx1, next_vx;
  
  DFF #(1) ball_state(clk, slow_clk, next_vx, vel_x);
  
  assign next_vx1 = hit ? ~vel_x : vel_x;
  assign next_vx = serve ? 1'b1 : next_vx1;
endmodule


//--------------------------------------
// Get the y_velocity of the ball
//--------------------------------------

module Velocity_y(clk, slow_clk, serve, contact_pt, x_boundary, y_boundary, vel_y);
  input clk, slow_clk, serve, x_boundary, y_boundary;
  input [1:0] contact_pt;
  output [1:0] vel_y ;
  
  wire [1:0] next_vy;
  reg [1:0] next_vy1, next_vy2;
  
  DFF #(2) ball_state(clk, slow_clk, next_vy, vel_y);

  always @(contact_pt or vel_y or x_boundary) begin
    case({contact_pt, x_boundary})
      {`TOP,1'b1} : next_vy1 = (vel_y == `UP) ? vel_y : (vel_y+1);
      {`BOTTOM,1'b1} : next_vy1 = (vel_y == `DN) ? vel_y : (vel_y-1);
      default : next_vy1 = vel_y;
    endcase
  end
  
  always @(next_vy1 or y_boundary) begin
    case({next_vy1, y_boundary})
      {`UP, 1'b1} : next_vy2 = `DN;
      {`DN, 1'b1} : next_vy2 = `UP;
      default : next_vy2 = next_vy1;
    endcase
  end
  
  assign next_vy = serve ? `HOR : next_vy2;
endmodule


//--------------------------------------
// Get the position of the paddle
//--------------------------------------

module Paddle(clk, slow_clk, serve, mv_up, mv_dn, pad) ;

  input clk, slow_clk, mv_up,mv_dn, serve;
  output [`HEIGHT-1:0] pad;
  
  reg [`HEIGHT-1:0] next_p1;
  wire [`HEIGHT-1:0] next_p;
  wire top, bottom;
  
  DFF #(`HEIGHT) paddle_pos(clk, slow_clk, next_p, pad);
  
  assign top = (pad=={`HEIGHT{1'b1}});
  assign bottom = (pad=={`HEIGHT{1'b0}});
  
  always @(mv_up or mv_dn or bottom or top or pad) begin
    case({mv_up,mv_dn})
      2'b01 : next_p1 = bottom ? pad : (pad+1);
      2'b10 : next_p1 = top ? pad : (pad-1);
      default : next_p1 = pad;
    endcase
  end
  
  assign next_p = serve ? {1'b1, {(`HEIGHT-1){1'b0}}} : next_p1;
endmodule

//--------------------------------------
// Counter module - arbitrary width
//--------------------------------------
module Counter (clk, rst, en, count);
  parameter n=3;
  input clk, rst, en;
  output [n-1:0] count;

  wire [n-1:0] next_count, count;

  DFF #(n) count_reg(clk, en, next_count, count);

  assign next_count = rst ? {n{1'b0}} : (count+1);

endmodule

//--------------------------------------
// Top-level pong game
//--------------------------------------
module Pong (clk, reset, lup, ldn, lhit, rup, rdn, rhit, ball_x, ball_y, l_pad, r_pad, score_l, score_r, l_flash, r_flash);

  input clk, reset, lup, ldn, lhit, rup, rdn, rhit;
  output [3:0] score_l, score_r;
  output [`WIDTH-1:0] ball_x;
  output [`HEIGHT-1:0] ball_y, l_pad, r_pad;
  output l_flash, r_flash;

  wire slow_clk, l_won, r_won;
  wire vel_x, won;
  wire [1:0] vel_y;
  wire padonball_l, padonball_r, hit, incr_l, incr_r, miss, x_boundary, y_boundary;
  wire [1:0] contact_pt_l, contact_pt_r, contact_pt;
  wire [`SLOW_FACTOR-1:0] count;

  // Divide the clock to get a slower signal
  Counter #(`SLOW_FACTOR) divider(clk, reset, 1'b1, count);
  assign slow_clk = (count[(`SLOW_FACTOR-4):0]=={(`SLOW_FACTOR-3){1'b0}});
  assign l_flash = l_won & count[`SLOW_FACTOR-1];
  assign r_flash = r_won & count[`SLOW_FACTOR-1];
  
  // instantiate the modules
  Ball_pos_x pos_x(clk, slow_clk, vel_x, hit, miss | won, ball_x);
  Ball_pos_y pos_y(clk, slow_clk, vel_y, miss | won, y_boundary, ball_y);
  Velocity_x veloc_x(clk, slow_clk, hit, miss | won, vel_x);
  Velocity_y veloc_y(clk, slow_clk, miss | won, contact_pt, x_boundary, y_boundary, vel_y);
  Paddle left_pad(clk, slow_clk, reset, lup, ldn, l_pad);
  Paddle right_pad(clk, slow_clk, reset, rup, rdn, r_pad);

  assign hit = ((ball_x == {`WIDTH{1'b1}}) & rhit & padonball_r) | 
               ((ball_x == {`WIDTH{1'b0}}) & lhit & padonball_l) ;
  assign incr_l = ~hit & (ball_x == {`WIDTH{1'b1}});
  assign incr_r = ~hit & (ball_x == {`WIDTH{1'b0}});
  assign miss = reset | incr_l | incr_r;
  assign l_won = (score_l == 4'd9);
  assign r_won = (score_r == 4'd9);
  assign won = l_won | r_won;
  assign x_boundary = ((ball_x == {`WIDTH{1'b1}}) | (ball_x == {`WIDTH{1'b0}}));  
  assign y_boundary = ((ball_y == {`HEIGHT{1'b1}}) | (ball_y == {`HEIGHT{1'b0}}));

  Counter #(4) sc_l(clk, reset, reset | (slow_clk & incr_l), score_l);
  Counter #(4) sc_r(clk, reset, reset | (slow_clk & incr_r), score_r);
  
  assign contact_pt = vel_x ? contact_pt_r : contact_pt_l;

  //position
  Bounce_cond left_edge(ball_y, l_pad, padonball_l, contact_pt_l);
  Bounce_cond right_edge(ball_y, r_pad, padonball_r, contact_pt_r);
  
endmodule

//--------------------------------------
// Combinational logic
//--------------------------------------
module Bounce_cond(ball_y, pad, padonball, contact_pt);
  input [`HEIGHT-1:0] ball_y, pad;
  output [1:0] contact_pt;
  output padonball;
  
  reg [1:0] contact_pt;

  wire padonball = (ball_y == pad) |
                     (ball_y == pad+1) |
                     (ball_y == pad+2) |
                     (ball_y == pad+3) |
                     (ball_y+1 == pad) |
                     (ball_y+2 == pad) |
                     (ball_y+3 == pad) |
                     (ball_y+4 == pad);

  always @(ball_y or pad) begin
     if (ball_y == pad)
       contact_pt = `MID;
     else if (ball_y == pad+1)
       contact_pt = `MID;
     else if (ball_y == pad+2)
       contact_pt = `BOTTOM;
     else if (ball_y == pad+3)
       contact_pt = `BOTTOM;
     else if (ball_y+1 == pad)
       contact_pt = `BOTTOM;
     else if (ball_y+2 == pad)
       contact_pt = `TOP;
     else if (ball_y+3 == pad)
       contact_pt = `TOP;
     else if (ball_y+4 == pad)
       contact_pt = `TOP;
  end
endmodule
