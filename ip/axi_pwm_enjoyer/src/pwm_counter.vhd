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
        CLK_I           : in std_logic;
        RST_I           : in std_logic;
        EN_I            : in std_logic;                                         -- Señal de habilitación                                         
        CNT_LEN_I       : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del estado actual
        CNT_LEN_NEXT_I  : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del siguiente estado
        SWITCH_MEM_I    : in std_logic;                                         -- Indicador de último valor del último ciclo
        PWM_INIT_I      : in std_logic;                                         -- Valor inicial del ciclo
        PWM_O           : out std_logic;                                        -- Salida del PWM
        CNT_END_O       : out std_logic                                         -- Indicador de final de estado
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
    signal r_cnt        : unsigned((G_STATE_MAX_L2 - 1) downto 0);
    signal r_pwm        : std_logic;
    signal r_cnt_end    : std_logic;
    signal r_switch_mem : std_logic;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    PWM_O <= r_pwm;

    CNT_END_O <= r_cnt_end;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Registro de entradas
    P_REG : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_switch_mem <= '0';
        elsif rising_edge(CLK_I) then
            r_switch_mem <= SWITCH_MEM_I;
        end if;
    end process P_REG;  

    -- Contador
    P_CNT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt <= (others => '0');
            r_pwm <= '0';
        elsif rising_edge(CLK_I) then
            if (EN_I = '1') then
                if (unsigned(CNT_LEN_I) > 0) then
                    if (r_cnt < (unsigned(CNT_LEN_I) - 1)) then
                        r_cnt <= r_cnt + 1;
                    else
                        r_cnt <= (others => '0');
                        if (r_switch_mem = '0') then
                            r_pwm <= not r_pwm;
                        elsif (r_switch_mem = '1') then
                            r_pwm <= PWM_INIT_I;
                        end if;
                    end if;
                else
                    r_pwm <= PWM_INIT_I;
                end if;
            else
                r_cnt <= (others => '0');
                r_pwm <= '0';
            end if;
        end if;
    end process P_CNT;

    -- Flag de final
    P_CNT_END : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt_end <= '0';
        elsif rising_edge(CLK_I) then
            r_cnt_end <= '0';
            if (EN_I = '1') then
                -- Caso normal: estado actual > 1
                if (unsigned(CNT_LEN_I) > 1) then
                    -- Caso normal
                    if (r_cnt = (unsigned(CNT_LEN_I) - 2)) then
                        r_cnt_end <= '1';
                    -- Caso particular: siguiente estado es 1
                    elsif ((r_cnt = (unsigned(CNT_LEN_I) - 1)) and (unsigned(CNT_LEN_NEXT_I) = 1)) then
                        r_cnt_end <= '1';
                    end if;
                -- Caso particular: estado actual es 1 y el siguiente también
                elsif ((unsigned(CNT_LEN_I) = 1) and (unsigned(CNT_LEN_NEXT_I) = 1)) then
                    r_cnt_end <= '1';
                end if;
            end if;
        end if;
    end process P_CNT_END;

end architecture beh;