-- Módulo: pwm_top
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 09.07.2025

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
entity pwm_top is
    generic (
        G_DATA_W    : integer   := 32;              -- Ancho de datos en bits (G_STATE_MAX_L2)
        G_ADDR_W    : integer   := 32;              -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
        G_MEM_DEPTH : integer   := 4096;            -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
        G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I       : in std_logic;     
        RST_I       : in std_logic;
        EN_I        : in std_logic;                                             -- Señal de habilitación
        N_ADDR_I    : in std_logic_vector((G_ADDR_W - 1) downto 0);             -- Número de estados del PWM
        CYC_SYNC_I  : in std_logic;                                             -- Señal de sincronismo de todos los PWM
        PWM_INIT_I  : in std_logic;                                             -- Valor inicial
        WR_EN_I     : in std_logic;                                             -- Enable de escritura
        WR_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0);             -- Dirección de escritura
        WR_DATA_I   : in std_logic_vector((G_DATA_W - 1) downto 0);             -- Dato de escritura
        PWM_O       : out std_logic                                             -- Salida binaria
    );
end entity pwm_top;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture str of pwm_top is

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
    -- Port map
    signal s_rd_addr    : std_logic_vector((G_ADDR_W - 1) downto 0);
    signal s_rd_data    : std_logic_vector((G_DATA_W - 1) downto 0);
    signal s_cnt_end    : std_logic;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    state_ctrlr_i : entity work.state_ctrlr
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            EN_I        => EN_I,
            N_ADDR_I    => N_ADDR_I,
            CYC_SYNC_I  => CYC_SYNC_I,
            CNT_END_I   => s_cnt_end,
            RD_ADDR_O   => s_rd_addr
        );

    pwm_dp_mem_i : entity work.pwm_dp_mem
        generic map (
            G_DATA_W    => G_STATE_MAX_L2,
            G_ADDR_W    => G_MEM_SIZE_MAX_L2,
            G_MEM_DEPTH => G_MEM_SIZE_MAX_N,
            G_MEM_MODE  => "LOW_LATENCY",
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            WR_EN_I     => WR_EN_I,
            WR_ADDR_I   => WR_ADDR_I,
            WR_DATA_I   => WR_DATA_I,
            CYC_SYNC_I  => CYC_SYNC_I,
            RD_ADDR_I   => s_rd_addr,
            RD_DATA_O   => s_rd_data 
        );

    pwm_counter_i : entity work.pwm_counter
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            EN_I        => EN_I,
            CNT_LEN_I   => s_rd_data,
            PWM_INIT_I  => PWM_INIT_I,
            PWM_O       => PWM_O,
            CNT_END_O   => s_cnt_end
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- n/a

end architecture str;