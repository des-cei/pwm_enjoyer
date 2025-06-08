-- Módulo: my_pkg
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 02.06.2025

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
    constant G_SYS_CLK_HZ   : integer := 50_000_000;    -- Reloj de referencia

    -- Número de parámetros
    constant G_PARAMS_N     : integer := 4; -- Número de parámetros o estados

    -- Tamaño de los parámetros
    constant G_PARAM_MAX_N  : integer := 10;                                        -- Número máximo de bits de cualquiera de los parámetros
    constant G_PARAM_MAX_L2 : integer := integer(ceil(log2(real(G_PARAM_MAX_N))));  -- Tamaño del vector de cualquiera de los parámetros

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- Valores de los parámetros
    constant C_VAL_PARAM_1  : std_logic := '1';
    constant C_VAL_PARAM_2  : std_logic := '0';
    constant C_VAL_PARAM_3  : std_logic := '1';
    constant C_VAL_PARAM_4  : std_logic := '0';

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