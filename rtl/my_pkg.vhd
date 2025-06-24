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
    constant G_SYS_CLK_HZ   : integer := 50_000_000;    -- Reloj de referencia

    -- Nivel activo del reset
    constant G_RST_POL      : std_logic := '1';

    -- Tamaño de los parámetros
    constant G_STATE_MAX_N      : integer := 10;                                            -- Número máximo de pulsos que dura un estado
    constant G_STATE_MAX_L2     : integer := integer(ceil(log2(real(G_STATE_MAX_N))));      -- Tamaño del vector de número de pulsos de un estado
    constant G_MEM_SIZE_MAX_N   : integer := 8;                                             -- Número máximo de estados, tamaño máximo de la memoria
    constant G_MEM_SIZE_MAX_L2  : integer := integer(ceil(log2(real(G_MEM_SIZE_MAX_N))));   -- Tamaño del vector del número de estados

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- n/a

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