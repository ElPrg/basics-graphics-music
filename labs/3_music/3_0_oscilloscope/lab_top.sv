`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height )
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

    //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
    // assign red        = '0;
    // assign green      = '0;
    // assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;
    
    logic                   white;
    assign red   = {w_red  {white}};
    assign green = {w_green{white}};
    assign blue  = {w_blue {white}};


    //------------------------------------------------------------------------
    //
    //  Oscilloscope
    //
    //------------------------------------------------------------------------

    // It is enough for the counter to be 20 bit. Why?

    logic        [23:0]    prev_mic;
    logic        [19:0]    counter;
    logic        [19:0]    distance;
    logic signed [w_y-1:0] bufy[screen_width/2];
    wire  signed [w_y-1:0] micy = {mic[23], (mic[23]?~&mic[22:16]:|mic[22:16])? ~{(w_y-1){$signed(mic[23])}} : mic[15-:w_y-1]};
    wire         [w_x-1:0] cnt  = counter[19-:w_x];
    localparam logic signed [w_y-1:0] midy = screen_height/2;

    always_comb
        white = (x>>1) < (distance[19-:w_x]) && y == midy - bufy[(x>>1)] && x < screen_width && y < screen_height;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            prev_mic <= '0;
            counter  <= '0;
            distance <= '0;
        end
        else
        begin
            if (cnt < screen_width/2)
                bufy[cnt] <= micy;

            prev_mic <= mic;

            // Crossing from negative to positive numbers
            if (  prev_mic [$left ( prev_mic )] == 1'b1
                & mic      [$left ( mic      )] == 1'b0 )
            begin
               distance <= counter;
               counter  <= 20'h0;
            end
            else if (counter != ~ 20'h0)  // To prevent overflow
            begin
               counter <= counter + 20'h1;
            end
        end

endmodule
