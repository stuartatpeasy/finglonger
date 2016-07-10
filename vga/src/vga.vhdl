-- VGA output demonstration for Lattice ICEstick
--
-- Stuart Wallace, July 2016.
--

-- VGA timings
--
-- ----------------  -------- horizontal -------  -------- vertical ---------  -------  --- pll ---
-- resolution  rfsh  sync   fp    bp    pix  pol  sync   fp    bp    pix  pol  clk/MHz  divf   divq
-- ----------------  ---------------------------  ---------------------------  -------  -----------
--  640 x  480  @60    96   16    48    640    0     2   10    33    480    0   25.175  1000010 101
--  800 x  600  @60   128   40    88    800    1     4    1    23    600    1   40.000  0110100 100
-- 1024 x  768  @60   136   24   160   1024    0     6    3    29    768    0   65.000  1010110 100
-- 1280 x 1024  @60   112   48   248   1280    1     3    1    38   1024    1  108.000  1000111 011
-- 1440 x  900  @60   152   80   232   1440    0     3    1    28    900    1  106.470  1000110 011
-- 1680 x 1050  @60   184  104   288   1680    0     3    1    33   1050    1  147.140  0110000 010
-- 1920 x 1080  @60   207  119   326   1920    0     3    1    32   1080    0  172.221  0111000 010
-- ----------------  ---------------------------  ---------------------------  ------- ------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity vga_gen is
    port(
        CLK         : in std_logic;         -- master clock input (12MHz)

        HSYNC       : out std_logic;        -- horizontal sync
        VSYNC       : out std_logic;        -- vertical sync

        R           : out std_logic;        -- red output
        G           : out std_logic;        -- green output
        B           : out std_logic         -- blue output
    );
end;


architecture behaviour of vga_gen is
    signal disp_en      : std_logic;

    signal x            : std_logic_vector(11 downto 0);
    signal y            : std_logic_vector(11 downto 0);
begin

    -- instantiate a VGA controller module
    vga_controller_inst: entity work.vga_controller 
        generic map(
            h_sync_width    => 207,
            h_fp_width      => 119,
            h_bp_width      => 326,
            h_pixels        => 1920,
            h_sync_pol      => '0',

            v_sync_width    => 3,
            v_fp_width      => 1,
            v_bp_width      => 32,
            v_pixels        => 1080,
            v_sync_pol      => '0',

            pll_divf        => "0111000",
            pll_divq        => "010"
        )
        port map(
            ref_clk         => CLK,
            reset           => '1',

            h_sync          => HSYNC,
            v_sync          => VSYNC,

            disp_en         => disp_en,

            col             => x,
            row             => y
        );

    process(disp_en, x, y)
    begin
        if(disp_en = '1') then
            -- inside the active display area: light all the red and blue pixels
            -- (could use the values of the "x" and "y" signals to determine what to display here)
            if(x(5) = '0' and x(6) = '0') then
                R <= '0';
                G <= '0';
            elsif(x(5) = '1' and x(6) = '0') then
                R <= '1';
                G <= '0';
            elsif(x(5) = '0' and x(6) = '1') then
                R <= '0';
                G <= '1';
            elsif(x(5) = '1' and x(6) = '1') then
                R <= '1';
                G <= '1';
            end if;

            if(y(5) = '0') then
                B <= '0';
            else
                B <= '1';
            end if;
        else
            -- outside the active display area
            R <= '0';
            G <= '0';
            B <= '0';
        end if;
    end process;
end behaviour;

