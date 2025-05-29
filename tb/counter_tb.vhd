----------------------------------------------------------
--                                                      --
--          Digital Embedded Systems (DES)              --
--       Centro de Electronica Industrial (CEI)         --
--      Universidad Politecnica de Madrid (UPM)         --
--                                                      --
--               VHDL Counter testbench                 --
--                                                      --
-- Author:  Daniel Vazquez <daniel.vazquez@upm.es>      --
--                                                      --
----------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity counter_tb is

    generic (
        C_CNT_BITS  : natural := 5;
        C_CNT_MAX   : natural := 30;
        C_OV        : boolean := true;
        C_RSTPOL    : std_logic := '0'
    );

end counter_tb;

architecture Behavioral of counter_tb is

    constant CLK_PERIOD : time := 8 ns; -- 125 MHz
    signal clk, reset, clr, enable, overflow : std_logic; 
    signal count : std_logic_vector(C_CNT_BITS-1 downto 0);
    
begin

    uut : entity work.counter(Behavioral)
        generic map(
            C_CNT_BITS  => C_CNT_BITS,
            C_CNT_MAX   => C_CNT_MAX,
            C_OV        => C_OV,
            C_RSTPOL    => C_RSTPOL
        )
        port map(
            -- Inputs
            clk         => clk,
            reset       => reset,
            clr         => clr,
            enable      => enable,          
            -- Outputs
            overflow    => overflow,
            count       => count
        );
        
    clk_stimuli : process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;
    
    uut_stimuli : process
    begin
        -- Initial reset
        reset <= C_RSTPOL;
        clr <= '0';
        enable <= '0';
        wait for CLK_PERIOD/64; -- Introduce real clock conditions
        wait for 5*CLK_PERIOD;
        reset <= not C_RSTPOL;
        wait for 5*CLK_PERIOD;
        
        -- Check free running
        enable <= '1';
        wait for (C_CNT_MAX+5)*CLK_PERIOD;

        -- Check synchronous reset
        clr <= '1';
        wait for CLK_PERIOD;
        clr <= '0';
        wait for 10*CLK_PERIOD;

        -- Check enable
        enable <= '0';
        wait for 5*CLK_PERIOD;
        enable <= '1';
        wait for 3*CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        enable <= '1';
        wait for CLK_PERIOD;
        enable <= '0';
        wait for CLK_PERIOD;
        enable <= '1';

        -- End of stimuli
        wait;
    end process;

end Behavioral;
