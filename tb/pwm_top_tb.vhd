-- Módulo: pwm_top test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 09.07.2025

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
            G_DATA_W    : integer   := 32;              -- Ancho de datos en bits (G_STATE_MAX_L2)
            G_ADDR_W    : integer   := 32;              -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
            G_MEM_DEPTH : integer   := 4096;            -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
            G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;
            EN_I        : in std_logic;                                     -- Señal de habilitación
            N_ADDR_I    : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Número de estados del PWM
            CYC_SYNC_I  : in std_logic;                                     -- Señal de sincronismo de todos los PWM
            PWM_INIT_I  : in std_logic;                                     -- Valor inicial
            WR_EN_I     : in std_logic;                                     -- Enable de escritura
            WR_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0);     -- Dirección de escritura
            WR_DATA_I   : in std_logic_vector((G_DATA_W - 1) downto 0);     -- Dato de escritura
            PWM_O       : out std_logic                                     -- Salida binaria
        );
    end component pwm_top;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I       : std_logic;
    signal RST_I       : std_logic;
    signal EN_I        : std_logic;                                             
    signal N_ADDR_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);             
    signal CYC_SYNC_I  : std_logic;                                             
    signal PWM_INIT_I  : std_logic;                                             
    signal WR_EN_I     : std_logic;                                             
    signal WR_ADDR_I   : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);             
    signal WR_DATA_I   : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);             
    signal PWM_O       : std_logic;       

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
        signal cyc_sync : out std_logic;
        signal pwm_init : out std_logic;
        signal wr_en    : out std_logic;
        signal wr_addr  : out std_logic_vector;
        signal wr_data  : out std_logic_vector
    ) is
    begin
        rst         <= '1';
        en          <= '0';
        n_addr      <= (others => '0');
        cyc_sync    <= '0';
        pwm_init    <= '0';
        wr_en       <= '0';
        wr_addr     <= (others => '0');
        wr_data     <= (others => '0');
        p_wait(clk_period);
        rst         <= '0';
    end procedure reset;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_top
        generic map (
            G_DATA_W    => G_STATE_MAX_L2,
            G_ADDR_W    => G_MEM_SIZE_MAX_L2,
            G_MEM_DEPTH => G_MEM_SIZE_MAX_N,
            G_MEM_MODE  => "LOW_LATENCY",
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,     
            RST_I       => RST_I,     
            EN_I        => EN_I,      
            N_ADDR_I    => N_ADDR_I,  
            CYC_SYNC_I  => CYC_SYNC_I,
            PWM_INIT_I  => PWM_INIT_I,
            WR_EN_I     => WR_EN_I,   
            WR_ADDR_I   => WR_ADDR_I, 
            WR_DATA_I   => WR_DATA_I, 
            PWM_O       => PWM_O     
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
        variable v_n_est : integer := 0;
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";
        reset(RST_I, EN_I, N_ADDR_I, CYC_SYNC_I, PWM_INIT_I, WR_EN_I, WR_ADDR_I, WR_DATA_I);
        p_wait(10*clk_period);

        ------------------------------
        -- ...
        ------------------------------

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;