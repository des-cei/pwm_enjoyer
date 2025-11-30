-- Módulo: pwm_counter test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 24.06.2025

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
entity pwm_counter_tb is
end entity pwm_counter_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_counter_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_counter is
        generic (
            G_RST_POL       : std_logic := '1';
            G_STATE_MAX_L2  : natural := 32     -- Tamaño del vector de número de pulsos de un estado
        );
        port (
            CLK_I           : in std_logic;
            RST_I           : in std_logic;
            EN_I            : in std_logic;                                         -- Señal de habilitación                                         
            CNT_LEN_I       : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del estado actual
            CNT_LEN_NEXT_I  : in std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);   -- Número de pulsos del estado actual
            SWITCH_MEM_I    : in std_logic;                                         -- Indicador de último valor del último ciclo
            PWM_INIT_I      : in std_logic;                                         -- Valor inicial del ciclo
            PWM_O           : out std_logic;                                        -- Salida del PWM
            CNT_END_O       : out std_logic                                         -- Indicador de final de estado
        );
    end component pwm_counter;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/C_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I           : std_logic;
    signal RST_I           : std_logic;
    signal EN_I            : std_logic;                                      
    signal CNT_LEN_I       : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
    signal CNT_LEN_NEXT_I  : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);
    signal SWITCH_MEM_I    : std_logic;                                      
    signal PWM_INIT_I      : std_logic;                                      
    signal PWM_O           : std_logic;                                     
    signal CNT_END_O       : std_logic;
    
    -- Array de memoria
    type memory is array (0 to (C_MEM_SIZE_MAX_N - 1)) of integer range 0 to C_STATE_MAX_N;

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
        signal en           : out std_logic;
        signal cnt_len      : out std_logic_vector;
        signal cnt_len_next : out std_logic_vector;
        signal last_cyc     : out std_logic;
        signal pwm_init     : out std_logic
    ) is
    begin
        rst             <= C_RST_POL;
        en              <= '0';
        cnt_len         <= (others => '0');
        cnt_len_next    <= (others => '0');
        last_cyc        <= '1';
        pwm_init        <= '0';
        p_wait(clk_period);
        rst             <= not C_RST_POL;
    end procedure reset;

    procedure cnt_cyc (
        variable mem        : in memory;            -- Memoria actual
        variable n_ciclos   : in integer;           -- Número de ciclos
        variable n_estados  : in integer;           -- Numero de estados actuales
        variable nx_pwm_ini : in std_logic;         -- Valor inicial del siguiente ciclo
        variable nx_cnt_len : in integer;           -- Tiempo inicial del siguiente ciclo
        signal cnt_len      : out std_logic_vector; -- Tiempo de estado actual
        signal cnt_len_next : out std_logic_vector; -- Tiempo de estado siguiente
        signal last_cyc     : out std_logic;        -- Inidicador de último ciclo
        signal pwm_init     : out std_logic
    ) is
    begin
        last_cyc <= '0';
        for j in 0 to (n_ciclos - 1) loop
            for i in 0 to (n_estados - 1) loop
                -- Última dirección del ciclo
                if (j = (n_ciclos - 1)) and (i = (n_estados - 1)) then
                    last_cyc        <= '1';
                    pwm_init        <= nx_pwm_ini;
                end if;
                    cnt_len         <= std_logic_vector(to_unsigned(mem(i), cnt_len'length));
                if (i < (n_estados - 1)) then
                    cnt_len_next    <= std_logic_vector(to_unsigned(mem(i+1), cnt_len'length));
                elsif (j < (n_ciclos - 1)) then
                    cnt_len_next    <= std_logic_vector(to_unsigned(mem(0), cnt_len'length));
                else
                    cnt_len_next    <= std_logic_vector(to_unsigned(nx_cnt_len, cnt_len'length));
                end if;
                    p_wait(mem(i)*clk_period);
            end loop;

        end loop;
    end procedure cnt_cyc;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_counter
        generic map (
            G_RST_POL       => C_RST_POL,
            G_STATE_MAX_L2  => C_STATE_MAX_L2
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            CNT_LEN_I       => CNT_LEN_I,
            CNT_LEN_NEXT_I  => CNT_LEN_NEXT_I,
            SWITCH_MEM_I    => SWITCH_MEM_I,
            PWM_INIT_I      => PWM_INIT_I,
            PWM_O           => PWM_O,
            CNT_END_O       => CNT_END_O
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

        variable v_mem      : memory := (others => 0);
        variable v_estados  : integer := 0;
        variable v_ciclos   : integer := 0;
        variable v_nx_pwm_init      : std_logic;
        variable v_nx_pwm_val       : integer;

    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";    -- INIT
        reset(RST_I, EN_I, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
        p_wait(10*clk_period);

        ------------------------------
        -- Enable
        ------------------------------
        sim <= x"45_4E_41_42_4C_45";    -- ENABLE
        EN_I <= '1';
        p_wait(10*clk_period);

        -- Primera carga
        PWM_INIT_I  <= '1';
        p_wait(clk_period);

        ------------------------------
        -- Run 1
        --  5 estados: 3-5-1-2-1, empieza en '1'
        --  4 ciclos
        ------------------------------
        sim         <= x"52_55_4E_20_31_20";    -- RUN 1
        v_mem       := (0 => 2, 1 => 5, 2 => 1, 3 => 2, 4 => 1, others => 0);
        v_estados   := 5;
        v_ciclos    := 4;
        v_nx_pwm_init := '0';
        v_nx_pwm_val  := 1;
        cnt_cyc(v_mem, v_ciclos, v_estados, v_nx_pwm_init, v_nx_pwm_val, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
      
        ------------------------------
        -- Run 2
        --  4 estados: 1-4-1-2, empieza en '0'
        --  2 ciclos
        ------------------------------
        sim         <= x"52_55_4E_20_32_20";    -- RUN 2
        v_mem       := (0 => 1, 1 => 4, 2 => 1, 3 => 2, others => 0);
        v_estados   := 4;
        v_ciclos    := 2;
        v_nx_pwm_init := '0';
        v_nx_pwm_val  := 2;
        cnt_cyc(v_mem, v_ciclos, v_estados, v_nx_pwm_init, v_nx_pwm_val, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
      
        ------------------------------
        -- Run 3
        --  3 estados: 2-3-2, empieza en '0'
        --  3 ciclos
        ------------------------------
        sim         <= x"52_55_4E_20_33_20";    -- RUN 3
        v_mem       := (0 => 2, 1 => 3, 2 => 2, others => 0);
        v_estados   := 3;
        v_ciclos    := 3;
        v_nx_pwm_init := '0';
        v_nx_pwm_val  := 1;
        cnt_cyc(v_mem, v_ciclos, v_estados, v_nx_pwm_init, v_nx_pwm_val, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
     
        ------------------------------
        -- Run 4
        --  5 estados: 1-1-1-1-1, empieza en '0'
        --  2 ciclos
        ------------------------------
        sim         <= x"52_55_4E_20_34_20";    -- RUN 4
        v_mem       := (0 => 1, 1 => 1, 2 => 1, 3 => 1, 4 => 1, others => 0);
        v_estados   := 5;
        v_ciclos    := 2;
        v_nx_pwm_init := '1';
        v_nx_pwm_val  := 1;
        cnt_cyc(v_mem, v_ciclos, v_estados, v_nx_pwm_init, v_nx_pwm_val, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
     
        ------------------------------
        -- Run 5
        --  5 estados: 1-1-1-1-1, empieza en '1'
        --  2 ciclos
        ------------------------------
        sim         <= x"52_55_4E_20_35_20";    -- RUN 5
        v_mem       := (0 => 1, 1 => 1, 2 => 1, 3 => 1, 4 => 1, others => 0);
        v_estados   := 5;
        v_ciclos    := 2;
        v_nx_pwm_init := '1';
        cnt_cyc(v_mem, v_ciclos, v_estados, v_nx_pwm_init, v_nx_pwm_val, CNT_LEN_I, CNT_LEN_NEXT_I, SWITCH_MEM_I, PWM_INIT_I);
     
        ------------------------------
        -- End
        ------------------------------
        sim     <= x"45_4E_44_49_4E_47";    -- ENDING
        EN_I    <= '0';
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;