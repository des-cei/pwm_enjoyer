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
    constant C_SYS_CLK_HZ   : natural := 125_000_000;    -- Reloj del sistema

    -- Nivel activo del reset
    constant C_RST_POL      : std_logic := '1';

    -- Ancho de los registros AXI
    constant C_AXI_REG_W    : natural := 32;

    -- Profunidad de la memoria
    constant C_MEM_SIZE_MAX_N   : natural := 128;                                               -- Número máximo de estados
    constant C_MEM_SIZE_MAX_L2  : natural := integer(ceil(log2(real(C_MEM_SIZE_MAX_N + 1))));   -- Tamaño del vector

    -- Ancho de la memoria
    constant C_STATE_MAX_N      : natural := 2**31 - 1;                                         -- Número máximo de pulsos que dura un estado (simulación)
    -- constant C_STATE_MAX_L2     : natural := integer(ceil(log2(real(C_STATE_MAX_N))));       -- Tamaño del vector
    constant C_STATE_MAX_L2     : natural := C_AXI_REG_W;                                       -- Tamaño del vector
    -- NOTE:
    --  Como el acceso a los registros es de 32 bits, para poder tener N_TOT_CYC = FFFF_FFFF, en el peor caso posible (que se 
    --      configuren C_MEM_SIZE_MAX_N estados, el valor máximo de los estados queda limitado a FFFF_FFFF / 128 = 1FF_FFFF = 33_554_431)

    -- Suma de todos los estados de la configuración
    -- constant C_PERIOD_MAX_N     : natural := 2**32 - 1;                                      -- Número máximo de periodos de reloj
    -- constant C_PERIOD_MAX_L2    : natural := integer(ceil(log2(real(C_PERIOD_MAX_N))));      -- Tamaño del vector
    constant C_PERIOD_MAX_L2    : natural := C_AXI_REG_W;                                       -- Tamaño del vector

    -- Número máximo de módulos PWM
    constant C_PWM_N    : natural := 32;

    -- Habilita redundancias internas
    constant C_EN_REDUNDANCY    : std_logic := '1';

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    -- Memoria de estados
    type mem is array (0 to C_MEM_SIZE_MAX_N - 1) of std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);

    -- Interfaces UC - PWM_TOP
    type pwm_top_in is record
        en              : std_logic;
        upd_mem         : std_logic;
        wr_en           : std_logic;
        wr_addr         : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);
        wr_data         : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
        n_addr          : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);
        n_tot_cyc       : std_logic_vector((C_PERIOD_MAX_L2 - 1) downto 0);
        pwm_init        : std_logic;
    end record pwm_top_in;

    type pwm_top_out is record
        pwm             : std_logic;
        unlocked        : std_logic;
        status          : std_logic_vector(1 downto 0);
    end record pwm_top_out;

    type modulo_pwm_in is array (0 to (C_PWM_N - 1)) of pwm_top_in;
    type modulo_pwm_out is array (0 to (C_PWM_N - 1)) of pwm_top_out;

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Ampliar la longitud de un slv y le añade un offset
    function resize_offset (
        vect    : in std_logic_vector;
        offset  : in integer
    ) return std_logic_vector;

end package my_pkg;

-----------------------------------------------------------
-- Cuerpo
-----------------------------------------------------------
package body my_pkg is

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Ampliar la longitud de un slv y le añade un offset
    function resize_offset (
        vect    : in std_logic_vector;
        offset  : in integer
    ) return std_logic_vector is
        variable v_res : std_logic_vector(vect'length downto 0);
    begin
        v_res := std_logic_vector(to_unsigned((to_integer(unsigned(vect)) + offset), vect'length + 1));
        return v_res;
    end function resize_offset;

end package body my_pkg;