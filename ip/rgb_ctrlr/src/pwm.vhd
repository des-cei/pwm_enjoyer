-- Módulo: pwm
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.11.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm is
    generic (
        G_SYS_CLK_HZ    : integer := 125_000_000;
        G_RST_POL       : std_logic := '1';
        G_PERIOD_MAX_US : integer := 1_000_000
    );
    port (
        CLK_I       : in std_logic;
        RST_I       : in std_logic;
        DUTY_I      : in integer range 0 to 100;                -- Duty cycle [%]
        PERIOD_US_I : in integer range 0 to G_PERIOD_MAX_US;    -- Period [us]
        PWM_O       : out std_logic
    );
end entity pwm;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm is

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
    -- Contador de us
    constant C_CNT_REF_MAX  : integer := G_SYS_CLK_HZ/(10**6);
    signal r_cnt_ref        : integer range 0 to C_CNT_REF_MAX;

    -- Tiempo activo
    signal s_on     : integer range 0 to G_PERIOD_MAX_US;
    signal r_cnt_on : integer range 0 to G_PERIOD_MAX_US;

    -- Salida
    signal r_pwm    : std_logic;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    s_on <= DUTY_I * PERIOD_US_I / 100;

    PWM_O <= r_pwm;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Divisor de frecuencia
    P_CLK_NS : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt_ref <= 0;
        elsif rising_edge(CLK_I) then
            if (r_cnt_ref < (C_CNT_REF_MAX - 1)) then
                r_cnt_ref <= r_cnt_ref + 1;
            else
                r_cnt_ref <= 0;
            end if;
        end if;
    end process P_CLK_NS;

    -- Contador de us
    P_CNT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_cnt_on <= 0;
        elsif rising_edge(CLK_I) then
            if (r_cnt_ref = (C_CNT_REF_MAX - 1)) then
                if (r_cnt_on < (PERIOD_US_I - 1)) then
                    r_cnt_on <= r_cnt_on + 1;
                else
                    r_cnt_on <= 0;
                end if;
            end if;
        end if;
    end process P_CNT;

    -- Salida
    P_PWM : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_pwm <= '0';
        elsif rising_edge(CLK_I) then
            if (r_cnt_on < s_on) then
                r_pwm <= '1';
            else
                r_pwm <= '0';
            end if;
        end if;
    end process P_PWM;

end architecture beh;