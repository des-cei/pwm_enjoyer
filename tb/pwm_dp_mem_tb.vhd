-- Módulo: pwm_dp_mem test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 07.07.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm_dp_mem_tb is
end entity pwm_dp_mem_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_dp_mem_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_dp_mem is
        generic (
            G_DATA_W    : integer   := 32;    -- Ancho de datos en bits (G_STATE_MAX_L2)
            G_ADDR_W    : integer   := 32;    -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
            G_MEM_DEPTH : integer   := 4096;  -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
            G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I           : in std_logic;     
            RST_I           : in std_logic;
            EN_WR_CONFIG_I  : in std_logic;                                     -- Bloqueo de escritura de configuración
            WR_EN_I         : in std_logic;                                     -- Enable de escritura
            WR_ADDR_I       : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de escritura
            WR_DATA_I       : in std_logic_vector((G_DATA_W - 1) downto 0);     -- Dato de escritura
            SWITCH_MEM_I    : in std_logic;                                     -- Señal de actualización de memoria
            LAST_CYC_I      : in std_logic;                                     -- Indicador de último valor del último ciclo
            N_ADDR_I        : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Número de estados del PWM
            RD_ADDR_I       : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de lectura
            RD_DATA_O       : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Dato de lectura
            RD_DATA_NEXT_O  : out std_logic_vector((G_DATA_W - 1) downto 0);    -- Siguiente dato de lectura
            NEXT_CONFIG_O   : out mem                                           -- Siguiente configuración
        );
    end component pwm_dp_mem;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I            : std_logic;     
    signal RST_I            : std_logic;
    signal EN_WR_CONFIG_I   : std_logic;                                
    signal WR_EN_I          : std_logic;                                
    signal WR_ADDR_I        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal WR_DATA_I        : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal SWITCH_MEM_I     : std_logic;                                
    signal LAST_CYC_I       : std_logic;    
    signal N_ADDR_I         : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);                            
    signal RD_ADDR_I        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');
    signal RD_DATA_O        : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal RD_DATA_NEXT_O   : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal NEXT_CONFIG_O    : mem;

    -- Soporte
    type memory is array (0 to (G_MEM_SIZE_MAX_N - 1)) of integer range 0 to G_STATE_MAX_N;
    signal act_mem              : memory := (others => 0);
    signal act_mem_d1           : memory := (others => 0);
    signal next_mem             : memory := (others => 0);
    constant empty_mem          : memory := (others => 0);
    shared variable v_load_mem  : std_logic := '0';
    shared variable v_mem       : memory := (others => 0);
    shared variable v_n_estados : integer := 0;
    signal cnt                  : integer range 0 to G_STATE_MAX_N; -- Contador de RD_ADDR_I
    signal cnt_out              : integer range 0 to G_STATE_MAX_N; -- Contador que debería seguir RD_DATA_O

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

    -- Write mem
    procedure write_mem (
        variable mem    : in memory;
        variable n_est  : in integer;  
        signal en       : out std_logic;
        signal addr     : out std_logic_vector;
        signal data     : out std_logic_vector
    ) is
    begin
        en <= '1';
        for i in 0 to (n_est - 1) loop
            addr <= std_logic_vector(to_unsigned(i, addr'length));
            data <= std_logic_vector(to_unsigned(mem(i), data'length));
            p_wait(clk_period);
        end loop;
        en <= '0';
    end procedure write_mem;

    -- Espera 1 estado
    procedure wait_est (
        constant addr   : in integer;
        signal tiempo   : in integer;
        variable last   : in boolean;
        signal rd_addr  : out std_logic_vector;
        signal switch   : out std_logic
    ) is 
    begin
        rd_addr <= std_logic_vector(to_unsigned(addr, rd_addr'length));
        if (tiempo > 1) then
            p_wait((tiempo - 1)*clk_period);
        end if;
        if (last = true) then
            switch  <= '1';
        end if;
        p_wait(clk_period);
        switch <= '0';
    end procedure wait_est;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_dp_mem
        generic map (
            G_DATA_W    => G_STATE_MAX_L2,
            G_ADDR_W    => G_MEM_SIZE_MAX_L2,
            G_MEM_DEPTH => G_MEM_SIZE_MAX_N,
            G_MEM_MODE  => "LOW_LATENCY",
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_WR_CONFIG_I  => EN_WR_CONFIG_I,
            WR_EN_I         => WR_EN_I,
            WR_ADDR_I       => WR_ADDR_I,
            WR_DATA_I       => WR_DATA_I,
            SWITCH_MEM_I    => SWITCH_MEM_I,
            LAST_CYC_I      => LAST_CYC_I,
            N_ADDR_I        => N_ADDR_I,
            RD_ADDR_I       => RD_ADDR_I,
            RD_DATA_O       => RD_DATA_O, 
            RD_DATA_NEXT_O  => RD_DATA_NEXT_O,
            NEXT_CONFIG_O   => NEXT_CONFIG_O 
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

    -- Edge
    P_EDGE : process (CLK_I)
    begin
        if rising_edge(CLK_I) then
            act_mem_d1  <= act_mem;
            cnt_out     <= cnt;
        end if;
    end process P_EDGE;

    -- Carga de memoria
    P_MEM : process
    begin
        if (RST_I = G_RST_POL) then
            WR_EN_I     <= '0';
            WR_ADDR_I   <= (others => '0');
            WR_DATA_I   <= (others => '0');
            N_ADDR_I    <= (others => '0');
        elsif (v_load_mem = '1') then
            if (EN_WR_CONFIG_I = '1') then
                N_ADDR_I    <= std_logic_vector(to_unsigned(v_n_estados, N_ADDR_I'length));
                write_mem(v_mem, v_n_estados, WR_EN_I, WR_ADDR_I, WR_DATA_I);
                v_load_mem := '0';
            end if;
        end if;
        p_wait(clk_period);
    end process P_MEM;

    -- Cambio de memoria
    P_SWITCH : process (SWITCH_MEM_I)
    begin
        if (SWITCH_MEM_I = '1') then
            act_mem <= next_mem;
        end if;
    end process;

    -- Contador RD_ADDR
    P_CNT : process (RST_I, CLK_I, RD_ADDR_I)
    begin
        if (RST_I = G_RST_POL) then
            cnt <= 0;
        elsif (act_mem_d1 = empty_mem) then
            cnt <= 0;
        elsif falling_edge(RD_ADDR_I(0)) then
            cnt <= 0;
        elsif rising_edge(RD_ADDR_I(0)) then
            cnt <= 0;
        elsif falling_edge(RD_ADDR_I(1)) then
            cnt <= 0;
        elsif rising_edge(RD_ADDR_I(1)) then
            cnt <= 0;
        elsif falling_edge(RD_ADDR_I(2)) then
            cnt <= 0;
        elsif rising_edge(RD_ADDR_I(2)) then
            cnt <= 0;
        elsif rising_edge(CLK_I) then
            cnt <= cnt + 1;
        end if;
    end process P_CNT;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
        variable v_last         : boolean := false;
        variable v_acaba_en_1   : boolean := true;
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";    -- INIT
        RST_I           <= G_RST_POL;
        EN_WR_CONFIG_I  <= '1';
        SWITCH_MEM_I    <= '0';
        LAST_CYC_I      <= '1';
        next_mem        <= (others => 0);
        p_wait(clk_period);
        RST_I           <= not G_RST_POL;
        p_wait(10*clk_period);

        ------------------------------
        -- WRITE 1
        --  4-1-2
        ------------------------------
        sim <= x"57_52_20_31_20_20";    -- WR 1

        if (v_acaba_en_1) then
            v_mem   := (0 => 4, 1 => 2, 2 => 1, others => 0);
        else
            v_mem   := (0 => 4, 1 => 1, 2 => 2, others => 0);
        end if;
        next_mem    <= v_mem;
        v_n_estados := 3;
        v_load_mem  := '1';

        wait until falling_edge(WR_EN_I);
        p_wait(10*clk_period);

        SWITCH_MEM_I    <= '1';
        p_wait(clk_period);
        SWITCH_MEM_I    <= '0';
        LAST_CYC_I      <= '0';

        ------------------------------
        -- READ 1
        --  4-1-2
        ------------------------------
        sim <= x"52_44_20_31_20_20";    -- RD 1

        -- Ciclo 1-1
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 2-1
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 3-1
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        ------------------------------
        -- WRITE 2
        --  1-4-1-3
        ------------------------------
        sim <= x"57_52_20_32_20_20";    -- WR 2

        if (v_acaba_en_1) then
            v_mem   := (0 => 1, 1 => 4, 2 => 3, 3 => 1, others => 0);
        else
            v_mem   := (0 => 1, 1 => 4, 2 => 1, 3 => 3, others => 0);
        end if;
        next_mem    <= v_mem;
        v_n_estados := 4;
        v_load_mem  := '1';

        ------------------------------
        -- READ 1
        --  4-1-2
        ------------------------------
        sim <= x"52_44_20_31_20_20";    -- RD 1

        -- Ciclo 4-1
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 5-1
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '1';
        v_last          := true;
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '0';
        v_last          := false;

        ------------------------------
        -- READ 2
        --  1-4-1-3
        ------------------------------
        sim <= x"52_44_20_32_20_20";    -- RD 2

        -- Ciclo 1-2
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 2-2
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        ------------------------------
        -- WRITE 3
        --  1-1-2
        ------------------------------
        sim <= x"57_52_20_33_20_20";    -- WR 3
        
        if (v_acaba_en_1) then
            v_mem   := (0 => 1, 1 => 2, 2 => 1, others => 0);
        else
            v_mem   := (0 => 1, 1 => 1, 2 => 2, others => 0);
        end if;
        next_mem    <= v_mem;
        v_n_estados := 3;
        v_load_mem  := '1';

        ------------------------------
        -- READ 2
        --  1-4-1-3
        ------------------------------
        sim <= x"52_44_20_32_20_20";    -- RD 2

        -- Ciclo 3-2
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 4-2
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '1';
        v_last          := true;
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '0';
        v_last          := false;

        ------------------------------
        -- READ 3
        --  1-1-2
        ------------------------------
        sim <= x"52_44_20_33_20_20";    -- RD 3

        -- Ciclo 1-3
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 2-3
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 3-3
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        ------------------------------
        -- WRITE 4
        --  5-3-1-6
        ------------------------------
        sim <= x"57_52_20_34_20_20";    -- WR 4
        
        if (v_acaba_en_1) then
            v_mem   := (0 => 5, 1 => 3, 2 => 6, 3 => 1, others => 0);
        else
            v_mem   := (0 => 5, 1 => 3, 2 => 1, 3 => 6, others => 0);
        end if;
        next_mem    <= v_mem;
        v_n_estados := 4;
        v_load_mem  := '1';

        ------------------------------
        -- READ 3
        --  1-1-2
        ------------------------------
        sim <= x"52_44_20_33_20_20";    -- RD 3

        -- Ciclo 4-3
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 4-3
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '1';
        v_last          := true;
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '0';
        v_last          := false;

        ------------------------------
        -- READ 4
        --  5-3-1-6
        ------------------------------
        sim <= x"52_44_20_34_20_20";    -- RD 4

        -- Ciclo 1-4
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 2-4
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        ------------------------------
        -- WRITE 5: No se carga
        --  1-2-1-2-1
        ------------------------------
        sim <= x"57_52_20_35_20_20";    -- WR 5

        EN_WR_CONFIG_I <= '0';
        
        if (v_acaba_en_1) then
            v_mem   := (0 => 1, 1 => 2, 2 => 1, 3 => 2, 4 => 1, others => 0);
        else
            v_mem   := (0 => 1, 1 => 2, 2 => 1, 3 => 1, 4 => 2, others => 0);
        end if;
        next_mem    <= v_mem;
        v_n_estados := 5;
        v_load_mem  := '1';

        ------------------------------
        -- READ 4
        --  5-3-1-6
        ------------------------------
        sim <= x"52_44_20_34_20_20";    -- RD 4

        -- Ciclo 3-4
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);

        -- Ciclo 4-4
        wait_est(0, act_mem(0), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(1, act_mem(1), v_last, RD_ADDR_I, SWITCH_MEM_I);
        wait_est(2, act_mem(2), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '1';
        v_last          := true;
        wait_est(3, act_mem(3), v_last, RD_ADDR_I, SWITCH_MEM_I);
        LAST_CYC_I      <= '0';
        v_last          := false;

        -- ------------------------------
        -- -- Reset
        -- ------------------------------
        -- sim <= x"52_45_53_45_54_20";    -- RESET
        -- RST_I           <= G_RST_POL;
        -- SWITCH_MEM_I    <= '0';
        -- LAST_CYC_I      <= '1';
        -- next_mem        <= (others => 0);
        -- p_wait(clk_period);
        -- RST_I           <= not G_RST_POL;

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(20*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;