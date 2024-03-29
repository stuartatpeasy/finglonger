-- VGA output demonstration for Lattice ICEstick
--
-- Stuart Wallace, July 2016.
--

-- VGA timings
--
-- ----------------  -------- horizontal -------  -------- vertical ---------  -------  --- pll ---  -- pllx4 --  -- pllx8 --
-- resolution  rfsh  sync   fp    bp    pix  pol  sync   fp    bp    pix  pol  clk/MHz  divf   divq  divf   divq  divf   divq
-- ----------------  ---------------------------  ---------------------------  -------  -----------  -----------  -----------
--  640 x  480  @60    96   16    48    640    0     2   10    33    480    0   25.175  1000010 101  1000010 011  1000010 010
--  800 x  600  @60   128   40    88    800    1     4    1    23    600    1   40.000  0110100 100  0110100 010
-- 1024 x  768  @60   136   24   160   1024    0     6    3    29    768    0   65.000  1010110 100  1010110 010
-- 1280 x 1024  @60   112   48   248   1280    1     3    1    38   1024    1  108.000  1000111 011
-- 1440 x  900  @60   152   80   232   1440    0     3    1    28    900    1  106.470  1000110 011
-- 1680 x 1050  @60   184  104   288   1680    0     3    1    33   1050    1  147.140  0110000 010
-- 1920 x 1080  @60   207  119   326   1920    0     3    1    32   1080    0  172.221  0111000 010
-- ----------------  ---------------------------  ---------------------------  -------  -----------  -----------  -----------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity vga_gen is
    generic(
        bpp     : integer := 5      -- bits per colour plane
    );

    port(
        CLK     : in std_logic;     -- master clock input (12MHz)

        H_SYNC,                     -- horizontal sync
        V_SYNC  : out std_logic;    -- vertical sync

        R,                                                  -- red
        G,                                                  -- green
        B       : out std_logic_vector(bpp - 1 downto 0)    -- blue
    );
end;


architecture behaviour of vga_gen is
    signal core_clk     : std_logic;
    signal pix_clk      : std_logic;

    signal disp_en      : std_logic;

    signal x, y         : std_logic_vector(10 downto 0);

    signal pix_val      : std_logic_vector((bpp * 3) - 1 downto 0);
begin

    -- instantiate a clock-generator PLL, fixed at 100.7MHz [=4 x 25.175MHz (for 640x480)]
    pll_inst: entity work.pll 
        generic map(
            -- 1024x768
            --pll_divf        => "1010110",
            --pll_divq        => "010"

            -- 800x600
            --pll_divf        => "0110100",
            --pll_divq        => "010"

            -- 640x480
            pll_divf        => "1000010",
            pll_divq        => "011"
        )
        port map(
            REFERENCECLK    => CLK,
            PLLOUTCORE      => core_clk,
            PLLOUTGLOBAL    => open,
            RESET           => '1'          -- TODO find out whether the chip has a reset input wired
        );

    -- produce the pixel clock = clk/4
    process(core_clk)
        variable div : integer range 0 to 1 := 0;
    begin
        if(rising_edge(core_clk)) then
            div := div + 1;
            if(div = 0) then
                pix_clk <= not pix_clk;
            end if;
        end if;
    end process;

    -- instantiate a VGA controller module; set resolution to 640x480 @60Hz
    vga_controller_inst: entity work.vga_controller 
        generic map(
            bpp             => bpp,

            -- 1024x768
            --vga_h_sync      => 136,
            --vga_h_fp        => 24,
            --vga_h_bp        => 160,
            --vga_h_pixels    => 1024,
            --vga_h_sync_pol  => '0',
              
            --vga_v_sync      => 6,
            --vga_v_fp        => 3,
            --vga_v_bp        => 29,
            --vga_v_pixels    => 768,
            --vga_v_sync_pol  => '0'

            -- 800x600
            --vga_h_sync      => 128,
            --vga_h_fp        => 40,
            --vga_h_bp        => 88,
            --vga_h_pixels    => 800,
            --vga_h_sync_pol  => '1',
              
            --vga_v_sync      => 4,
            --vga_v_fp        => 1,
            --vga_v_bp        => 23,
            --vga_v_pixels    => 600,
            --vga_v_sync_pol  => '1'

            -- 640x480
            vga_h_sync      => 96,
            vga_h_fp        => 16,
            vga_h_bp        => 48,
            vga_h_pixels    => 640,
            vga_h_sync_pol  => '0',

            vga_v_sync      => 2,
            vga_v_fp        => 10,
            vga_v_bp        => 33,
            vga_v_pixels    => 480,
            vga_v_sync_pol  => '0'
        )
        port map(
            CLK             => pix_clk,
            RESET           => '1',

            PIXEL           => pix_val,
            H_SYNC          => H_SYNC,
            V_SYNC          => V_SYNC,

            DISP_EN         => disp_en,

            COL             => x,
            ROW             => y,

            R               => R,
            G               => G,
            B               => B
        );

    -- pixel-lighting process
    process(x, y, pix_clk)
    begin
        if(rising_edge(pix_clk)) then
            pix_val <=   y(6) & y(5) & y(4) & y(3) & y(2)       -- blue component
                       & x(8) & x(7) & x(6) & x(5) & x(4)       -- green component
                       & y(7) & x(3) & x(2) & x(1) & x(0);      -- red component
        end if;
    end process;
end behaviour;

