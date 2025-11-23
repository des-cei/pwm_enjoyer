-- Módulo: control_unit test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 25.10.2025

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
entity control_unit_tb is
end entity control_unit_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of control_unit_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component control_unit is
        generic (
            G_RST_POL   : std_logic := '1';
            G_PWM_N     : integer := 32     -- Número máximo de módulos PWM. Si hay más de 32 hay que añadir más registros (*)
        );
        port (
            CLK_I               : in std_logic;
            RST_I               : in std_logic;
            -- Registros
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
            -- I/O de los módulos PWM
            PWM_TOP_INPUTS_O    : out modulo_pwm_in;    -- Array de G_PWM_N de las entradas a cada pwm_top
            PWM_TOP_OUTPUTS_I   : in modulo_pwm_out     -- Array de G_PWM_N de las salidas de cada pwm_top
        );
    end component control_unit;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
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
    signal PWM_TOP_INPUTS_O     : modulo_pwm_in;
    signal PWM_TOP_OUTPUTS_I    : modulo_pwm_out;

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
        signal reg_init     : out std_logic_vector;
        signal pwm_out      : out modulo_pwm_out
    ) is
    begin
        rst         <= G_RST_POL;
        reg_dir     <= (others => '0');
        reg_con     <= (others => '0');
        reg_wr_d    <= (others => '0');
        reg_wr_d_v  <= (others => '0');
        reg_n_ad    <= (others => '0');
        reg_n_to    <= (others => '0');
        reg_init    <= (others => '0');
        for i in 0 to (G_PWM_N - 1) loop
            pwm_out(i).pwm                  <= '0';
            pwm_out(i).en_wr_config         <= '1';
            pwm_out(i).pwm_red_1            <= '0';
            pwm_out(i).en_wr_config_red_1   <= '1';
            pwm_out(i).pwm_red_2            <= '0';
            pwm_out(i).en_wr_config_red_2   <= '1';
        end loop;
        p_wait(clk_period);
        rst         <= not G_RST_POL;
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

    -- Serializar vector
    procedure serial (
        constant vector_1   : in std_logic_vector;
        signal bit_1        : out std_logic;
        constant vector_2   : in std_logic_vector;
        signal bit_2        : out std_logic;
        constant vector_3   : in std_logic_vector;
        signal bit_3        : out std_logic
    ) is
    begin
        for i in 0 to (vector_1'length - 1) loop
            bit_1 <= vector_1(vector_1'high - i);
            bit_2 <= vector_2(vector_2'high - i);
            bit_3 <= vector_3(vector_3'high - i);
            p_wait(clk_period);
        end loop;
    end procedure serial;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component control_unit
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
            PWM_TOP_INPUTS_O    => PWM_TOP_INPUTS_O,
            PWM_TOP_OUTPUTS_I   => PWM_TOP_OUTPUTS_I
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
        reset(RST_I, REG_DIRECCIONES_I, REG_CONTROL_I, REG_WR_DATA_I, REG_WR_DATA_VALID_I, REG_N_ADDR_I, REG_N_TOT_CYC_I, REG_PWM_INIT_I, PWM_TOP_OUTPUTS_I);
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
        p_wait(10*clk_period);

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
        -- Se intenta programar cuando 1/3 no da EN_WR_CONFIG
        --  Disparidad en 1
        --  Correcto en 2
        ------------------------------
        sim <= x"45_4E_57_52_43_46";    -- ENWRCF

        -- EN_WR_CONFIG
        PWM_TOP_OUTPUTS_I(0).en_wr_config          <= '1';
        PWM_TOP_OUTPUTS_I(0).en_wr_config_red_1    <= '1';
        PWM_TOP_OUTPUTS_I(0).en_wr_config_red_2    <= '0';
        PWM_TOP_OUTPUTS_I(1).en_wr_config          <= '1';
        PWM_TOP_OUTPUTS_I(1).en_wr_config_red_1    <= '1';
        PWM_TOP_OUTPUTS_I(1).en_wr_config_red_2    <= '1';

        p_wait(10*clk_period);

        -- Configurar 1 y 2
        REG_DIRECCIONES_I   <= x"00000003";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000006";
        REG_N_TOT_CYC_I     <= x"0000001B";
        REG_PWM_INIT_I      <= x"00000000";

        p_wait(clk_period);

        wr_data(2, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(3, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(4, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(5, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(6, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(7, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Updatear
        p_wait(2*clk_period);
        REG_DIRECCIONES_I   <= x"00000003";
        REG_CONTROL_I       <= x"00000004";

        p_wait(50*clk_period);

        ------------------------------
        -- Error en las redundancias
        --  Una redundancia puntual no implica error
        --  Cuando hay redundancia al aplicar la programación es cuando salta el error
        ------------------------------
        reset(RST_I, REG_DIRECCIONES_I, REG_CONTROL_I, REG_WR_DATA_I, REG_WR_DATA_VALID_I, REG_N_ADDR_I, REG_N_TOT_CYC_I, REG_PWM_INIT_I, PWM_TOP_OUTPUTS_I);

        sim <= x"52_45_44_55_4E_31";    -- REDUN1

        -- PWM
        serial (
            "11100001100", PWM_TOP_OUTPUTS_I(0).pwm,
            "11101101100", PWM_TOP_OUTPUTS_I(0).pwm_red_1,
            "11100001100", PWM_TOP_OUTPUTS_I(0).pwm_red_2
        );

        p_wait(10*clk_period);

        -- Configurar 1
        REG_DIRECCIONES_I   <= x"00000001";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"00000004";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Updatear 
        -- NOTE: Debe actualizar, pues la redundancia se ha dado antes de esta petición
        p_wait(2*clk_period);
        REG_DIRECCIONES_I   <= x"00000003";
        REG_CONTROL_I       <= x"00000004";

        p_wait(50*clk_period);

        reset(RST_I, REG_DIRECCIONES_I, REG_CONTROL_I, REG_WR_DATA_I, REG_WR_DATA_VALID_I, REG_N_ADDR_I, REG_N_TOT_CYC_I, REG_PWM_INIT_I, PWM_TOP_OUTPUTS_I);

        sim <= x"52_45_44_55_4E_32";    -- REDUN2

        -- PWM
        PWM_TOP_OUTPUTS_I(0).pwm        <= '1';
        PWM_TOP_OUTPUTS_I(0).pwm_red_1  <= '0';
        PWM_TOP_OUTPUTS_I(0).pwm_red_2  <= '1';

        p_wait(10*clk_period);

        -- Configurar 1
        REG_DIRECCIONES_I   <= x"00000001";
        REG_CONTROL_I       <= x"00000008";
        REG_N_ADDR_I        <= x"00000004";
        REG_N_TOT_CYC_I     <= x"00000004";
        REG_PWM_INIT_I      <= x"00000001";

        p_wait(clk_period);

        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);
        wr_data(1, REG_WR_DATA_I, REG_WR_DATA_VALID_I);

        -- Updatear 
        -- NOTE: No debe actualizar
        p_wait(2*clk_period);
        REG_DIRECCIONES_I   <= x"00000003";
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