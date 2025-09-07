-- Módulo: test de autovalidación de pwm_dp_mem
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 27.08.2025

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
entity pwm_dp_mem_autotest_tb is
    generic (
        -- Ficheros .txt
        C_N_INPUTS          : integer := 7; -- Número de entradas (columnas)
        C_N_OUTPUTS         : integer := 2; -- Número de salidas (columnas)
        C_WIDTH             : integer := 8; -- Número de bits de las señales
        C_INPUTS_PATH       : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_inputs.txt";
        C_OUTPUTS_REF_PATH  : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs_ref.txt";
        C_OUTPUTS_PATH      : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs.txt";
        -- C_INPUTS_PATH       : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_inputs.txt";
        -- C_OUTPUTS_REF_PATH  : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs_ref.txt";
        -- C_OUTPUTS_PATH      : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs.txt";
        -- Genéricos del componente
        C_DATA_W    : integer   := G_STATE_MAX_L2;
        C_ADDR_W    : integer   := G_MEM_SIZE_MAX_L2;
        C_MEM_DEPTH : integer   := G_MEM_SIZE_MAX_N;
        C_MEM_MODE  : string    := "LOW_LATENCY";
        C_RST_POL   : std_logic := G_RST_POL
    );
end entity pwm_dp_mem_autotest_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_dp_mem_autotest_tb is

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
            NEXT_CONFIG_O   : out mem
        );
    end component pwm_dp_mem;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := 20 ns;

    -- Port map
    signal CLK_I            : std_logic;     
    signal RST_I            : std_logic := '1';
    signal EN_WR_CONFIG_I   : std_logic := '0';                                
    signal WR_EN_I          : std_logic := '0';                                
    signal WR_ADDR_I        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');
    signal WR_DATA_I        : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0) := (others => '0');
    signal SWITCH_MEM_I     : std_logic := '0';                                
    signal LAST_CYC_I       : std_logic := '0';    
    signal N_ADDR_I         : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');                            
    signal RD_ADDR_I        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');
    signal RD_DATA_O        : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0) := (others => '0');
    signal RD_DATA_NEXT_O   : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0) := (others => '0');
    signal NEXT_CONFIG_O    : mem;

    -- Vectores de datos
    type vec_input is array (0 to (C_N_INPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);
    type vec_output is array (0 to (C_N_OUTPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- n/a

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_dp_mem
        generic map (
            G_DATA_W    => C_DATA_W,   
            G_ADDR_W    => C_ADDR_W,   
            G_MEM_DEPTH => C_MEM_DEPTH,
            G_MEM_MODE  => C_MEM_MODE, 
            G_RST_POL   => C_RST_POL  
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
        CLK_I <= '1';
        wait for clk_period/2;
        CLK_I <= '0';
        wait for clk_period/2;
    end process;

    -- Reset
    P_RST : process
    begin
        RST_I <= G_RST_POL;
        wait for clk_period;
        RST_I <= not G_RST_POL;
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
            -- User TODO: Asignación de entradas
            WR_EN_I         <= to_stdlogicvector(data_in(0))(0);
            WR_ADDR_I       <= to_stdlogicvector(data_in(1))((C_ADDR_W - 1 ) downto 0);
            WR_DATA_I       <= to_stdlogicvector(data_in(2))((C_DATA_W - 1 ) downto 0);
            SWITCH_MEM_I    <= to_stdlogicvector(data_in(3))(0);
            LAST_CYC_I      <= to_stdlogicvector(data_in(4))(0);
            N_ADDR_I        <= to_stdlogicvector(data_in(5))((C_ADDR_W - 1 ) downto 0);
            RD_ADDR_I       <= to_stdlogicvector(data_in(6))((C_ADDR_W - 1 ) downto 0);
            ---------------------------------------
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
            -- User TODO: Asignación de salidas
            data_out(0)((RD_DATA_O'length - 1) downto 0) := to_bitvector(RD_DATA_O);
            data_out(1)((RD_DATA_NEXT_O'length - 1) downto 0) := to_bitvector(RD_DATA_NEXT_O);
            ----------------------------------------
            for i in 0 to (C_N_OUTPUTS - 1) loop
                read(line_in, data_in(i));                          -- Lee dato a dato, separados por espacios
                write(line_out, data_out(i), right, (C_WIDTH + 1)); -- Escribe dato a dato, separados por espacios
            end loop;
            writeline(write_file, line_out);                        -- Escribe fila a fila
            -- User TODO: Comparación de salidas
            assert data_out(0) = data_in(0)
                report ":( Wrong DATA output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(0))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(0))))) & " at step: " & integer'image(index)
                severity failure;
            assert data_out(1) = data_in(1)
                report ":( Wrong NEXT_DATA output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            ---------------------------------------
        end loop;
        wait until rising_edge(CLK_I);
        file_close(read_file);
        file_close(write_file);

        assert FALSE report "\_(^^ )_/ Simulation successfull! \_(^^ )_/" severity failure;

    end process;

end architecture beh;