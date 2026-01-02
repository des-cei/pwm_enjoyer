-- Módulo: state_ctrlr test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.06.2025

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
entity state_ctrlr_tb is
end entity state_ctrlr_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of state_ctrlr_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component state_ctrlr is
        generic (
            G_RST_POL           : std_logic := '1';
            G_MEM_SIZE_MAX_L2   : natural := 32;        -- Tamaño del vector del número máximo de estados
            G_PERIOD_MAX_L2     : natural := 32         -- Tamaño del vector del número máximo de periodos de reloj de una configuración
        );
        port (
            CLK_I           : in std_logic;
            RST_I           : in std_logic;                                             -- Reset asíncrono
            EN_I            : in std_logic;                                             -- Señal de habilitación
            N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
            N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
            UPD_MEM_I       : in std_logic;                                             -- Señal de actualización de memoria
            CNT_END_I       : in std_logic;                                             -- Fin de estado
            CNT_END_PRE_I   : in std_logic;                                             -- Fin de estado anticipado
            EARLY_SW_I      : in std_logic;                                             -- Protección ante SWITCH sin configuración previa
            RD_ADDR_O       : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de memoria (estado) a leer
            EN_CNT_O        : out std_logic;                                            -- Habiltador del contador
            SWITCH_MEM_O    : out std_logic;                                            -- Cambio de memoria
            LAST_CYC_O      : out std_logic;                                            -- Indicador de último ciclo
            UNLOCKED_O      : out std_logic;                                            -- Bloqueo de escritura de configuración
            STATUS_O        : out std_logic_vector(1 downto 0)                          -- Estado (00 = Apagado, 01 = Apagando, 11 = Activo)
    );
    end component state_ctrlr;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/C_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I            : std_logic;
    signal RST_I            : std_logic;                                         
    signal EN_I             : std_logic;                                         
    signal N_ADDR_I         : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal N_TOT_CYC_I      : std_logic_vector((C_PERIOD_MAX_L2 - 1) downto 0);
    signal UPD_MEM_I        : std_logic;
    signal CNT_END_I        : std_logic;                                         
    signal CNT_END_PRE_I    : std_logic;                                         
    signal EARLY_SW_I       : std_logic;                                         
    signal RD_ADDR_O        : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal EN_CNT_O         : std_logic;                                         
    signal SWITCH_MEM_O     : std_logic;
    signal LAST_CYC_O       : std_logic;
    signal UNLOCKED_O       : std_logic;
    signal STATUS_O         : std_logic_vector(1 downto 0);

    -- CNT Port map
    signal DATA_I           : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
    signal DATA_NEXT_I      : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
    signal DATA_NEXT_2_I    : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
    signal PWM_INIT_I       : std_logic;
    signal PWM_O            : std_logic;

    -- MEM Port map
    signal WR_EN_I          : std_logic;
    signal WR_ADDR_I        : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal WR_DATA_I        : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);

    -- Soporte
    type memory is array (0 to (C_MEM_SIZE_MAX_N - 1)) of integer range 0 to (2**31 - 1);
    shared variable v_mem       : memory := (others => 0);
    shared variable v_n_addr    : integer := 0;
    shared variable v_n_tot_cyc : integer := 0;

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
        signal n_addr   : out std_logic_vector;
        signal n_tot    : out std_logic_vector;
        signal upd      : out std_logic;
        signal pwm_init : out std_logic;
        signal wr_en    : out std_logic;
        signal wr_addr  : out std_logic_vector;
        signal wr_data  : out std_logic_vector
    ) is
    begin
        rst         <= C_RST_POL;
        en          <= '0';
        n_addr      <= (others => '0');
        n_tot       <= (others => '0');
        upd         <= '0';
        pwm_init    <= '0';
        wr_en       <= '0';
        wr_addr     <= (others => '0');
        wr_data     <= (others => '0');
        p_wait(clk_period);
        rst         <= not C_RST_POL;
    end procedure reset;

    -- Pulso
    procedure pulso (
        signal sig  : out std_logic
    ) is
    begin
        sig <= '1';
        p_wait(clk_period);
        sig <= '0';
    end procedure pulso;

    -- Write config
    procedure wr_config (
        variable mem        : in memory;
        variable mem_len    : in integer;
        constant pulses     : in integer;   -- Pulsos de seperación entre wr_en
        signal wr_en        : out std_logic;
        signal wr_addr      : out std_logic_vector;
        signal wr_data      : out std_logic_vector
    ) is
    begin
        for i in 0 to (mem_len - 1) loop
            wr_en   <= '1';
            wr_addr <= std_logic_vector(to_unsigned(i, wr_addr'length));
            wr_data <= std_logic_vector(to_unsigned(mem(i), wr_data'length));
            if (pulses = 0) then
                p_wait(clk_period);
            else
                p_wait(clk_period);
                wr_en   <= '0';
                p_wait(pulses*clk_period);
            end if;
        end loop;
        wr_en <= '0';
    end procedure wr_config;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component state_ctrlr
        generic map (
            G_RST_POL           => C_RST_POL,
            G_MEM_SIZE_MAX_L2   => C_MEM_SIZE_MAX_L2,
            G_PERIOD_MAX_L2     => C_PERIOD_MAX_L2
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            N_ADDR_I        => N_ADDR_I,
            N_TOT_CYC_I     => N_TOT_CYC_I,
            UPD_MEM_I       => UPD_MEM_I,
            CNT_END_I       => CNT_END_I,
            CNT_END_PRE_I   => CNT_END_PRE_I,
            EARLY_SW_I      => EARLY_SW_I,
            RD_ADDR_O       => RD_ADDR_O,
            EN_CNT_O        => EN_CNT_O,
            SWITCH_MEM_O    => SWITCH_MEM_O,
            LAST_CYC_O      => LAST_CYC_O,
            UNLOCKED_O      => UNLOCKED_O,
            STATUS_O        => STATUS_O
        );

    cnt : entity work.pwm_counter
        generic map (
            G_RST_POL       => C_RST_POL,
            G_STATE_MAX_L2  => C_STATE_MAX_L2
        )
        port map (
            CLK_I               => CLK_I,
            RST_I               => RST_I,
            EN_I                => EN_CNT_O,
            CNT_LEN_I           => DATA_I,
            CNT_LEN_NEXT_I      => DATA_NEXT_I,
            CNT_LEN_NEXT_2_I    => DATA_NEXT_2_I,
            SWITCH_MEM_I        => SWITCH_MEM_O,
            PWM_INIT_I          => PWM_INIT_I,
            PWM_O               => PWM_O,
            CNT_END_O           => CNT_END_I,
            CNT_END_PRE_O       => CNT_END_PRE_I
        );

    mem : entity work.pwm_dp_mem
        generic map (
            G_DATA_W    => C_STATE_MAX_L2,
            G_ADDR_W    => C_MEM_SIZE_MAX_L2,
            G_MEM_DEPTH => C_MEM_SIZE_MAX_N,
            G_MEM_MODE  => "LOW_LATENCY",
            G_RST_POL   => C_RST_POL
        )
        port map (
            CLK_I               => CLK_I,
            RST_I               => RST_I,
            EN_I                => EN_I,
            UNLOCKED_I          => UNLOCKED_O,
            WR_EN_I             => WR_EN_I,
            WR_ADDR_I           => WR_ADDR_I,
            WR_DATA_I           => WR_DATA_I,
            SWITCH_MEM_I        => SWITCH_MEM_O,
            LAST_CYC_I          => LAST_CYC_O,
            N_ADDR_I            => N_ADDR_I,
            RD_ADDR_I           => RD_ADDR_O,
            RD_DATA_O           => DATA_I, 
            RD_DATA_NEXT_O      => DATA_NEXT_I,
            RD_DATA_NEXT_2_O    => DATA_NEXT_2_I,
            EARLY_SW_O          => EARLY_SW_I
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
        reset(RST_I, EN_I, N_ADDR_I, N_TOT_CYC_I, UPD_MEM_I, PWM_INIT_I, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(10*clk_period);

        EN_I <= '1';

        p_wait(10*clk_period);

        ------------------------------
        -- Config 1
        ------------------------------
        sim <= x"43_4F_4E_46_20_31";    -- CONF 1

        v_n_addr    := 4;
        v_n_tot_cyc := 10;
        v_mem := (  0 => 4,
                    1 => 1,
                    2 => 3,
                    3 => 2,
                    others => 0);
        PWM_INIT_I  <= '1';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Config 2
        ------------------------------
        sim <= x"43_4F_4E_46_20_32";    -- CONF 2

        v_n_addr    := 3;
        v_n_tot_cyc := 8;
        v_mem := (  0 => 2,
                    1 => 1,
                    2 => 5,
                    others => 0);
        PWM_INIT_I  <= '0';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Config 3
        ------------------------------
        sim <= x"43_4F_4E_46_20_33";    -- CONF 3

        v_n_addr    := 4;
        v_n_tot_cyc := 6;
        v_mem := (  0 => 1,
                    1 => 2,
                    2 => 2,
                    3 => 1,
                    others => 0);
        PWM_INIT_I  <= '1';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Config 4
        ------------------------------
        sim <= x"43_4F_4E_46_20_34";    -- CONF 4

        v_n_addr    := 5;
        v_n_tot_cyc := 5;
        v_mem := (  0 => 1,
                    1 => 1,
                    2 => 1,
                    3 => 1,
                    4 => 1,
                    others => 0);
        PWM_INIT_I  <= '1';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Config 5
        ------------------------------
        sim <= x"43_4F_4E_46_20_35";    -- CONF 5

        v_n_addr    := 2;
        v_n_tot_cyc := 6;
        v_mem := (  0 => 2,
                    1 => 4,
                    others => 0);
        PWM_INIT_I  <= '1';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Apagar
        ------------------------------
        sim <= x"41_50_41_47_41_52";    -- APAGAR

        EN_I <= '0';

        p_wait(20*clk_period);

        ------------------------------
        -- Reiniciar
        ------------------------------
        sim <= x"41_50_41_47_41_52";    -- APAGAR

        EN_I <= '1';

        p_wait(clk_period);

        ------------------------------
        -- Config 6
        ------------------------------
        sim <= x"43_4F_4E_46_20_36";    -- CONF 6

        v_n_addr    := 2;
        v_n_tot_cyc := 3;
        v_mem := (  0 => 1,
                    1 => 2,
                    others => 0);
        PWM_INIT_I  <= '0';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- Reset
        ------------------------------
        sim <= x"52_45_53_45_54_20";    -- RESET
        reset(RST_I, EN_I, N_ADDR_I, N_TOT_CYC_I, UPD_MEM_I, PWM_INIT_I, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        EN_I <= '1';

        p_wait(clk_period);

        ------------------------------
        -- Config 7
        ------------------------------
        sim <= x"43_4F_4E_46_20_37";    -- CONF 7

        v_n_addr    := 3;
        v_n_tot_cyc := 3;
        v_mem := (  0 => 1,
                    1 => 1,
                    2 => 1,
                    others => 0);
        PWM_INIT_I  <= '0';
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_addr, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot_cyc, N_TOT_CYC_I'length));
        wr_config(v_mem, v_n_addr, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update
        pulso(UPD_MEM_I);

        p_wait(50*clk_period);

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;