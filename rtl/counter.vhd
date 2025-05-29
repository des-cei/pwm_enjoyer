----------------------------------------------------------
--                                                      --
--          Digital Embedded Systems (DES)              --
--       Centro de Electronica Industrial (CEI)         --
--      Universidad Politecnica de Madrid (UPM)         --
--                                                      --
--                  VHDL Counter                        --
--                                                      --
-- Author:  Daniel Vazquez <daniel.vazquez@upm.es>      --
--                                                      --
-- Description:  Configurable counter                   --
-- Features:                                            --
--      Enable signal                                   --
--      Overflow mode                                   --
--      Synchronous reset (clr)                         --
--      Reset poling                                    --
--                                                      --
----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity counter is

    generic (
        C_CNT_BITS  : natural := 8;         -- Counter resolution
        C_CNT_MAX   : natural := 200;       -- Maximum count
        C_OV        : boolean := false;     -- Overflow mode (true - enabled, false - disabled)
        C_RSTPOL    : std_logic := '1'      -- Reset poling
    );
    port (
        -- Inputs
        clk             : in std_logic;
        reset           : in std_logic;
        clr             : in std_logic;
        enable          : in std_logic;
        -- Output
        count           : out std_logic_vector((C_CNT_BITS - 1) downto 0);
        overflow        : out std_logic 
    );

end entity counter;

architecture Behavioral of counter is

    constant MAX_CNT_STD    : std_logic_vector((C_CNT_BITS - 1) downto 0) := std_logic_vector(to_unsigned((C_CNT_MAX - 1), C_CNT_BITS));
    signal counter_std      : std_logic_vector((C_CNT_BITS - 1) downto 0);

begin

    cnt : process(clk, reset)
    begin
        if reset = C_RSTPOL then
            counter_std <= (others => '0');
        elsif clk'event and clk = '1' then
            if clr = '1' then
                counter_std <= (others => '0');
            elsif enable = '1' then
                if (counter_std < MAX_CNT_STD) then
                    counter_std <= std_logic_vector(unsigned(counter_std) + 1);
                else
                    counter_std <= (others => '0');
                end if;               
            end if;
        end if;
    end process;
    
    GEN_OV : if C_OV = true generate
    begin
        overflow <= '1' when (counter_std = MAX_CNT_STD) else '0';
    end generate;
    
    GEN_N_OV : if C_OV = false generate
    begin
        overflow <= '0';
    end generate;
    
    count <= counter_std;

end Behavioral;
