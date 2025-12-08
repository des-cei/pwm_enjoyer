import random
import os
import math


def generar_config(index, n_max_estados, n_max_dato, n_max_ciclos):
    """Crear los datos iniciales."""

    n_tot_cyc = 0     # (*)
    iter = 0
    while n_tot_cyc not in range(3, 2**32):
        # N_ADDR
        n_addr = random.randint(2, n_max_estados)

        # WR_DATA
        data = [random.randint(1, n_max_dato) for _ in range(n_addr)]

        # Probabilidad de empezar en 1
        if random.random() < 0.25:
            data[0] = 1

        # Probabilidad de acabar en 1
        if random.random() < 0.25:
            data[-1] = 1

        # Número de pulsos por ciclo (N_TOT_CYC)
        n_tot_cyc = sum(data)

        # print(  f"CONFIG: {index}\n" +
        #         f"TRY: {iter}\n" +
        #         f"ESTADOS: {n_addr}\n" +
        #         f"DATOS: {data}\n" +
        #         f"SUMA: {n_tot_cyc} => {int(math.log2(n_tot_cyc)) + 1} bits \n")
        iter += 1

    # WR_ADDR
    addr = list(range(n_addr))

    # PWM_INIT
    init = random.choice([0, 1])

    # Número entero de ciclos
    ciclos = random.randint(4, n_max_ciclos) 

    # Update de la primera configuración
    if index == 0:
        first_upd = random.randint(n_addr + 1, n_addr + 15)
    else:
        first_upd = 0

    return {"n_config": index + 1,
            "n_addr": n_addr, 
            "wr_addr": addr,
            "wr_data": data,
            "pwm_init": init,
            "ciclos": ciclos,
            "n_tot_cyc": n_tot_cyc,
            "first_upd": first_upd
            }


def generar_salidas(config_dic, index):

    longitud_ciclo = config_dic["n_tot_cyc"]
    init = config_dic["pwm_init"]
    datos = config_dic["wr_data"]

    dic_salidas = {"steps": [],
                   "pwm": [],
                   "unlock": [],
                   "n_config_out": [],
                   "ciclo": []
                   }
    
    pwm_ciclo_impar = []
    for dato in datos:
        pwm_ciclo_impar += [init]*dato
        if init == 1:
            init = 0
        else:
            init = 1
    pwm_ciclo_par = [int(math.fabs(x - 1)) for x in pwm_ciclo_impar]
    
    for ciclo in range(1, config_dic["ciclos"] + 1):
        dic_salidas["steps"]    += [n + 1 for n in range(longitud_ciclo)]
        dic_salidas["ciclo"]    += [ciclo for _ in range(longitud_ciclo)]
        dic_salidas["n_config_out"] += [index + 1 for _ in range(longitud_ciclo)]

        if (ciclo % 2 != 0):
            dic_salidas["pwm"]  += pwm_ciclo_impar
        elif (config_dic["n_addr"] % 2 == 0):
            dic_salidas["pwm"]  += pwm_ciclo_impar
        else:
            dic_salidas["pwm"]  += pwm_ciclo_par
            
        dic_salidas["unlock"] += [0 for _ in range(longitud_ciclo)]

    return dic_salidas


