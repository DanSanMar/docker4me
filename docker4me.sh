#!/bin/bash

# --- 1. CONFIGURACIÓN DE ENTORNO Y COLORES ---
export TERM=xterm-256color
BLANCO="\e[1;37m"
AZUL="\e[1;36m"
AMARILLO="\e[1;33m"
ROJO="\e[1;31m"
VERDE="\e[1;32m"
RESET="\e[0m"

# --- DETECTOR DE TERMINAL ---
detectar_terminal() {
    if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        echo ""
        return
    fi
    for term in xfce4-terminal gnome-terminal konsole xterm kitty alacritty; do
        if command -v "$term" &>/dev/null; then
            echo "$term"
            return
        fi
    done
}
MY_TERM=$(detectar_terminal)

# --- 2. FUNCIONES DE UTILIDAD ---

trap despedida SIGINT

function despedida() {
    echo -e "\n"
    echo -e "${AZUL}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${RESET}"
    echo -e "${AZUL}    ¡Gracias por usar Docker4me! Bye!    ${RESET}"
    echo -e "${AZUL}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${RESET}"
    exit 0
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${ROJO}❌ Error: '$1' no está instalado.${RESET}"
        exit 1
    fi
}

function mostrar_logo() {
    clear
    echo -e "${AZUL}"
    echo "  ██████   ██████   ██████ ██  ██ ███████ ██████  ██  ██ ███    ███ ███████ "
    echo "  ██   ██ ██    ██ ██      ██ ██  ██      ██   ██ ██  ██ ████  ████ ██      "
    echo "  ██   ██ ██    ██ ██      █████  █████   ██████  ███████ ██ ████ ██ █████   "
    echo "  ██   ██ ██    ██ ██      ██  ██ ██      ██   ██     ██ ██  ██  ██ ██      "
    echo "  ██████   ██████   ██████ ██  ██ ███████ ██   ██     ██ ██      ██ ███████ "
    echo -e "${BLANCO}   Docker4me Versión 1.4 - Interfaz Completa Interactiva con FZF${RESET}"
    echo -e "${AZUL}   -------------------------------------------------------------------------${RESET}"
    echo ""
}

# --- 3. LÓGICA DE GESTIÓN DOCKER ---

function abrir_imagen() {
    local image cmd
    echo -e "${AMARILLO}🔍 Listando imágenes disponibles...${RESET}"
    image=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | fzf --height 40% --reverse --header "SELECCIONA IMAGEN PARA LANZAR:")
    
    if [[ -n "$image" ]]; then
        cmd="if docker run --rm -it $image /bin/bash; then :; else docker run --rm -it $image /bin/sh; fi"
        
        if [[ -n "$MY_TERM" ]]; then
            echo -e "${VERDE}🚀 Abriendo $image en nueva ventana ($MY_TERM)...${RESET}"
            $MY_TERM -- bash -c "$cmd; echo -e '\n${AMARILLO}Presiona Enter para cerrar...${RESET}'; read" &
        else
            echo -e "${VERDE}🚀 Lanzando $image aquí mismo...${RESET}"
            clear
            eval "$cmd"
        fi
    else
        echo -e "${AMARILLO}⚠️ No se seleccionó ninguna imagen.${RESET}"
        sleep 1
    fi
}

