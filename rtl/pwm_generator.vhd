-- Módulo: pwm_generator
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 02.06.2025

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
entity pwm_generator is
    generic (
        G_PARAM_MAX_N   : integer := 10;    -- Pulsos máximos que dura cualquiera de los parámetros
        G_PARAMS_N      : integer := 4      -- Número de parámetros que componen la tabla
    );
    port (
        CLK_I       : in std_logic;
        RST_I       : in std_logic;                                         -- Reset asíncrono por nivel alto
        SET_I       : in std_logic;                                         -- Señal para aplicar la configuración de entrada
        PARAM_1_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_1
        PARAM_2_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_2
        PARAM_3_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_3
        PARAM_4_I   : in std_logic_vector((G_PARAM_MAX_L2 - 1) downto 0);   -- Número pulsos a nivel alto del PARAM_4
        PWM_O       : out std_logic
    );
end entity pwm_generator;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_generator is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    type t_estado is record
        ancho   : integer range 0 to (G_PARAM_MAX_N - 1);
        salida  : std_logic;
    end record t_estado;

    type t_tabla is array (0 to (G_PARAMS_N - 1)) of t_estado;

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Entradas
    signal r_set    : std_logic;
    signal tabla    : t_tabla;

    -- Salidas
    signal r_pwm    : std_logic;

    -- Contadores
    signal r_cnt_estados    : integer range 0 to (G_PARAMS_N - 1);
    signal r_cnt_bits       : integer range 0 to (G_PARAM_MAX_N - 1);

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- Salidas
    PWM_O <= r_pwm;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Registro de la señal de set
    P_SET : process (CLK_I, RST_I)
    begin
        if (RST_I = '1') then
            r_set <= '0';
        elsif rising_edge(CLK_I) then
            if (SET_I = '1') then
                r_set <= '1';
            elsif ((r_set = '1') and (r_cnt_estados = (G_PARAMS_N - 1)) and (r_cnt_bits = (tabla(G_PARAMS_N - 1).ancho - 1))) then
                r_set <= '0';
            end if;
        end if;
    end process P_SET;

    -- Set de los parámetros de entrada
    P_REG_IN : process (CLK_I, RST_I)
    begin
        if (RST_I = '1') then
            tabla(0) <= (ancho => G_PARAM_MAX_N, salida => C_VAL_PARAM_1);
            tabla(1) <= (ancho => G_PARAM_MAX_N, salida => C_VAL_PARAM_2);
            tabla(2) <= (ancho => G_PARAM_MAX_N, salida => C_VAL_PARAM_3);
            tabla(3) <= (ancho => G_PARAM_MAX_N, salida => C_VAL_PARAM_4);
        elsif rising_edge(CLK_I) then
            if ((r_set = '1') and (r_cnt_estados = (G_PARAMS_N - 1)) and (r_cnt_bits = (tabla(G_PARAMS_N - 1).ancho - 1))) then
                tabla(0) <= (ancho => to_integer(unsigned(PARAM_1_I)), salida => C_VAL_PARAM_1);
                tabla(1) <= (ancho => to_integer(unsigned(PARAM_2_I)), salida => C_VAL_PARAM_2);
                tabla(2) <= (ancho => to_integer(unsigned(PARAM_3_I)), salida => C_VAL_PARAM_3);
                tabla(3) <= (ancho => to_integer(unsigned(PARAM_4_I)), salida => C_VAL_PARAM_4);
            end if;
        end if;
    end process P_REG_IN;

    -- Contador de bits
    P_CNT_BITS : process (CLK_I, RST_I)
    begin
        if (RST_I = '1') then
            r_cnt_bits <= 0;
        elsif rising_edge(CLK_I) then
            if (r_cnt_bits < (tabla(r_cnt_estados).ancho - 1)) then
                r_cnt_bits <= r_cnt_bits + 1;
            else
                r_cnt_bits <= 0;
            end if;
        end if;
    end process P_CNT_BITS;

    -- Contador de estados
    P_CNT_ST : process (CLK_I, RST_I)
    begin
        if (RST_I = '1') then
            r_cnt_estados <= 0;
        elsif rising_edge(CLK_I) then
            if (r_cnt_bits = (tabla(r_cnt_estados).ancho - 1)) then
                if (r_cnt_estados < (G_PARAMS_N - 1)) then
                    r_cnt_estados <= r_cnt_estados + 1;
                else
                    r_cnt_estados <= 0;
                end if;
            end if;
        end if;
    end process P_CNT_ST;

    -- Salida
    P_REG_OUT : process (CLK_I, RST_I)
    begin
        if (RST_I = '1') then
            r_pwm <= '0';
        elsif rising_edge(CLK_I) then
            r_pwm <= tabla(r_cnt_estados).salida;
        end if;
    end process P_REG_OUT;

end architecture beh;