def generar_entradas (config_dic, index, dic_salidas, long_ent_prev, config_dic_prev={}, config_dic_next={"n_addr": 0}):

    dic_entradas = {"n_config": [],
                    "n_addr": [],
                    "n_tot_cyc": [],
                    "pwm_init": [],
                    "wr_en": [],
                    "wr_addr": [],
                    "wr_data": [],
                    "upd_mem": []
                }

    # Longitud del vector de entradas
    lon_start = 0
    lon_end = 0
    for i in range(len(dic_salidas["pwm"])):
        if (int(dic_salidas["n_config_out"][i], 2) == (index + 1)) and (int(dic_salidas["ciclo"][i], 2) == 1) and (int(dic_salidas["steps"][i], 2) == 2):
            lon_start = i
        elif (int(dic_salidas["n_config_out"][i], 2) == (index + 1)) and (int(dic_salidas["ciclo"][i], 2) == (config_dic["ciclos"] - 1)) and (int(dic_salidas["steps"][i], 2) == (config_dic["n_tot_cyc"] - 1)):
            lon_end = i - config_dic_next["n_addr"] - 1
    longitud = random.randint(lon_start, lon_end) - long_ent_prev

    # Posición del update
    upd_start = 0
    upd_end = 0
    upd_pos = -1
    if index > 0:
        for i in range(len(dic_salidas["pwm"])):
            if (int(dic_salidas["n_config_out"][i], 2) == index) and (int(dic_salidas["ciclo"][i], 2) == (config_dic_prev["ciclos"] - 2)) and (int(dic_salidas["steps"][i], 2) == (config_dic_prev["n_tot_cyc"] - 1)):
                upd_start = i
            elif (int(dic_salidas["n_config_out"][i], 2) == index) and (int(dic_salidas["ciclo"][i], 2) == (config_dic_prev["ciclos"] - 1)) and (int(dic_salidas["steps"][i], 2) == (config_dic_prev["n_tot_cyc"] - 3)):
                upd_end = i

    upd_pos = random.randint(max(upd_start, long_ent_prev), upd_end) - long_ent_prev
    while (upd_pos < config_dic["n_addr"] + 1):
        upd_pos += 1

    for n, i in enumerate(range(longitud)):
        dic_entradas["n_config"].append(index + 1)
        dic_entradas["n_addr"].append(config_dic["n_addr"])
        dic_entradas["n_tot_cyc"].append(config_dic["n_tot_cyc"])
        dic_entradas["pwm_init"].append(config_dic["pwm_init"])

        if i < config_dic["n_addr"]:
            dic_entradas["wr_en"].append(1)
            dic_entradas["wr_addr"].append(config_dic["wr_addr"][i])
            dic_entradas["wr_data"].append(config_dic["wr_data"][i])
        else:
            dic_entradas["wr_en"].append(0)
            dic_entradas["wr_addr"].append(config_dic["wr_addr"][config_dic["n_addr"] - 1])                  
            dic_entradas["wr_data"].append(config_dic["wr_data"][config_dic["n_addr"] - 1])

        if index == 0:
            if n == (config_dic["first_upd"] - 1):
                dic_entradas["upd_mem"].append(1)
            else:
                dic_entradas["upd_mem"].append(0)
        else:
            if n == upd_pos:
                dic_entradas["upd_mem"].append(1)
            else:
                dic_entradas["upd_mem"].append(0)

    return dic_entradas


def exportar_txt(dic, archivo):
    """Convierte un diccionario de listas en un fichero .txt con una lista por columna."""

    # Obtener las listas en el orden de las claves
    listas = list(dic.values())

    # Transponer con zip: filas -> columnas
    filas = zip(*listas)

    # Escribir al fichero
    with open(archivo, "w") as f:
        for fila in filas:
            linea = " ".join(f"{str(valor):<8}" for valor in fila)
            f.write(linea.rstrip() + "\n")

    print(f"{archivo} creado correctamente.")


def int_a_bin (lista, formato):
    """Convierte una lista de enteros a una lista en el formato definido."""
    return [format(int(x), formato) for x in lista]


