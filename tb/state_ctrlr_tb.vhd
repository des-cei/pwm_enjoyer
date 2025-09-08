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
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I           : in std_logic;
            RST_I           : in std_logic;                                             -- Reset asíncrono
            EN_I            : in std_logic;                                             -- Señal de habilitación
            N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
            N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
            UPD_MEM_I       : in std_logic;                                             -- Señal de actualización de memoria
            CNT_END_I       : in std_logic;                                             -- Fin de estado
            NEXT_CONFIG_I   : in mem;                                                   -- Siguiente configuración
            RD_ADDR_O       : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de memoria (estado) a leer
            EN_CNT_O        : out std_logic;                                            -- Habiltador del contador
            SWITCH_MEM_O    : out std_logic;                                            -- Cambio de memoria
            LAST_CYC_O      : out std_logic;                                            -- Inidicador de último ciclo
            EN_WR_CONFIG_O  : out std_logic                                             -- Bloqueo de escritura de configuración
        );
    end component state_ctrlr;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I            : std_logic;
    signal RST_I            : std_logic;                                         
    signal EN_I             : std_logic;                                         
    signal N_ADDR_I         : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal N_TOT_CYC_I      : std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);
    signal UPD_MEM_I        : std_logic;
    signal NEXT_CONFIG_I    : mem;                                         
    signal CNT_END_I        : std_logic;                                         
    signal RD_ADDR_O        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal EN_CNT_O         : std_logic;                                         
    signal SWITCH_MEM_O     : std_logic;
    signal LAST_CYC_O       : std_logic;
    signal EN_WR_CONFIG_O   : std_logic;

    -- Soporte
    type memory is array (0 to (G_MEM_SIZE_MAX_N - 1)) of integer range 0 to G_STATE_MAX_N;
    shared variable v_mem       : memory := (others => 0);
    signal cnt_data_sim         : integer range 0 to G_STATE_MAX_N := 0;
    signal data_sim             : integer range 0 to G_MEM_SIZE_MAX_N := 0;
    signal internal_n_addr      : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');  
    signal internal_n_tot_cyc   : std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0) := (others => '0'); 
    signal internal_mem         : memory := (others => 0);

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
        signal config   : out mem
    ) is
    begin
        rst     <= G_RST_POL;
        en      <= '0';
        n_addr  <= (others => '0');
        n_tot   <= (others => '0');
        upd     <= '0';
        config  <= (others => (others => '0'));
        p_wait(clk_period);
        rst     <= not G_RST_POL;
    end procedure reset;

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
    uut : component state_ctrlr
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            N_ADDR_I        => N_ADDR_I,
            N_TOT_CYC_I     => N_TOT_CYC_I,
            UPD_MEM_I       => UPD_MEM_I,
            CNT_END_I       => CNT_END_I,
            NEXT_CONFIG_I   => NEXT_CONFIG_I,
            RD_ADDR_O       => RD_ADDR_O,
            EN_CNT_O        => EN_CNT_O,
            SWITCH_MEM_O    => SWITCH_MEM_O,
            LAST_CYC_O      => LAST_CYC_O,
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

    -- Emulador del contador y señal de END
    P_CNT : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            cnt_data_sim     <= 0;
            data_sim      <= 0;
        elsif rising_edge(CLK_I) then
            if (EN_CNT_O = '1') then
                if (cnt_data_sim < (internal_mem(data_sim) - 1)) then
                    cnt_data_sim     <= cnt_data_sim + 1;
                else
                    cnt_data_sim     <= 0;
                    if (data_sim < (to_integer(unsigned(internal_n_addr)) - 1)) then
                        data_sim <= data_sim + 1;
                    else
                        data_sim  <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;

    CNT_END_I <= '1' when (EN_CNT_O = '1') and (cnt_data_sim = (internal_mem(data_sim) - 1)) else '0';

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
        variable v_n_est    : integer := 0;
        variable v_n_tot    : integer := 0;
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";    -- INIT
        reset(RST_I, EN_I, N_ADDR_I, N_TOT_CYC_I, UPD_MEM_I, NEXT_CONFIG_I);
        p_wait(10*clk_period);

        EN_I <= '1';

        ------------------------------
        -- Config 1
        ------------------------------
        sim <= x"43_4F_4E_46_20_31";    -- CONF 1
        
        v_n_est         := 4;
        v_n_tot         := 10;
        v_mem           := (0 => 3, 1 => 1, 2 => 2, 3 => 4, others => 0);
        N_ADDR_I        <= std_logic_vector(to_unsigned(v_n_est, N_ADDR_I'length));
        N_TOT_CYC_I     <= std_logic_vector(to_unsigned(v_n_tot, N_TOT_CYC_I'length));
        for i in 0 to (G_MEM_SIZE_MAX_N - 1) loop
            NEXT_CONFIG_I(i) <= std_logic_vector(to_unsigned(v_mem(i), NEXT_CONFIG_I(i)'length));
        end loop;

        p_wait(10*clk_period);

        ------------------------------
        -- Update 1
        ------------------------------
        sim <= x"55_50_44_54_20_31";    -- UPDT 1
        
        pulso(UPD_MEM_I);

        -- wait until (SWITCH_MEM_O = '1');
        wait until falling_edge(SWITCH_MEM_O);
        -- internal_n_addr     <= N_ADDR_I;
        internal_n_tot_cyc  <= N_TOT_CYC_I;
        internal_mem        <= v_mem;
        p_wait(clk_period);
        internal_n_addr     <= N_ADDR_I;
        
        p_wait(60*clk_period);
        
        ------------------------------
        -- Config 2
        ------------------------------
        sim <= x"43_4F_4E_46_20_32";    -- CONF 2
        
        v_n_est     := 2;
        v_n_tot     := 7;
        v_mem       := (0 => 2, 1 => 5, others => 0);
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_est, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot, N_TOT_CYC_I'length));
        for i in 0 to (G_MEM_SIZE_MAX_N - 1) loop
            NEXT_CONFIG_I(i) <= std_logic_vector(to_unsigned(v_mem(i), NEXT_CONFIG_I(i)'length));
        end loop;

        p_wait(10*clk_period);

        ------------------------------
        -- Update 2
        ------------------------------
        sim <= x"55_50_44_54_20_32";    -- UPDT 2
        
        pulso(UPD_MEM_I);

        -- wait until (SWITCH_MEM_O = '1');
        wait until falling_edge(SWITCH_MEM_O);
        -- internal_n_addr     <= N_ADDR_I;
        internal_n_tot_cyc  <= N_TOT_CYC_I;
        internal_mem        <= v_mem;
        p_wait(clk_period);
        internal_n_addr     <= N_ADDR_I;
        
        p_wait(60*clk_period);

        ------------------------------
        -- Config 3
        ------------------------------
        sim <= x"43_4F_4E_46_20_33";    -- CONF 3
        
        v_n_est     := 5;
        v_n_tot     := 9;
        v_mem       := (0 => 1, 1 => 1, 2 => 5, 3 => 1, 4 => 1, others => 0);
        N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_est, N_ADDR_I'length));
        N_TOT_CYC_I <= std_logic_vector(to_unsigned(v_n_tot, N_TOT_CYC_I'length));
        for i in 0 to (G_MEM_SIZE_MAX_N - 1) loop
            NEXT_CONFIG_I(i) <= std_logic_vector(to_unsigned(v_mem(i), NEXT_CONFIG_I(i)'length));
        end loop;

        p_wait(10*clk_period);

        ------------------------------
        -- Update 3
        ------------------------------
        sim <= x"55_50_44_54_20_33";    -- UPDT 3
        
        pulso(UPD_MEM_I);

        -- wait until (SWITCH_MEM_O = '1');
        wait until falling_edge(SWITCH_MEM_O);
        -- internal_n_addr     <= N_ADDR_I;
        internal_n_tot_cyc  <= N_TOT_CYC_I;
        internal_mem        <= v_mem;
        p_wait(clk_period);
        internal_n_addr     <= N_ADDR_I;
        
        p_wait(60*clk_period);

        ------------------------------
        -- Disenable
        ------------------------------
        sim <= x"44_49_53_45_4E_41";    -- DISENA
        EN_I <= '0';
        p_wait(30*clk_period);

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;