-- Módulo: pwm_enjoyer
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 04.11.2025

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
entity pwm_enjoyer is
    generic (
        -- Valor activo del reset
        G_RST_POL           : std_logic := '1';
        -- Número máximo de pulsos que dura un estado
        G_STATE_MAX_N       : integer := 20;
        -- Tamaño del vector de número de pulsos de un estado {integer(ceil(log2(real(G_STATE_MAX_N))))}
        G_STATE_MAX_L2      : integer := 5;
        -- Número máximo de estados, tamaño máximo de la memoria
        G_MEM_SIZE_MAX_N    : integer := 8;
        -- Tamaño del vector del número de estados {integer(ceil(log2(real(G_MEM_SIZE_MAX_N))))}
        G_MEM_SIZE_MAX_L2   : integer := 3;
        -- Número máximo de ciclos de reloj que puede durar una configuración {G_STATE_MAX_N*G_MEM_SIZE_MAX_N}
        G_PERIOD_MAX_N      : integer := 160;
        -- Tamaño del vector del número máximo de ciclos de reloj {integer(ceil(log2(real(G_PERIOD_MAX_N))))}
        G_PERIOD_MAX_L2     : integer := 8;
        -- Número de PWMS
        G_PWM_N             : integer := 32
    );
    port (
        CLK_I               : in std_logic;
        RST_I               : in std_logic;
        -- Registros de usuario
        REG_DIRECCIONES_I   : in std_logic_vector(31 downto 0);     -- (*)
        REG_CONTROL_I       : in std_logic_vector(31 downto 0);
        REG_WR_DATA_I       : in std_logic_vector(31 downto 0);
        REG_WR_DATA_VALID_I : in std_logic_vector(31 downto 0);
        REG_N_ADDR_I        : in std_logic_vector(31 downto 0);
        REG_N_TOT_CYC_I     : in std_logic_vector(31 downto 0);
        REG_PWM_INIT_I      : in std_logic_vector(31 downto 0);
        REG_REDUNDANCIAS_O  : out std_logic_vector(31 downto 0);    -- (*)
        REG_ERRORES_O       : out std_logic_vector(31 downto 0);    -- (*)
        REG_STATUS_O        : out std_logic_vector(31 downto 0);
        -- PWMs
        PWMS_O              : out std_logic_vector((G_PWM_N - 1) downto 0)   -- Array de G_PWM_N de las salidas de cada pwm_top
    );
