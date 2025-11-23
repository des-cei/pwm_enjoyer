-- Módulo: my_pkg
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.06.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-----------------------------------------------------------
-- Encabezado
-----------------------------------------------------------
package my_pkg is

    -------------------------------------------------
    -- Genéricos
    -------------------------------------------------
    -- Relojes
    constant G_SYS_CLK_HZ   : integer := 125_000_000;    -- Reloj del sistema

    -- Nivel activo del reset
    constant G_RST_POL      : std_logic := '1';

    -- Tamaño de los parámetros
    constant G_STATE_MAX_N      : integer := 20;                                            -- Número máximo de pulsos que dura un estado
    constant G_STATE_MAX_L2     : integer := integer(ceil(log2(real(G_STATE_MAX_N))));      -- Tamaño del vector de número de pulsos de un estado
    constant G_MEM_SIZE_MAX_N   : integer := 8;                                             -- Número máximo de estados, tamaño máximo de la memoria
    constant G_MEM_SIZE_MAX_L2  : integer := integer(ceil(log2(real(G_MEM_SIZE_MAX_N))));   -- Tamaño del vector del número de estados
    constant G_PERIOD_MAX_N     : integer := G_STATE_MAX_N*G_MEM_SIZE_MAX_N;                -- Número máximo de periodos de reloj que puede durar una configuración
    constant G_PERIOD_MAX_L2    : integer := integer(ceil(log2(real(G_PERIOD_MAX_N))));     -- Tamaño del vector del número de periodos

    -- Número máximo de módulos PWM
    constant G_PWM_N    : integer := 32;

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- Memoria de estados
    type mem is array (0 to G_MEM_SIZE_MAX_N - 1) of std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);

    -- Interfaces UC - PWM_TOP
    type pwm_top_in is record
        en              : std_logic;
        upd_mem         : std_logic;
        wr_en           : std_logic;
        wr_addr         : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
        wr_data         : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
        n_addr          : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
        n_tot_cyc       : std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);
        pwm_init        : std_logic;
    end record pwm_top_in;

    type pwm_top_out is record
        -- Módulo principal
        pwm                 : std_logic;
        en_wr_config        : std_logic;
        -- Módulo redundante 1
        pwm_red_1           : std_logic;
        en_wr_config_red_1  : std_logic;
        -- Módulo redundante 2
        pwm_red_2           : std_logic;
        en_wr_config_red_2  : std_logic;
    end record pwm_top_out;

    type modulo_pwm_in is array (0 to (G_PWM_N - 1)) of pwm_top_in;
    type modulo_pwm_out is array (0 to (G_PWM_N - 1)) of pwm_top_out;

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- n/a

end package my_pkg;

-----------------------------------------------------------
-- Cuerpo
-----------------------------------------------------------
package body my_pkg is

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- n/a

end package body my_pkg;