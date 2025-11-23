-- Módulo: pwm_top
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 09.07.2025

-- Forma de funcionamiento:
--  Se puede cargar una configuración siempre que EN_WR_CONFIG_O = '1'.
--      En caso contrario esa configuración no se aplicará.
--  Cada vez que se quiera activar la configuración cargada previamente (actualizar
--      la memoria) se debe presentar un pulso positivo en UPD_MEM_I.
--  Cada configuración queda definida por:
--      · Entrada de datos en serie: WR_EN, WR_ADDR, WR_DATA
--      · Número de estados de la configuración: N_ADDR
--      · Número total de ciclos de la configuración: N_TOT_CYC
--      · Primer valor de la salida: PWM_INIT
--  Por ejemplo, para una tabla 2-4-1-3 cuyo primer estado sea '1', la 
--      estructura de datos debe ser la siguiente:
--      CLK          :  /'\_/'\_/'\_/'\_/'\_/'\_/'\_/'\_/'\_/'\_
--      WR_EN        :  ____/'''''''''''''''\___
--      WR_ADDR      :  ____/ 0 X 1 X 2 X 3 \___
--      WR_DATA      :  ____/ 2 X 4 X 1 X 3 \___
--      N_ADDR       :  ____/ 4 ------------\___
--      N_TOT_CYC    :  ____/ 10 -----------\___
--      PWM_INIT     :  ____/''''' (hasta la siguiente config)
--  Aplicada la configuración se espera a la salida:
--      PWM          :  /'''''''\_______________/'''\___________


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
        G_DATA_W    : integer   := G_STATE_MAX_L2;      -- Ancho de datos en bits (G_STATE_MAX_L2)
        G_ADDR_W    : integer   := G_MEM_SIZE_MAX_L2;   -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
        G_MAX_PUL_W : integer   := G_PERIOD_MAX_L2;     -- Número máximo de pulsos de una configuración (G_PERIOD_MAX_L2)
        G_MEM_DEPTH : integer   := G_MEM_SIZE_MAX_N;    -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
        G_MEM_MODE  : string    := "LOW_LATENCY";       -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
        G_RST_POL   : std_logic := '1'
    );
    port (
        CLK_I           : in std_logic;     
        RST_I           : in std_logic;
        -- Activación de memoria
        EN_I            : in std_logic;                                     -- Señal de habilitación del PWM
        UPD_MEM_I       : in std_logic;                                     -- Pulso de actualización de memoria
        -- Configuración de la memoria
        WR_EN_I         : in std_logic;                                     -- Enable de escritura
        WR_ADDR_I       : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de escritura
        WR_DATA_I       : in std_logic_vector((G_DATA_W - 1) downto 0);     -- Dato de escritura
        N_ADDR_I        : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Número de estados
        N_TOT_CYC_I     : in std_logic_vector((G_MAX_PUL_W - 1) downto 0);  -- Número total de ciclos que dura la configuración
        PWM_INIT_I      : in std_logic;                                     -- Valor inicial de salida
        -- Salidas
        PWM_O           : out std_logic;                                    -- Salida del PWM
        EN_WR_CONFIG_O  : out std_logic                                     -- Habilitación de configuración de memoria
    );
end entity pwm_top;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture str of pwm_top is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- Componentes definidos explícitamente

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
    -- Interconexiones
    signal s_cnt_end        : std_logic := '0';
    signal s_next_config    : mem := (others => (others => '0'));
    signal s_rd_addr        : std_logic_vector((G_ADDR_W - 1) downto 0) := (others => '0');
    signal s_en_cnt         : std_logic := '0';
    signal s_switch_mem     : std_logic := '0';
    signal s_last_cyc       : std_logic := '0';
    signal s_en_wr_config   : std_logic := '0';
    signal s_rd_data        : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');
    signal s_rd_data_next   : std_logic_vector((G_DATA_W - 1) downto 0) := (others => '0');

    -------------------------------------------------
    -- ILA
    -------------------------------------------------
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of EN_I            : signal is "true";
    attribute MARK_DEBUG of UPD_MEM_I       : signal is "true";
    attribute MARK_DEBUG of PWM_O           : signal is "true";
    attribute MARK_DEBUG of EN_WR_CONFIG_O  : signal is "true";

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- Máquina de estados
    fsm_i : entity work.state_ctrlr
        generic map (
            G_RST_POL       => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            N_ADDR_I        => N_ADDR_I,
            N_TOT_CYC_I     => N_TOT_CYC_I,
            UPD_MEM_I       => UPD_MEM_I,
            CNT_END_I       => s_cnt_end,
            NEXT_CONFIG_I   => s_next_config,
            RD_ADDR_O       => s_rd_addr,
            EN_CNT_O        => s_en_cnt,
            SWITCH_MEM_O    => s_switch_mem,
            LAST_CYC_O      => s_last_cyc,
            EN_WR_CONFIG_O  => s_en_wr_config
        );

    -- Memoria
    mem_i : entity work.pwm_dp_mem
        generic map (
            G_DATA_W        => G_DATA_W,
            G_ADDR_W        => G_ADDR_W,
            G_MEM_DEPTH     => G_MEM_DEPTH,
            G_MEM_MODE      => G_MEM_MODE,
            G_RST_POL       => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_WR_CONFIG_I  => s_en_wr_config,
            WR_EN_I         => WR_EN_I,
            WR_ADDR_I       => WR_ADDR_I,
            WR_DATA_I       => WR_DATA_I,
            SWITCH_MEM_I    => s_switch_mem,
            LAST_CYC_I      => s_last_cyc,
            N_ADDR_I        => N_ADDR_I,
            RD_ADDR_I       => s_rd_addr,
            RD_DATA_O       => s_rd_data, 
            RD_DATA_NEXT_O  => s_rd_data_next,
            NEXT_CONFIG_O   => s_next_config 
        );

    -- Contador
    cnt_i : entity work.pwm_counter
        generic map (
            G_RST_POL       => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => s_en_cnt,
            CNT_LEN_I       => s_rd_data,
            CNT_LEN_NEXT_I  => s_rd_data_next,
            SWITCH_MEM_I    => s_switch_mem,
            PWM_INIT_I      => PWM_INIT_I,
            PWM_O           => PWM_O,
            CNT_END_O       => s_cnt_end
        );

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    EN_WR_CONFIG_O <= s_en_wr_config;

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- n/a

end architecture str;