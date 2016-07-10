-- Very simple VGA controller
--
-- Stuart Wallace, July 2016.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity vga_controller is
    generic(
        -- Horizontal
        h_sync_width    : integer;      -- sync pulse width, pixels
        h_fp_width      : integer;      -- "front porch" width, pixels
        h_bp_width      : integer;      -- "back porch" width, pixels
        h_pixels        : integer;      -- visible pixel count
        h_sync_pol      : std_logic;    -- sync polarity (1: +ve, 0: -ve)

        -- Vertical
        v_sync_width    : integer;      -- sync pulse width, rows
        v_fp_width      : integer;      -- "front porch" width, rows
        v_bp_width      : integer;      -- "back porch" width, rows
        v_pixels        : integer;      -- visible pixel count
        v_sync_pol      : std_logic;    -- sync polarity (1: +ve, 0: -ve)

        -- PLL attributes
        pll_divf        : bit_vector(6 downto 0);
        pll_divq        : bit_vector(2 downto 0)
    );

    port(
        REF_CLK         : in  std_logic;    -- reference clock
        RESET           : in  std_logic;    -- active-low async reset

        H_SYNC          : out std_logic;    -- horizontal sync
        V_SYNC          : out std_logic;    -- vertical sync

        DISP_EN         : out std_logic;    -- display enable

        COL             : out std_logic_vector(11 downto 0);      -- h co-ordinate
        ROW             : out std_logic_vector(11 downto 0)       -- v co-ordinate
    );
end vga_controller;


architecture behaviour of vga_controller is
    constant h_period   : integer := h_sync_width + h_bp_width + h_pixels + h_fp_width;
    constant v_period   : integer := v_sync_width + v_bp_width + v_pixels + v_fp_width;

    signal clk : std_logic;
begin

    -- instantiate a clock-generator PLL, fixed at 25.175MHz (for 640x480)
    vga_pll_inst: entity work.vga_pll 
        generic map(
            divf            => pll_divf,
            divq            => pll_divq
        )
        port map(
            REFERENCECLK    => REF_CLK,
            PLLOUTCORE      => clk,
            PLLOUTGLOBAL    => open,
            RESET           => RESET
        );

    process(clk, RESET)
        variable h_count : integer range 0 to h_period - 1 := 0;
        variable v_count : integer range 0 to v_period - 1 := 0;
    begin
        if(RESET = '0') then
            h_count := 0;
            v_count := 0;

            H_SYNC  <= not h_sync_pol;
            V_SYNC  <= not v_sync_pol;
            DISP_EN <= '0';

            COL <= (others => '0');
            ROW <= (others => '0');
        elsif(rising_edge(clk)) then
            if(h_count < (h_period - 1)) then
                h_count := h_count + 1;
            else
                h_count := 0;
                if(v_count < (v_period - 1)) then
                    v_count := v_count + 1;
                else
                    v_count := 0;
                end if;
            end if;

            -- generate horizontal sync
            if((h_count < (h_pixels + h_fp_width)) or (h_count > (h_pixels + h_fp_width + h_sync_width))) then
                H_SYNC <= not h_sync_pol;
            else
                H_SYNC <= h_sync_pol;
            end if;
    
            -- generate vertical sync
            if((v_count < (v_pixels + v_fp_width)) or (v_count > (v_pixels + v_fp_width + v_sync_width))) then
                V_SYNC <= not v_sync_pol;
            else
                V_SYNC <= v_sync_pol;
            end if;
    
            -- generate pixel co-ordinates
            if(h_count < h_pixels) then
                COL <= std_logic_vector(to_unsigned(h_count, COL'length));
            end if;
    
            if(v_count < v_pixels) then
                ROW <= std_logic_vector(to_unsigned(v_count, ROW'length));
            end if;
    
            -- generate display enable
            if((h_count < h_pixels) and (v_count < v_pixels)) then
                DISP_EN <= '1';
            else
                DISP_EN <= '0';
            end if;
        end if;
    end process;
end behaviour;

