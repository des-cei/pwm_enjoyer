-- Módulo: test de autovalidación de pwm_top
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 30.09.2025

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
entity pwm_top_autotest_tb is
    generic (
        -- Ficheros .txt
        C_N_INPUTS          : integer := 8;     -- Número de entradas (columnas)
        C_N_OUTPUTS         : integer := 5;     -- Número de salidas (columnas)
        C_WIDTH             : integer := 32;    -- Número de bits de las señales
        -- C_INPUTS_PATH       : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_inputs.txt";
        -- C_OUTPUTS_REF_PATH  : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_outputs_ref.txt";
        -- C_OUTPUTS_PATH      : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_outputs.txt"
        C_INPUTS_PATH       : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_inputs.txt";
        C_OUTPUTS_REF_PATH  : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_outputs_ref.txt";
        C_OUTPUTS_PATH      : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_top_outputs.txt"
    );
end entity pwm_top_autotest_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_top_autotest_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_top is
        generic (
            G_STATE_MAX_L2      : natural   := 32;              -- Ancho de datos en bits
            G_MEM_SIZE_MAX_L2   : natural   := 32;              -- Ancho de direcciones en bits
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
            UNLOCKED_O      : out std_logic;                                            -- Habilitación de configuración de memoria
            STATUS_O        : out std_logic_vector(1 downto 0)                          -- Estado (00 = Apagado, 01 = Apagando, 11 = Activo)
        );
    end component pwm_top;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/C_SYS_CLK_HZ) * 1 ns;

    -- Port map
    signal CLK_I        : std_logic;     
    signal RST_I        : std_logic;
    signal EN_I         : std_logic;                                            -- Señal de habilitación del PWM
    signal UPD_MEM_I    : std_logic;                                            -- Pulso de actualización de memoria
    signal WR_EN_I      : std_logic;                                            -- Enable de escritura
    signal WR_ADDR_I    : std_logic_vector((C_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de escritura
    signal WR_DATA_I    : std_logic_vector((C_STATE_MAX_L2 - 1) downto 0);      -- Dato de escritura
    signal N_ADDR_I     : std_logic_vector((C_MEM_SIZE_MAX_L2 -1) downto 0);    -- Número de estados
    signal N_TOT_CYC_I  : std_logic_vector((C_PERIOD_MAX_L2 - 1) downto 0);     -- Número total de ciclos que dura la configuración
    signal PWM_INIT_I   : std_logic;                                            -- Valor inicial de salida
    signal PWM_O        : std_logic;                                            -- Salida del PWM
    signal UNLOCKED_O   : std_logic;                                            -- Habilitación de configuración de memoria
    signal STATUS_O     : std_logic_vector(1 downto 0);                         -- Estado (00 = Apagado, 01 = Apagando, 11 = Activo)

    -- Vectores de datos
    type vec_input is array (0 to (C_N_INPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);
    type vec_output is array (0 to (C_N_OUTPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);

    -- Otras señales
    signal CONFIG_N : integer range 0 to 255;

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- n/a

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_top
        generic map (
            G_STATE_MAX_L2      => C_STATE_MAX_L2,
            G_MEM_SIZE_MAX_L2   => C_MEM_SIZE_MAX_L2,
            G_PERIOD_MAX_L2     => C_PERIOD_MAX_L2,
            G_MEM_SIZE_MAX_N    => C_MEM_SIZE_MAX_N,
            G_MEM_MODE          => "LOW_LATENCY",
            G_RST_POL           => C_RST_POL  
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            EN_I        => EN_I,
            UPD_MEM_I   => UPD_MEM_I,
            WR_EN_I     => WR_EN_I,
            WR_ADDR_I   => WR_ADDR_I,
            WR_DATA_I   => WR_DATA_I,
            N_ADDR_I    => N_ADDR_I,
            N_TOT_CYC_I => N_TOT_CYC_I,
            PWM_INIT_I  => PWM_INIT_I,
            PWM_O       => PWM_O,
            UNLOCKED_O  => UNLOCKED_O,
            STATUS_O    => STATUS_O
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK : process
    begin
        CLK_I <= '1';
        wait for clk_period/2;
        CLK_I <= '0';
        wait for clk_period/2;
    end process;

    -- Reset
    P_RST : process
    begin
        RST_I <= C_RST_POL;
        EN_I  <= '0';
        wait for clk_period;
        RST_I <= not C_RST_POL;
        EN_I  <= '1';
        wait;
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    -- Lectura de los datos de entrada
    P_INPUT : process
        file read_file      : text;         -- Archivo de lectura
        variable line_in    : line;         -- Línea de lectura
        variable data_in    : vec_input;    -- Dato extraído
    begin

        file_open(read_file, C_INPUTS_PATH, read_mode); -- Abre el archivo de lectura
        while not endfile(read_file) loop
            -- wait until rising_edge(CLK_I);
            wait until CLK_I'event and (CLK_I = '1');
            readline(read_file, line_in);               -- Lee fila a fila
            for i in 0 to (C_N_INPUTS - 1) loop
                read(line_in, data_in(i));              -- Lee dato a dato, separados por espacios
            end loop;
            -- USER: Asignación de entradas
            CONFIG_N    <= to_integer(unsigned(to_stdlogicvector(data_in(0))));
            N_ADDR_I    <= to_stdlogicvector(data_in(1))((N_ADDR_I'length - 1) downto 0);
            N_TOT_CYC_I <= to_stdlogicvector(data_in(2))((N_TOT_CYC_I'length - 1) downto 0);
            PWM_INIT_I  <= to_stdlogicvector(data_in(3))(0);
            WR_EN_I     <= to_stdlogicvector(data_in(4))(0);
            WR_ADDR_I   <= to_stdlogicvector(data_in(5))((WR_ADDR_I'length - 1) downto 0);
            WR_DATA_I   <= to_stdlogicvector(data_in(6))((WR_DATA_I'length - 1) downto 0);
            UPD_MEM_I   <= to_stdlogicvector(data_in(7))(0);
            -- USER -----------------------
        end loop;
        -- wait until rising_edge(CLK_I);
        wait until CLK_I'event and (CLK_I = '1');
        file_close(read_file);

        assert FALSE report "End inputs reading" severity note;
        wait;

    end process;

    -- Lectura y comparación de las salidas con el modelo
    --  y escritura con los valores de salida obtenidos
    P_COMPARE : process
        file read_file      : text;         -- Archivo de lectura
        variable line_in    : line;         -- Línea de lectura
        variable data_in    : vec_output;   -- Dato extraído
        variable index      : integer := 1; -- Indicador de línea
        file write_file     : text;         -- Archivo de escritura
        variable line_out   : line;         -- Línea de lectura
        variable data_out   : vec_output;   -- Dato escrito
    begin

        file_open(read_file, C_OUTPUTS_REF_PATH, read_mode);    -- Abre el archivo de lectura
        file_open(write_file, C_OUTPUTS_PATH, write_mode);      -- Abre el archivo de escritura
        while not endfile(read_file) loop
            wait until rising_edge(CLK_I);
            readline(read_file, line_in);                       -- Lee fila a fila
            index := index + 1;
            -- USER: Asignación de salidas
            data_out(0)(0) := '0';                  -- STEPS (DEBUG)
            data_out(1)(0) := to_bit(PWM_O);        -- PWM
            data_out(2)(0) := to_bit(UNLOCKED_O);   -- UNLOCKED
            data_out(3)(0) := '0';                  -- N_CONFIG (DEBUG)
            data_out(4)(0) := '0';                  -- CICLO (DEBUG)
            -- USER ----------------------
            for i in 0 to (C_N_OUTPUTS - 1) loop
                read(line_in, data_in(i));                          -- Lee dato a dato, separados por espacios
                write(line_out, data_out(i), left, (C_WIDTH + 1));  -- Escribe dato a dato, separados por espacios
            end loop;
            writeline(write_file, line_out);                        -- Escribe fila a fila
            -- USER: Comparación de salidas
            assert data_out(1) = data_in(1)
                report ":( Wrong PWM output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            -- assert data_out(2) = data_in(2)
            --     report ":( Wrong UNLOCKED output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(2))))) &
            --         " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(2))))) & " at step: " & integer'image(index)
            --     severity failure;
            -- USER -----------------------
        end loop;
        wait until rising_edge(CLK_I);
        file_close(read_file);
        file_close(write_file);

        assert FALSE report "\_(^^ )_/ Simulation successfull! \_(^^ )_/" severity failure;

    end process;

end architecture beh;