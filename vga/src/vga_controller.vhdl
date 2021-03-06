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
        vga_h_sync,                     -- sync pulse width, pixels
        vga_h_fp,                       -- "front porch" width, pixels
        vga_h_bp,                       -- "back porch" width, pixels
        vga_h_pixels    : integer;      -- visible pixel count
        vga_h_sync_pol  : std_logic;    -- sync polarity (1: +ve, 0: -ve)

        -- Vertical
        vga_v_sync,                     -- sync pulse width, rows
        vga_v_fp,                       -- "front porch" width, rows
        vga_v_bp,                       -- "back porch" width, rows
        vga_v_pixels    : integer;      -- visible pixel count
        vga_v_sync_pol  : std_logic;    -- sync polarity (1: +ve, 0: -ve)
        
        bpp             : integer       -- bits per plane (colour channel)
    );

    port(
        CLK,                            -- reference clock
        RESET   : in  std_logic;        -- active-low async reset

        H_SYNC,                         -- horizontal sync
        V_SYNC,                         -- vertical sync
        DISP_EN : out std_logic;        -- display enable

        R,                                                  -- red output
        G,                                                  -- green output
        B       : out std_logic_vector(bpp - 1 downto 0);   -- blue output


        COL,                                                -- h co-ordinate of next pixel
        ROW     : out std_logic_vector(10 downto 0);        -- v co-ordinate of next pixel

        PIXEL   : in  std_logic_vector((bpp * 3) - 1 downto 0) -- pixel data
    );
end vga_controller;


architecture behaviour of vga_controller is
    constant h_period : integer := vga_h_sync + vga_h_bp + vga_h_pixels + vga_h_fp;
    constant v_period : integer := vga_v_sync + vga_v_bp + vga_v_pixels + vga_v_fp;

    signal pix_val_p2, pix_val_p3 : std_logic_vector(PIXEL'length - 1 downto 0);
    signal h_sync_p1, h_sync_p2, v_sync_p1, v_sync_p2 : std_logic;
begin
    process(CLK, RESET)
        variable h_count : integer range 0 to h_period - 1 := 0;
        variable v_count : integer range 0 to v_period - 1 := 0;
    begin
        if(RESET = '0') then
            h_count := 0;
            v_count := 0;

            H_SYNC  <= not vga_h_sync_pol;
            V_SYNC  <= not vga_v_sync_pol;
            DISP_EN <= '0';

            COL <= (others => '0');
            ROW <= (others => '0');

            R <= (others => '0');
            G <= (others => '0');
            B <= (others => '0');

            h_sync_p1 <= '0';
            h_sync_p2 <= '0';
            v_sync_p1 <= '0';
            v_sync_p2 <= '0';

            pix_val_p2 <= (others => '0');
            pix_val_p3 <= (others => '0');
        elsif(rising_edge(CLK)) then
            --
            -- Pipeline stage 3: emit pixel and sync signals
            --
            pix_val_p3  <= pix_val_p2;
            H_SYNC      <= h_sync_p2;
            V_SYNC      <= v_sync_p2;

            if((h_count < vga_h_pixels) and (v_count < vga_v_pixels)) then
                R <= pix_val_p3((bpp * 1) - 1 downto (bpp * 0));
                G <= pix_val_p3((bpp * 2) - 1 downto (bpp * 1));
                B <= pix_val_p3((bpp * 3) - 1 downto (bpp * 2));
            else
                R <= (others => '0');
                G <= (others => '0');
                B <= (others => '0');
            end if;


            --
            -- Pipeline stage 2: read pixel value and latch; move sync signals along the pipeline.
            --
            pix_val_p2 <= PIXEL;
            h_sync_p2 <= h_sync_p1;
            v_sync_p2 <= v_sync_p1;


            --
            -- Pipeline stage 1: calculate next pixel address and latch it on ROW and COL.
            -- Calculate the hsync & vsync values and latch them.
            --
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
            if((h_count >= (vga_h_pixels + vga_h_fp)) and
               (h_count <= (vga_h_pixels + vga_h_fp + vga_h_sync))) then
                h_sync_p1 <= vga_h_sync_pol;
            else
                h_sync_p1 <= not vga_h_sync_pol;
            end if;
            
            -- generate vertical sync
            if((v_count >= (vga_v_pixels + vga_v_fp)) and
               (v_count <= (vga_v_pixels + vga_v_fp + vga_v_sync))) then
                v_sync_p1 <= vga_v_sync_pol;
            else
                v_sync_p1 <= not vga_v_sync_pol;
            end if;

            -- generate pixel co-ordinates
            if(h_count < vga_h_pixels) then
                COL <= std_logic_vector(to_unsigned(h_count, COL'length));
            else
                COL <= (others => '0');
            end if;
    
            if(v_count < vga_v_pixels) then
                ROW <= std_logic_vector(to_unsigned(v_count, ROW'length));
            else
                ROW <= (others => '0');
            end if;

            if((h_count < vga_h_pixels) and (v_count < vga_v_pixels)) then
                DISP_EN <= '1';
            else
                DISP_EN <= '0';
            end if;
        end if;
    end process;
end behaviour;