end entity pwm_enjoyer;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture str of pwm_enjoyer is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- Definidos explícitamente

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
    signal s_pwm_top_inputs     : modulo_pwm_in; 
    signal s_pwm_top_outputs    : modulo_pwm_out;

    -------------------------------------------------
    -- ILA
    -------------------------------------------------
    attribute MARK_DEBUG : string;
    attribute MARK_DEBUG of RST_I               : signal is "true";
    attribute MARK_DEBUG of REG_DIRECCIONES_I   : signal is "true";
    attribute MARK_DEBUG of REG_CONTROL_I       : signal is "true";
    attribute MARK_DEBUG of REG_WR_DATA_I       : signal is "true";
    attribute MARK_DEBUG of REG_WR_DATA_VALID_I : signal is "true";
    attribute MARK_DEBUG of REG_N_ADDR_I        : signal is "true";
    attribute MARK_DEBUG of REG_N_TOT_CYC_I     : signal is "true";
    attribute MARK_DEBUG of REG_PWM_INIT_I      : signal is "true";
    attribute MARK_DEBUG of REG_REDUNDANCIAS_O  : signal is "true";
    attribute MARK_DEBUG of REG_ERRORES_O       : signal is "true";
    attribute MARK_DEBUG of REG_STATUS_O        : signal is "true";

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- Unidad de control
    uc_i : entity work.control_unit
        generic map (
            G_RST_POL   => G_RST_POL,
            G_PWM_N     => G_PWM_N  
        )
        port map (
            CLK_I               => CLK_I,
            RST_I               => RST_I,
            REG_DIRECCIONES_I   => REG_DIRECCIONES_I,
            REG_CONTROL_I       => REG_CONTROL_I,
            REG_WR_DATA_I       => REG_WR_DATA_I,
            REG_WR_DATA_VALID_I => REG_WR_DATA_VALID_I,
            REG_N_ADDR_I        => REG_N_ADDR_I,
            REG_N_TOT_CYC_I     => REG_N_TOT_CYC_I,
            REG_PWM_INIT_I      => REG_PWM_INIT_I,
            REG_REDUNDANCIAS_O  => REG_REDUNDANCIAS_O,
            REG_ERRORES_O       => REG_ERRORES_O,
            REG_STATUS_O        => REG_STATUS_O,
            PWM_TOP_INPUTS_O    => s_pwm_top_inputs,
            PWM_TOP_OUTPUTS_I   => s_pwm_top_outputs
        );

    -- Módulos PWM nominales
    gen_pwm_top_nom : for i in 0 to (G_PWM_N - 1) generate
        pwm_nom_i : entity work.pwm_top
            generic map (
                G_DATA_W        => G_STATE_MAX_L2,
                G_ADDR_W        => G_MEM_SIZE_MAX_L2,
                G_MAX_PUL_W     => G_PERIOD_MAX_L2,
                G_MEM_DEPTH     => G_MEM_SIZE_MAX_N,
                G_MEM_MODE      => "LOW_LATENCY",
                G_RST_POL       => G_RST_POL
            )
            port map (
                CLK_I           => CLK_I,
                RST_I           => RST_I,
                EN_I            => s_pwm_top_inputs(i).en,
                UPD_MEM_I       => s_pwm_top_inputs(i).upd_mem,
                WR_EN_I         => s_pwm_top_inputs(i).wr_en,
                WR_ADDR_I       => s_pwm_top_inputs(i).wr_addr,
                WR_DATA_I       => s_pwm_top_inputs(i).wr_data,
                N_ADDR_I        => s_pwm_top_inputs(i).n_addr,
                N_TOT_CYC_I     => s_pwm_top_inputs(i).n_tot_cyc,
                PWM_INIT_I      => s_pwm_top_inputs(i).pwm_init,
                PWM_O           => s_pwm_top_outputs(i).pwm,
                EN_WR_CONFIG_O  => s_pwm_top_outputs(i).en_wr_config
            );
    end generate gen_pwm_top_nom;

    -- Módulos PWM redundantes 1
    gen_pwm_top_red_1 : for i in 0 to (G_PWM_N - 1) generate
        pwm_red_1_i : entity work.pwm_top
            generic map (
                G_DATA_W        => G_STATE_MAX_L2,
                G_ADDR_W        => G_MEM_SIZE_MAX_L2,
                G_MAX_PUL_W     => G_PERIOD_MAX_L2,
                G_MEM_DEPTH     => G_MEM_SIZE_MAX_N,
                G_MEM_MODE      => "LOW_LATENCY",
                G_RST_POL       => G_RST_POL
            )
            port map (
                CLK_I           => CLK_I,
                RST_I           => RST_I,
                EN_I            => s_pwm_top_inputs(i).en,
                UPD_MEM_I       => s_pwm_top_inputs(i).upd_mem,
                WR_EN_I         => s_pwm_top_inputs(i).wr_en,
                WR_ADDR_I       => s_pwm_top_inputs(i).wr_addr,
                WR_DATA_I       => s_pwm_top_inputs(i).wr_data,
                N_ADDR_I        => s_pwm_top_inputs(i).n_addr,
                N_TOT_CYC_I     => s_pwm_top_inputs(i).n_tot_cyc,
                PWM_INIT_I      => s_pwm_top_inputs(i).pwm_init,
                PWM_O           => s_pwm_top_outputs(i).pwm_red_1,
                EN_WR_CONFIG_O  => s_pwm_top_outputs(i).en_wr_config_red_1
            );
    end generate gen_pwm_top_red_1;

    -- Módulos PWM redundantes 2
    gen_pwm_top_red_2 : for i in 0 to (G_PWM_N - 1) generate
        pwm_red_2_i : entity work.pwm_top
            generic map (
                G_DATA_W        => G_STATE_MAX_L2,
                G_ADDR_W        => G_MEM_SIZE_MAX_L2,
                G_MAX_PUL_W     => G_PERIOD_MAX_L2,
                G_MEM_DEPTH     => G_MEM_SIZE_MAX_N,
                G_MEM_MODE      => "LOW_LATENCY",
                G_RST_POL       => G_RST_POL
            )
            port map (
                CLK_I           => CLK_I,
                RST_I           => RST_I,
                EN_I            => s_pwm_top_inputs(i).en,
                UPD_MEM_I       => s_pwm_top_inputs(i).upd_mem,
                WR_EN_I         => s_pwm_top_inputs(i).wr_en,
                WR_ADDR_I       => s_pwm_top_inputs(i).wr_addr,
                WR_DATA_I       => s_pwm_top_inputs(i).wr_data,
                N_ADDR_I        => s_pwm_top_inputs(i).n_addr,
                N_TOT_CYC_I     => s_pwm_top_inputs(i).n_tot_cyc,
                PWM_INIT_I      => s_pwm_top_inputs(i).pwm_init,
                PWM_O           => s_pwm_top_outputs(i).pwm_red_2,
                EN_WR_CONFIG_O  => s_pwm_top_outputs(i).en_wr_config_red_2
            );
    end generate gen_pwm_top_red_2;

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    gen_pwm_outputs : for i in 0 to (G_PWM_N - 1) generate
    begin
        PWMS_O(i) <= s_pwm_top_outputs(i).pwm;
    end generate gen_pwm_outputs;
    
    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- n/a

end architecture str;