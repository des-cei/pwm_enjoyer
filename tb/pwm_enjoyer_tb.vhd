-- Módulo: pwm_enjoyer test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 05.11.2025

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
entity pwm_enjoyer_tb is
end entity pwm_enjoyer_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_enjoyer_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_enjoyer is
        generic (
            -- Valor activo del reset
            G_RST_POL           : std_logic := '1';
            -- Número máximo de pulsos que dura un estado
            G_STATE_MAX_N       : natural := 2**32 - 1;
            -- Tamaño del vector de número de pulsos de un estado {integer(ceil(log2(real(G_STATE_MAX_N))))}
            G_STATE_MAX_L2      : natural := 32;
            -- Número máximo de estados, tamaño máximo de la memoria
            G_MEM_SIZE_MAX_N    : natural := 128;
            -- Tamaño del vector del número de estados {integer(ceil(log2(real(G_MEM_SIZE_MAX_N))))}
            G_MEM_SIZE_MAX_L2   : natural := 32;
            -- Número máximo de ciclos de reloj que puede durar una configuración {G_STATE_MAX_N*G_MEM_SIZE_MAX_N}
            G_PERIOD_MAX_N      : natural := 2**32 - 1;
            -- Tamaño del vector del número máximo de ciclos de reloj {integer(ceil(log2(real(G_PERIOD_MAX_N))))}
            G_PERIOD_MAX_L2     : natural := 32;
            -- Número de PWMS
            G_PWM_N             : natural := 32
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
    end component pwm_enjoyer;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/C_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I                : std_logic;
    signal RST_I                : std_logic;
    signal REG_DIRECCIONES_I    : std_logic_vector(31 downto 0);
    signal REG_CONTROL_I        : std_logic_vector(31 downto 0);
    signal REG_WR_DATA_I        : std_logic_vector(31 downto 0);
    signal REG_WR_DATA_VALID_I  : std_logic_vector(31 downto 0);
    signal REG_N_ADDR_I         : std_logic_vector(31 downto 0);
    signal REG_N_TOT_CYC_I      : std_logic_vector(31 downto 0);
    signal REG_PWM_INIT_I       : std_logic_vector(31 downto 0);
    signal REG_REDUNDANCIAS_O   : std_logic_vector(31 downto 0);
    signal REG_ERRORES_O        : std_logic_vector(31 downto 0);
    signal REG_STATUS_O         : std_logic_vector(31 downto 0);
    signal PWMS_O               : std_logic_vector((C_PWM_N - 1) downto 0);

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Wait
    procedure p_wait (
        constant period : in time
    ) is
    begin
        wait for 0.99*period;
        wait until rising_edge(CLK_I);
    end procedure p_wait;

    -- Reset
    procedure reset (
        signal rst          : out std_logic;
        signal reg_dir      : out std_logic_vector;
        signal reg_con      : out std_logic_vector;
        signal reg_wr_d     : out std_logic_vector;
        signal reg_wr_d_v   : out std_logic_vector;
        signal reg_n_ad     : out std_logic_vector;
        signal reg_n_to     : out std_logic_vector;
        signal reg_init     : out std_logic_vector
    ) is
    begin
        rst         <= C_RST_POL;
        reg_dir     <= (others => '0');
        reg_con     <= (others => '0');
        reg_wr_d    <= (others => '0');
        reg_wr_d_v  <= (others => '0');
        reg_n_ad    <= (others => '0');
        reg_n_to    <= (others => '0');
        reg_init    <= (others => '0');
        p_wait(clk_period);
        rst         <= not C_RST_POL;
    end procedure reset;

    -- Registos write data
    procedure wr_data (
        constant data       : in integer;
        signal wr_data      : out std_logic_vector;
        signal wr_data_en   : out std_logic_vector    
    ) is 
    begin
        wr_data     <= std_logic_vector(to_unsigned(data, 32));
        wr_data_en  <= x"00000001";
        p_wait(clk_period);
        wr_data_en  <= x"00000000";
        p_wait(clk_period);
    end procedure wr_data;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_enjoyer
        generic map (
            G_RST_POL           => C_RST_POL,
            G_STATE_MAX_N       => C_STATE_MAX_N,
            G_STATE_MAX_L2      => C_STATE_MAX_L2,
            G_MEM_SIZE_MAX_N    => C_MEM_SIZE_MAX_N,
            G_MEM_SIZE_MAX_L2   => C_MEM_SIZE_MAX_L2,
            G_PERIOD_MAX_N      => C_PERIOD_MAX_N,
            G_PERIOD_MAX_L2     => C_PERIOD_MAX_L2,
            G_PWM_N             => C_PWM_N
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
            PWMS_O              => PWMS_O
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK : process
    begin
        CLK_I <= '0';
        wait for clk_period/2;
        CLK_I <= '1';
        wait for clk_period/2;
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";    -- INIT
        reset(RST_I, REG_DIRECCIONES_I, REG_CONTROL_I, REG_WR_DATA_I, REG_WR_DATA_VALID_I, REG_N_ADDR_I, REG_N_TOT_CYC_I, REG_PWM_INIT_I);
        p_wait(10*clk_period);

        ------------------------------
        -- Configurar los PWM múltiplos de 1
        -- Estados: 5,6,7,8
        ------------------------------
        sim <= x"43_4F_4E_46_25_31";    -- CONF%1

        REG_DIRECCIONES_I   <= x"11111111";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"0000001A";
        REG_PWM_INIT_I      <= x"00000000";

        p_wait(clk_period);

        wr_data(5, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(6, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(7, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(8, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        ------------------------------
        -- Configurar los PWM múltiplos de 2
        -- Estados: 1,3,5,7,9
        ------------------------------
        sim <= x"43_4F_4E_46_25_32";    -- CONF%2

        REG_DIRECCIONES_I   <= x"22222222";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000005";
        REG_N_TOT_CYC_I     <= x"00000019";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(3, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(5, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(7, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(9, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        ------------------------------
        -- Configurar los PWM múltiplos de 3
        -- Estados: 1,1,2,2,1,1
        ------------------------------
        sim <= x"43_4F_4E_46_25_33";    -- CONF%3

        REG_DIRECCIONES_I   <= x"44444444";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000006";
        REG_N_TOT_CYC_I     <= x"00000008";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        ------------------------------
        -- Aplicar configuraciones en todos los módulos
        ------------------------------
        sim <= x"55_50_44_41_54_45";    -- UPDATE

        p_wait(10*clk_period);
        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000004";
        p_wait(10*clk_period);

        ------------------------------
        -- Esperar
        ------------------------------
        sim <= x"45_53_50_45_52_41";    -- ESPERA

        REG_CONTROL_I       <= x"00000000";
        p_wait(50*clk_period);

        ------------------------------
        -- Apagar los primeros 6 PWMS
        ------------------------------
        sim <= x"41_50_41_47_20_36";    -- APAG 6

        REG_DIRECCIONES_I   <= x"0000003F";
        REG_CONTROL_I       <= x"00000002";
        p_wait(50*clk_period);

        ------------------------------
        -- Configurar todos los PWM
        -- Estados: 3,2,1
        ------------------------------
        sim <= x"43_4F_4E_46_20_2A";    -- CONF *

        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000003";
        REG_N_TOT_CYC_I     <= x"00000006";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(3, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        ------------------------------
        -- Aplicar configuraciones en todos los módulos
        ------------------------------
        sim <= x"55_50_44_41_54_45";    -- UPDATE

        p_wait(10*clk_period);
        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000004";
        p_wait(30*clk_period);

        ------------------------------
        -- Apagar todos
        ------------------------------
        sim <= x"53_48_55_54_44_57";    -- SHUTDW

        REG_CONTROL_I       <= x"00000001";
        p_wait(50*clk_period);

        ------------------------------
        -- Configurar todos los PWM pares
        -- Estados: 10,5
        ------------------------------
        sim <= x"43_4F_4E_46_3D_32";    -- CONF=2

        REG_DIRECCIONES_I   <= x"55555555";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000002";
        REG_N_TOT_CYC_I     <= x"0000000F";
        REG_PWM_INIT_I      <= x"00000000";

        p_wait(clk_period);

        wr_data(10, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(5, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        ------------------------------
        -- Aplicar configuraciones en todos los módulos
        ------------------------------
        sim <= x"55_50_44_41_54_45";    -- UPDATE

        p_wait(10*clk_period);
        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000004";
        p_wait(10*clk_period);

        ------------------------------
        -- Esperar
        ------------------------------
        sim <= x"45_53_50_45_52_41";    -- ESPERA

        REG_CONTROL_I       <= x"00000000";
        p_wait(50*clk_period);

        ------------------------------
        -- Error de configuración
        --  Se programa 0 incorrectamente (1,1,1,1)
        --  Se programa 1 correctamente (2,2,2,2)
        --  Se aplica la configuración
        ------------------------------
        sim <= x"43_4F_20_45_52_52";    -- CO ERR

        -- Configurar 1
        REG_DIRECCIONES_I   <= x"00000001";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"00000008"; -- Error
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Configurar 2
        REG_DIRECCIONES_I   <= x"00000002";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"00000008";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Updatear
        p_wait(2*clk_period);
        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000004";

        p_wait(50*clk_period);

        ------------------------------
        -- Correción del error
        --  Se programa 0 correctamente (1,1,1,1)
        --  Se programa 1 correctamente (2,2,2,2)
        --  Se aplica la configuración
        ------------------------------
        sim <= x"43_4F_52_52_45_43";    -- CORREC

        -- Configurar 1
        REG_DIRECCIONES_I   <= x"00000001";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"00000004"; -- Corregido
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Updatear
        p_wait(2*clk_period);
        REG_DIRECCIONES_I   <= x"FFFFFFFF";
        REG_CONTROL_I       <= x"00000004";

        p_wait(50*clk_period);
        
        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;