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
    echo -e "${BLANCO}   Docker4me Versión 1.6 - Interfaz más Completa e Interactiva${RESET}"
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
    local container container_id conf
    echo -e "${ROJO}🔍 Selecciona el contenedor a ELIMINAR:${RESET}"
    
    # Inyectamos la opción masiva al principio de la lista de fzf
    container=$( (echo "💥 BORRAR TODOS LOS CONTENEDORES (PARADOS Y ACTIVOS)"; docker ps -a --format "{{.ID}} | {{.Names}} [{{.Status}}]") | fzf --height 40% --reverse --header "ELIMINAR CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        if [[ "$container" == *"BORRAR TODOS"* ]]; then
            echo -ne "${ROJO}⚠ ¿Seguro que quieres borrar TODOS los contenedores del sistema? (s/N): ${RESET}"
            read -r conf
            if [[ "$conf" =~ ^[sS]$ ]]; then
                echo -e "${ROJO}🗑️ Deteniendo y eliminando absolutamente todos los contenedores...${RESET}"
                docker rm -f $(docker ps -aq) 2>/dev/null && echo -e "${VERDE}✔ Todos los contenedores eliminados.${RESET}"
            else
                echo -e "${AMARILLO}⚠️ Operación cancelada.${RESET}"
            fi
        else
            container_id="${container%% *}"
            echo -e "${ROJO}🗑️ Eliminando $container_id...${RESET}"
            docker rm -f "$container_id" && echo -e "${VERDE}✔ Contenedor eliminado.${RESET}"
        fi
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
    fi
    sleep 1.5
}

function ver_imagenes() {
    clear
    echo -e "${AZUL}📋 Lista Completa de Imágenes Locales:${RESET}\n"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
    echo -e "\n${AMARILLO}Presiona Enter para volver al menú principal...${RESET}"
    read -r
}

function eliminar_imagen() {
    local image image_clean conf
    echo -e "${ROJO}🔍 Selecciona la imagen a ELIMINAR:${RESET}"
    
    # Inyectamos la opción masiva al principio de la lista de fzf
    image=$( (echo "💥 BORRAR TODAS LAS IMÁGENES LOCALES"; docker images --format "{{.Repository}}:{{.Tag}} ({{.ID}})" | grep -v "<none>") | fzf --height 40% --reverse --header "ELIMINAR IMAGEN:")
    
    if [[ -n "$image" ]]; then
        if [[ "$image" == *"BORRAR TODAS"* ]]; then
            echo -ne "${ROJO}⚠ ¿Seguro que quieres borrar TODAS las imágenes del sistema? (s/N): ${RESET}"
            read -r conf
            if [[ "$conf" =~ ^[sS]$ ]]; then
                echo -e "${ROJO}🗑️ Eliminando todas las imágenes locales...${RESET}"
                docker rmi -f $(docker images -aq) 2>/dev/null && echo -e "${VERDE}✔ Todas las imágenes eliminadas.${RESET}"
            else
                echo -e "${AMARILLO}⚠️ Operación cancelada.${RESET}"
            fi
        else
            image_clean="${image%% *}"
            echo -e "${ROJO}🗑️ Eliminando imagen $image_clean...${RESET}"
            docker rmi -f "$image_clean" && echo -e "${VERDE}✔ Imagen eliminada.${RESET}"
        fi
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
    fi
    sleep 1.5
}

function limpieza_profunda() {
    clear
    echo -e "${ROJO}╔══════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${ROJO}║  ⚠️  ¡ADVERTENCIA DE PELIGRO CRÍTICO!                                    ║${RESET}"
    echo -e "${ROJO}╠══════════════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${ROJO}║  Esta acción ejecutará un 'docker system prune -a --volumes'.            ║${RESET}"
    echo -e "${ROJO}║  Se eliminará de forma PERMANENTE e IRREVERSIBLE:                        ║${RESET}"
    echo -e "${ROJO}║  1. Todos los contenedores detenidos.                                    ║${RESET}"
    echo -e "${ROJO}║  2. Todas las redes que no estén siendo usadas.                          ║${RESET}"
    echo -e "${ROJO}║  3. Todas las imágenes locales sin contenedores asociados.               ║${RESET}"
    echo -e "${ROJO}║  4. Todos los volúmenes locales no utilizados (¡TUS DATOS DE VOLÚMENES!).║${RESET}"
    echo -e "${ROJO}╚══════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${AMARILLO}Para confirmar la destrucción total, escribe ${BLANCO}SI${AMARILLO} en mayúsculas.${RESET}"
    echo -ne "${AZUL}¿Proceder con la limpieza profunda? : ${RESET}"
    read -r confirmacion

    if [[ "$confirmacion" == "SI" ]]; then
        echo -e "\n${ROJO}💥 Iniciando purga completa del sistema...${RESET}"
        docker system prune -a --volumes -f
        echo -e "\n${VERDE}✔ Limpieza profunda completada con éxito.${RESET}"
    else
        echo -e "\n${AMARILLO}❌ Acción cancelada. No se ha modificado nada.${RESET}"
    fi
    sleep 3
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

    opcion=$(printf "🚀 Crear contenedor desde imagen (run)\n💻 Entrar a un contenedor activo (exec)\n📋 Ver logs de un contenedor (logs)\n🛑 Detener un contenedor (stop)\n🗑️ Eliminar un contenedor (rm)\n🖼️ Ver imágenes locales\n💥 Eliminar una imagen concreta\n🚨 Limpieza profunda del sistema (System Prune)\n❌ Salir" | \
             fzf --height 50% --reverse --header "SELECCIONA UNA ACCIÓN:")

    if [[ -z "$opcion" ]]; then
        despedida
    fi

    case "$opcion" in
        *"Crear contenedor"*)    abrir_imagen ;;
        *"Entrar a un contenedor"*) contenedor_abierto ;;
        *"Ver logs"*) 
            ver_logs 
            echo -e "\n${AMARILLO}Volviendo al menú principal...${RESET}"
            sleep 1
            ;;
        *"Detener un contenedor"*) detener_contenedor ;;
        *"Eliminar un contenedor"*) eliminar_contenedor ;;
        *"Ver imágenes locales"*)  ver_imagenes ;;
        *"Eliminar una imagen"*)   eliminar_imagen ;;
        *"Limpieza profunda"*)     limpieza_profunda ;;
        *"Salir"*)                 despedida ;;
    esac
done