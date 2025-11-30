-- Módulo: pwm_top test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 07.09.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm_top_tb is
end entity pwm_top_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_top_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_top is
        generic (
            G_STATE_MAX_L2      : natural   := 32;              -- Ancho de datos en bits
            G_MEM_SIZE_MAX_L2   : natural   := 32;              -- Ancho de direcciones en bits
            G_PERIOD_MAX_N      : natural   := 2**32 - 1;       -- Número máximo de periodos de reloj
            G_PERIOD_MAX_L2     : natural   := 32;              -- Tamaño del vector del número máximo de pulsos de una configuración
            G_MEM_SIZE_MAX_N    : natural   := 128;             -- Profundidad de memoria
            G_MEM_MODE          : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria
            G_RST_POL           : std_logic := '1'
        );
        port (
            CLK_I           : in std_logic;     
            RST_I           : in std_logic;
            -- Activación de memoria
            EN_I            : in std_logic;                                             -- Señal de habilitación del PWM
            UPD_MEM_I       : in std_logic;                                             -- Pulso de actualización de memoria
            -- Configuración de la memoria
            WR_EN_I         : in std_logic;                                             -- Enable de escritura
            WR_ADDR_I       : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Dirección de escritura
            WR_DATA_I       : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);       -- Dato de escritura
            N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados
            N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
            PWM_INIT_I      : in std_logic;                                             -- Valor inicial de salida
            -- Salidas
            PWM_O           : out std_logic;                                            -- Salida del PWM
            EN_WR_CONFIG_O  : out std_logic                                             -- Habilitación de configuración de memoria
        );
    end component pwm_top;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/C_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I            : std_logic;     
    signal RST_I            : std_logic;
    signal EN_I             : std_logic;                                            -- Señal de habilitación del PWM
    signal UPD_MEM_I        : std_logic;                                            -- Pulso de actualización de memoria
    signal WR_EN_I          : std_logic;                                            -- Enable de escritura
    signal WR_ADDR_I        : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de escritura
    signal WR_DATA_I        : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);      -- Dato de escritura
    signal N_ADDR_I         : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Número de estados
    signal N_TOT_CYC_I      : std_logic_vector((C_PERIOD_MAX_L2 - 1) downto 0);     -- Número total de ciclos que dura la configuración
    signal PWM_INIT_I       : std_logic;                                            -- Valor inicial de salida
    signal PWM_O            : std_logic;                                            -- Salida del PWM
    signal EN_WR_CONFIG_O   : std_logic;                                            -- Habilitación de configuración de memoria
    
    -- Soporte
    type memory is array (0 to (C_MEM_SIZE_MAX_N - 1)) of integer range 0 to C_STATE_MAX_N;
    shared variable v_mem       : memory := (others => 0);
    shared variable v_n_addr    : integer := 0;
    shared variable v_n_tot     : integer := 0;
    shared variable v_pwm_init  : std_logic := '0';
    signal cnt_pulse    : integer range 0 to C_STATE_MAX_N;

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
        signal rst      : out std_logic;
        signal en       : out std_logic;
        signal upd      : out std_logic;
        signal wr_en    : out std_logic;
        signal wr_data  : out std_logic_vector;
        signal wr_addr  : out std_logic_vector;
        signal n_addr   : out std_logic_vector;
        signal n_tot    : out std_logic_vector;
        signal pwm_init : out std_logic
    ) is
    begin
        rst         <= C_RST_POL;
        en          <= '0';
        upd         <= '0';
        wr_en       <= '0';
        wr_data     <= (others =>'0');
        wr_addr     <= (others =>'0');
        n_addr      <= (others =>'0');
        n_tot       <= (others =>'0');
        pwm_init    <= '0';
        p_wait(clk_period);
        rst     <= not C_RST_POL;
    end procedure reset;

    -- Set configuration
    procedure set_config (
        variable mem    : in memory;
        variable naddr  : in integer;
        variable ntot   : in integer;
        variable init   : in std_logic;
        signal wr_en    : out std_logic; 
        signal wr_addr  : out std_logic_vector; 
        signal wr_data  : out std_logic_vector; 
        signal n_addr   : out std_logic_vector; 
        signal n_tot    : out std_logic_vector; 
        signal pwm_init : out std_logic
    ) is
    begin
        n_addr      <= std_logic_vector(to_unsigned(naddr, n_addr'length));
        n_tot       <= std_logic_vector(to_unsigned(ntot, n_tot'length));
        pwm_init    <= init;
        for i in 0 to (naddr - 1) loop
            wr_en   <= '1';
            wr_addr <= std_logic_vector(to_unsigned(i, wr_addr'length));
            wr_data <= std_logic_vector(to_unsigned(mem(i), wr_data'length));
            p_wait(clk_period);
        end loop;
        wr_en       <= '0';
    end procedure set_config;

    -- Pulso
    procedure pulso (
        signal s    : out std_logic
    ) is
    begin
        s   <= '1';
        p_wait(clk_period);
        s   <= '0';
    end procedure pulso;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_top
        generic map (
            G_STATE_MAX_L2      => C_STATE_MAX_L2,
            G_MEM_SIZE_MAX_L2   => C_MEM_SIZE_MAX_L2,
            G_PERIOD_MAX_N      => C_PERIOD_MAX_N,
            G_PERIOD_MAX_L2     => C_PERIOD_MAX_L2,
            G_MEM_SIZE_MAX_N    => C_MEM_SIZE_MAX_N,
            G_MEM_MODE          => "LOW_LATENCY",
            G_RST_POL           => C_RST_POL  
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            UPD_MEM_I       => UPD_MEM_I,
            WR_EN_I         => WR_EN_I,
            WR_ADDR_I       => WR_ADDR_I,
            WR_DATA_I       => WR_DATA_I,
            N_ADDR_I        => N_ADDR_I,
            N_TOT_CYC_I     => N_TOT_CYC_I,
            PWM_INIT_I      => PWM_INIT_I,
            PWM_O           => PWM_O,
            EN_WR_CONFIG_O  => EN_WR_CONFIG_O
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

    -- Contador de pulsos
    P_CNT : process (CLK_I, RST_I, PWM_O, EN_WR_CONFIG_O)
    begin
        if (RST_I = C_RST_POL) then
            cnt_pulse   <= 0;
        elsif falling_edge(EN_WR_CONFIG_O) then
            cnt_pulse <= 1; 
        elsif PWM_O'event then
            cnt_pulse <= 1;
        elsif rising_edge(CLK_I) then
            cnt_pulse <= cnt_pulse + 1;   
        end if;
    end process P_CNT;

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
        reset(RST_I, EN_I, UPD_MEM_I, WR_EN_I, WR_ADDR_I, WR_DATA_I, N_ADDR_I, N_TOT_CYC_I, PWM_INIT_I);
        p_wait(10*clk_period);

        EN_I <= '1';
        p_wait(25*clk_period);

        ------------------------------
        -- Config 1
        ------------------------------
        sim <= x"43_4F_4E_46_20_31";    -- CONF 1

        v_n_addr    := 7;
        v_n_tot     := 52;
        v_pwm_init  := '1';
        v_mem := (
            0 => 1,
            1 => 9,
            2 => 19,
            3 => 8,
            4 => 4,
            5 => 8,
            6 => 3,
            others => 0);
        set_config(v_mem, v_n_addr, v_n_tot, v_pwm_init, WR_EN_I, WR_ADDR_I, WR_DATA_I, N_ADDR_I, N_TOT_CYC_I, PWM_INIT_I);

        p_wait(19*clk_period);
        pulso(UPD_MEM_I);

        p_wait(150*clk_period);

        ------------------------------
        -- Config 2
        ------------------------------
        sim <= x"43_4F_4E_46_20_32";    -- CONF 2

        v_n_addr    := 5;
        v_n_tot     := 13;
        v_pwm_init  := '0';
        v_mem := (
            0 => 5,
            1 => 2,
            2 => 1,
            3 => 1,
            4 => 4,
            others => 0);
        set_config(v_mem, v_n_addr, v_n_tot, v_pwm_init, WR_EN_I, WR_ADDR_I, WR_DATA_I, N_ADDR_I, N_TOT_CYC_I, PWM_INIT_I);

        p_wait(19*clk_period);
        pulso(UPD_MEM_I);

        p_wait(150*clk_period);

        ------------------------------
        -- Config 3
        ------------------------------
        sim <= x"43_4F_4E_46_20_33";    -- CONF 3

        v_n_addr    := 6;
        v_n_tot     := 9;
        v_pwm_init  := '0';
        v_mem := (
            0 => 1,
            1 => 3,
            2 => 1,
            3 => 2,
            4 => 1,
            5 => 1,
            others => 0);
        set_config(v_mem, v_n_addr, v_n_tot, v_pwm_init, WR_EN_I, WR_ADDR_I, WR_DATA_I, N_ADDR_I, N_TOT_CYC_I, PWM_INIT_I);

        p_wait(31*clk_period);
        pulso(UPD_MEM_I);

        p_wait(150*clk_period);

        ------------------------------
        -- Disenable
        ------------------------------
        sim <= x"44_49_53_45_4E_41";    -- DISENA
        EN_I <= '0';
        p_wait(25*clk_period);

        ------------------------------
        -- Renable
        ------------------------------
        sim <= x"45_4E_41_42_4C_45";    -- ENABLE
        EN_I <= '1';
        p_wait(25*clk_period);

        ------------------------------
        -- Reset
        ------------------------------
        sim <= x"52_45_53_45_54_20";    -- RESET
        reset(RST_I, EN_I, UPD_MEM_I, WR_EN_I, WR_ADDR_I, WR_DATA_I, N_ADDR_I, N_TOT_CYC_I, PWM_INIT_I);
        p_wait(25*clk_period);

        ------------------------------
        -- Renable
        ------------------------------
        sim <= x"45_4E_41_42_4C_45";    -- ENABLE
        EN_I <= '1';
        p_wait(25*clk_period);

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;