if __name__ == "__main__":

    ruta = os.path.dirname(os.path.abspath(__file__))

    # USER: Configurar ----------------------------------------
    # Hay que tener en cuenta que los registros son de 32 bits.
    #   Si bien el requisto máximo es de 128 estados de 32 bits, el valor de
    #   N_TOT_CYC = SUM(dato_i) no puede superar (2*32 - 1) (*)

    worst_case = True

    if worst_case:
        n_config = 50           # Número de secuencias
        n_max_estados = 128     # Número máximo de estados (128)
        n_max_dato = 15000      # Valor máximo de un dato (2**32 - 1 = 4.294.967.295, pero para que sea coherente con TOT_CYC tiene que ser 1FF_FFFF = 33.554.431
        n_max_ciclos = 1500     # Número máximo de repeticiones de ciclos
    else:
        n_config = 30           # Número de secuencias
        n_max_estados = 20      # Número máximo de estados (128)
        n_max_dato = 150        # Valor máximo de un dato (2**32 - 1 = 4.294.967.295, pero para que sea coherente con TOT_CYC tiene que ser 1FF_FFFF = 33.554.431
        n_max_ciclos = 40       # Número máximo de repeticiones de ciclos

    # USER ----------------------------------------------------

    ok = False
    n_try = 0

    while not ok:
        try:

            n_try += 1 

            config_list = []
            ceros_inicio = [0]*5
            separacion = ["-------"]
            formato = "032b"

            dic_salidas = {"steps": [],
                        "pwm": [],
                        "unlock": [],
                        "n_config_out": [],
                        "ciclo": []
                        }
            
            dic_entradas = {"n_config": [],
                            "n_addr": [],
                            "n_tot_cyc": [],
                            "pwm_init": [],
                            "wr_en": [],
                            "wr_addr": [],
                            "wr_data": [],
                            "upd_mem": []
                            }
            
            dic_check = {"n_config": ["N_CONFIG"],
                        "n_addr": ["N_ADDR"],
                        "n_tot_cyc": ["N_TOT_CY"],
                        "pwm_init": ["PWM_INIT"],
                        "wr_en": ["WR_EN"],
                        "wr_addr": ["WR_ADDR"],
                        "wr_data": ["WR_DATA"],
                        "upd_mem": ["UPD_MEM"],
                        "steps": ["STEPS"],
                        "pwm": ["PWM"],
                        "unlock": ["UNLOCK"],
                        "n_config_out": ["N_CONF_O"],
                        "ciclo": ["CICLO"]}

            # Generar configuraciones automáticamente
            for i in range(n_config):
                config_list.append(generar_config(i, n_max_estados, n_max_dato, n_max_ciclos))

            for n, config in enumerate(config_list):

                first_update_list = [0,0,0] + [0 for _ in range(config["first_upd"])]

                dic_salidas_gen = {}
                dic_entradas_gen = {}

                # Generar las salidas
                dic_salidas_gen = generar_salidas(config, n)
                for salida, lista in dic_salidas.items():
                    # Inicio
                    if n == 0:
                        lista += int_a_bin(ceros_inicio + first_update_list, formato) 
                        dic_check[salida] += ceros_inicio + separacion + first_update_list + separacion
                    # Configuraciones
                    lista += int_a_bin(dic_salidas_gen[salida], formato)
                    dic_check[salida] += dic_salidas_gen[salida] + separacion

                # Generar las entradas en el momento correspondiente a las salidas
                if n == 0:
                    dic_entradas_gen = generar_entradas(config, n, dic_salidas, len(dic_entradas["n_addr"]))
                elif n < (n_config - 1):
                    dic_entradas_gen = generar_entradas(config, n, dic_salidas, len(dic_entradas["n_addr"]), config_list[n - 1], config_list[n + 1])
                else:
                    dic_entradas_gen = generar_entradas(config, n, dic_salidas, len(dic_entradas["n_addr"]), config_list[n - 1])
                for entrada, lista in dic_entradas.items():
                    # Inicio
                    if n == 0:
                        lista += int_a_bin(ceros_inicio, formato) 
                        dic_check[entrada] += ceros_inicio + separacion
                    # Configuraciones
                    lista += int_a_bin(dic_entradas_gen[entrada], formato)
                    dic_check[entrada] += dic_entradas_gen[entrada] + separacion

            ok = True

        except Exception as e:
            print(f"Try: {n_try}")
            print(type(e), e)

    if worst_case:
        exportar_txt(dic_salidas, os.path.join(ruta, "pwm_top_outputs_ref_WC.txt"))
        exportar_txt(dic_entradas, os.path.join(ruta, "pwm_top_inputs_WC.txt"))
        exportar_txt(dic_check, os.path.join(ruta, "pwm_top_io_check_WC.txt"))
    else:
        exportar_txt(dic_salidas, os.path.join(ruta, "pwm_top_outputs_ref.txt"))
        exportar_txt(dic_entradas, os.path.join(ruta, "pwm_top_inputs.txt"))
        exportar_txt(dic_check, os.path.join(ruta, "pwm_top_io_check.txt"))