function contenedor_abierto() {
    local container container_id cmd
    echo -e "${AMARILLO}🔍 Buscando contenedores activos...${RESET}"
    container=$(docker ps --format "{{.ID}} | {{.Names}} ({{.Image}})" | fzf --height 40% --reverse --header "CONECTAR A CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        container_id="${container%% *}"
        cmd="if docker exec -it $container_id /bin/bash; then :; else docker exec -it $container_id /bin/sh; fi"
        
        if [[ -n "$MY_TERM" ]]; then
            echo -e "${VERDE}🚀 Conectando a $container_id en nueva ventana...${RESET}"
            $MY_TERM -- bash -c "$cmd; echo -e '\n${AMARILLO}Sesión terminada. Presiona Enter...${RESET}'; read" &
        else
            echo -e "${VERDE}🚀 Conectando a $container_id aquí mismo...${RESET}"
            clear
            eval "$cmd"
        fi
    else
        echo -e "${AMARILLO}⚠️ No se seleccionó ningún contenedor.${RESET}"
        sleep 1
    fi
}

function ver_logs() {
    local container container_id
    echo -e "${AMARILLO}🔍 Selecciona contenedor para ver logs:${RESET}"
    container=$(docker ps -a --format "{{.ID}} | {{.Names}}" | fzf --height 40% --reverse --header "VER LOGS DE:")
    
    if [[ -n "$container" ]]; then
        container_id="${container%% *}"
        clear
        echo -e "${AZUL}📋 Mostrando últimas 50 líneas y siguiendo en vivo... (Ctrl+C para volver al menú)${RESET}\n"
        docker logs --tail 50 -f "$container_id"
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
        sleep 1
    fi
}

function detener_contenedor() {
    local container container_id
    echo -e "${AMARILLO}🔍 Selecciona el contenedor a detener:${RESET}"
    container=$(docker ps --format "{{.ID}} | {{.Names}}" | fzf --height 40% --reverse --header "DETENER CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        container_id="${container%% *}"
        echo -e "${AMARILLO}🛑 Deteniendo $container_id...${RESET}"
        docker stop "$container_id" && echo -e "${VERDE}✔ Contenedor detenido.${RESET}"
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
    fi
    sleep 1
}

function eliminar_contenedor() {
    local container container_id
    echo -e "${ROJO}🔍 Selecciona el contenedor a ELIMINAR:${RESET}"
    container=$(docker ps -a --format "{{.ID}} | {{.Names}} [{{.Status}}]" | fzf --height 40% --reverse --header "ELIMINAR CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        container_id="${container%% *}"
        echo -e "${ROJO}🗑️ Eliminando $container_id...${RESET}"
        docker rm -f "$container_id" && echo -e "${VERDE}✔ Contenedor eliminado.${RESET}"
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
    fi
    sleep 1
}

# --- 4. VALIDACIONES Y BUCLE PRINCIPAL INTERACTIVO ---

check_command "fzf"
check_command "docker"

if ! docker ps >/dev/null 2>&1; then
    echo -e "${ROJO}❌ Error: El demonio de Docker no responde.${RESET}"
    echo "Asegúrate de que Docker Desktop o el servicio docker estén iniciados."
    exit 1
fi

while true; do
    mostrar_logo

    # Lanzamos el menú interactivo principal
    opcion=$(printf "🚀 Crear contenedor desde imagen (run)\n💻 Entrar a un contenedor activo (exec)\n📋 Ver logs de un contenedor (logs)\n🛑 Detener un contenedor (stop)\n🗑️ Eliminar un contenedor (rm)\n❌ Salir" | \
             fzf --height 40% --reverse --header "SELECCIONA UNA ACCIÓN:")

    # Si presionas ESC, salimos limpiamente
    if [[ -z "$opcion" ]]; then
        despedida
    fi

    # Ejecutamos la acción
    case "$opcion" in
        *"Crear contenedor"*) abrir_imagen ;;
        *"Entrar a un contenedor"*) contenedor_abierto ;;
        *"Ver logs"*) 
            ver_logs 
            # Pausa para que al salir de los logs (Ctrl+C) puedas ver si quedó algún mensaje antes del clear
            echo -e "\n${AMARILLO}Volviendo al menú principal...${RESET}"
            sleep 1.5
            ;;
        *"Detener un contenedor"*) detener_contenedor ;;
        *"Eliminar un contenedor"*) eliminar_contenedor ;;
        *"Salir"*) despedida ;;
    esac
done