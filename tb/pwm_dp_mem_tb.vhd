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

    -- Constantes
    constant C_CEROS    : std_logic_vector((RD_ADDR_I'length - 1) downto 0) := (others => '0');

    -- Soporte
    type memory is array (0 to (G_MEM_SIZE_MAX_N - 1)) of integer range 0 to G_STATE_MAX_N;
    shared variable v_mem       : memory := (others => 0);
    shared variable v_mem_len   : integer := 0;
    shared variable v_mem_int       : memory := (others => 0);
    shared variable v_mem_len_int   : integer := 0;
    signal addr_cnt             : integer range 0 to G_STATE_MAX_N;
    signal req_switch_1         : std_logic := '0';
    signal req_switch_2         : std_logic := '0';
    signal init                 : std_logic := '1';

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
        signal en_wr_config : out std_logic;
        signal wr_en        : out std_logic;
        signal wr_addr      : out std_logic_vector;
        signal wr_data      : out std_logic_vector;
        signal switch       : out std_logic;
        signal n_addr       : out std_logic_vector
    ) is 
    begin
        rst             <= G_RST_POL;
        en_wr_config    <= '1';
        wr_en           <= '0';
        wr_addr         <= (others => '0');
        wr_data         <= (others => '0');
        switch          <= '0';
        n_addr          <= (others => '0');
        p_wait(clk_period);
        rst             <= not G_RST_POL;
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

    -- Simulación RD_ADDR
    P_RD_ADDR : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            v_mem_int       := (others => 0);
            v_mem_len_int   := 0;
            RD_ADDR_I       <= (others => '0');
            addr_cnt        <= 1;
        elsif rising_edge(CLK_I) then
            -- Actualización de memoria interna
            if (SWITCH_MEM_I = '1') then
                v_mem_int       := v_mem;
                v_mem_len_int   := v_mem_len;
                RD_ADDR_I       <= (others => '0');
                addr_cnt        <= 1;
            -- RD_ADDR
            elsif (addr_cnt = v_mem_int(to_integer(unsigned(RD_ADDR_I)))) then
                addr_cnt        <= 1;
                if (to_integer(unsigned(RD_ADDR_I)) = (v_mem_len_int - 1)) then
                    RD_ADDR_I   <= (others => '0');
                else
                    RD_ADDR_I   <= std_logic_vector(unsigned(RD_ADDR_I) + 1);
                end if;
            else
                addr_cnt    <= addr_cnt + 1;
            end if;
        end if;
    end process P_RD_ADDR;

    -- Simulación de LAST y SWITCH
    P_SWITCH : process (RST_I, CLK_I)
        variable v_last : integer := 0;
    begin
        if (RST_I = G_RST_POL) then
            req_switch_2    <= '0';
            LAST_CYC_I      <= '0';
            SWITCH_MEM_I    <= '0';
            init            <= '1';
            v_last          := 0;
        elsif rising_edge(CLK_I) then
            if (req_switch_1 = '1') then
                if (init = '1') then
                    init            <= '0';
                    SWITCH_MEM_I    <= '1';
                else
                    req_switch_2    <= '1';
                end if;
            elsif (req_switch_2 = '1') then
                if (to_integer(unsigned(RD_ADDR_I)) = (v_mem_len_int - 1)) then
                    if (addr_cnt = v_mem_int(to_integer(unsigned(RD_ADDR_I)))) then
                        LAST_CYC_I      <= '1';
                        req_switch_2    <= '0';
                    end if;
                end if;               
            elsif ((LAST_CYC_I = '1') and (SWITCH_MEM_I = '0')) then
                -- Último estado es '1'
                if (v_last = 1) then
                    if ((to_integer(unsigned(RD_ADDR_I)) = (v_mem_len_int - 2))
                        and (addr_cnt = v_mem_int(to_integer(unsigned(RD_ADDR_I))))) then
                        SWITCH_MEM_I <= '1';
                    end if;
                -- Último estado no es '1'
                else
                    if ((to_integer(unsigned(RD_ADDR_I)) = (v_mem_len_int - 1))
                        and (addr_cnt = (v_mem_int(to_integer(unsigned(RD_ADDR_I))) - 1))) then
                        SWITCH_MEM_I <= '1';
                    end if;
                end if;
            elsif (SWITCH_MEM_I = '1') then
                LAST_CYC_I      <= '0';
                SWITCH_MEM_I    <= '0';
                v_last          := v_mem(to_integer(unsigned(N_ADDR_I) - 1));
            end if;
        end if;
    end process P_SWITCH;

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
        reset(RST_I, EN_WR_CONFIG_I, WR_EN_I, WR_ADDR_I, WR_DATA_I, req_switch_1, N_ADDR_I);

        p_wait(10*clk_period);

        ------------------------------
        -- Config 1
        ------------------------------
        sim <= x"43_4F_4E_46_20_31";    -- CONF 1
        v_mem_len := 4;
        v_mem := (  0 => 4,
                    1 => 3,
                    2 => 2,
                    3 => 1,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update 1
        pulso(req_switch_1);
        p_wait(50*clk_period);

        ------------------------------
        -- Config 2
        ------------------------------
        sim <= x"43_4F_4E_46_20_32";    -- CONF 2
        v_mem_len := 2;
        v_mem := (  0 => 5,
                    1 => 6,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 1, WR_EN_I, WR_ADDR_I, WR_DATA_I);

        p_wait(15*clk_period);

        -- Update 2
        pulso(req_switch_1);
        p_wait(35*clk_period);

        ------------------------------
        -- Config 3
        ------------------------------
        sim <= x"43_4F_4E_46_20_33";    -- CONF 3
        v_mem_len := 6;
        v_mem := (  0 => 7,
                    1 => 8,
                    2 => 9,
                    3 => 10,
                    4 => 11,
                    5 => 12,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 2, WR_EN_I, WR_ADDR_I, WR_DATA_I);

        p_wait(20*clk_period);

        -- Update 3
        pulso(req_switch_1);
        p_wait(40*clk_period);

        ------------------------------
        -- Config 4
        ------------------------------
        sim <= x"43_4F_4E_46_20_34";    -- CONF 4
        v_mem_len := 3;
        v_mem := (  0 => 13,
                    1 => 14,
                    2 => 15,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update 4
        pulso(req_switch_1);
        p_wait(70*clk_period);

        ------------------------------
        -- Config 5
        ------------------------------
        sim <= x"43_4F_4E_46_20_35";    -- CONF 5
        v_mem_len := 2;
        v_mem := (  0 => 8,
                    1 => 7,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update 5
        pulso(req_switch_1);
        p_wait(60*clk_period);

        ------------------------------
        -- Config 6
        ------------------------------
        sim <= x"43_4F_4E_46_20_36";    -- CONF 6
        v_mem_len := 3;
        v_mem := (  0 => 3,
                    1 => 2,
                    2 => 1,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 0, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update 6
        pulso(req_switch_1);
        p_wait(50*clk_period);

        ------------------------------
        -- Config 7
        ------------------------------
        sim <= x"43_4F_4E_46_20_37";    -- CONF 7
        v_mem_len := 5;
        v_mem := (  0 => 1,
                    1 => 2,
                    2 => 1,
                    3 => 2,
                    4 => 1,
                    others => 0);
        N_ADDR_I <= std_logic_vector(to_unsigned(v_mem_len, N_ADDR_I'length));
        wr_config(v_mem, v_mem_len, 5, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(20*clk_period);

        -- Update 7
        pulso(req_switch_1);
        p_wait(50*clk_period);

        ------------------------------
        -- Reset
        ------------------------------
        sim <= x"52_45_53_45_54_20";    -- RESET
        reset(RST_I, EN_WR_CONFIG_I, WR_EN_I, WR_ADDR_I, WR_DATA_I, req_switch_1, N_ADDR_I);

        p_wait(10*clk_period);
        
        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(20*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;