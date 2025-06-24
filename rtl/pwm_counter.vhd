-- Módulo: pwm_counter
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 24.06.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm_counter is
    generic (
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I       : in std_logic;
        RST_I       : in std_logic;
        EN_I        : in std_logic;                                         -- Señal de habilitación                                         
        CNT_LEN_I   : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del estado actual
        PWM_INIT_I  : in std_logic;                                         -- Valor inicial
        PWM_O       : out std_logic;                                        -- Salida del PWM
        CNT_END_O   : out std_logic                                         -- Indicador de final de estado
    );
end entity pwm_counter;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_counter is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    signal r_cnt    : unsigned((G_STATE_MAX_L2 - 1) downto 0);
    signal r_pwm    : std_logic := PWM_INIT_I;
    signal r_en     : std_logic;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    PWM_O <= r_pwm when (EN_I = '1') else '0';

    CNT_END_O <= '1' when (r_cnt = (unsigned(CNT_LEN_I) - 1)) else '0';

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- P_CNT : process (CLK_I, RST_I)
    -- begin
    --     if (RST_I = G_RST_POL) then
    --         r_cnt   <= (others => '0');
    --         r_pwm   <= PWM_INIT_I;
    --         CNT_END <= '0';
    --     elsif rising_edge(CLK_I) then
    --         CNT_END <= '0';
    --         if (EN_I = '1') then
    --             if (r_cnt < (unsigned(CNT_LEN_I) - 1)) then
    --                 r_cnt <= r_cnt + 1;
    --                 if (r_cnt = (unsigned(CNT_LEN_I) - 2)) then
    --                     CNT_END <= '1';
    --                 end if;
    --             else
    --                 r_cnt <= (others => '0');
    --                 r_pwm <= not r_pwm;
    --             end if;
    --         else
    --             r_cnt   <= (others => '0');
    --         end if;
    --     end if;
    -- end process P_CNT;



    P_CNT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt <= (others => '0');
            r_pwm <= PWM_INIT_I;
        elsif rising_edge(CLK_I) then
            if (EN_I = '1') then
                if (r_cnt < (unsigned(CNT_LEN_I) - 1)) then
                    r_cnt <= r_cnt + 1;
                else
                    r_cnt <= (others => '0');
                    r_pwm <= not r_pwm;
                end if;
            else
                r_cnt <= (others => '0');
                r_pwm <= PWM_INIT_I;
            end if;
        end if;
    end process P_CNT;


end architecture beh;