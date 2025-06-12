#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

function section() {
    echo -e "\n${YELLOW}[➤] $1${NC}"
}

function check_and_flag() {
    if [ -s "$1" ]; then
        echo -e "${RED}[!] Résultat trouvé – voir $1${NC}"
    else
        echo -e "${GREEN}[✓] Aucun élément détecté dans $1${NC}"
    fi
}

section "SCAN DES PORTS LOCAUX (TCP full)"
nmap -sS -T4 -p- localhost -oN nmap_full_ports.txt
check_and_flag nmap_full_ports.txt

section "CONNEXIONS RÉSEAU ACTIVES"
ss -tunap > ss_connexions.txt
grep -E -v "127.0.0.1|::1|localhost" ss_connexions.txt | grep ESTAB > tmp_connex
check_and_flag tmp_connex
mv tmp_connex ss_connexions_suspectes.txt

section "FICHIERS DOUTEUX (.exe/.bat/.ps1) récents dans TEMP"
find /mnt/c/Users/*/AppData/Local/Temp -type f \( -iname '*.exe' -o -iname '*.bat' -o -iname '*.ps1' -o -iname '*.vbs' \) -mtime -7 2> temp_find_errors.log > fichiers_douteux_temp.txt
check_and_flag fichiers_douteux_temp.txt
if [ -s temp_find_errors.log ]; then
    echo -e "${YELLOW}[!] Des erreurs de permission détectées (voir temp_find_errors.log)${NC}"
fi

section "PROGRAMMES AU DÉMARRAGE"
find /mnt/c/Users/*/AppData/Roaming/Microsoft/Windows/Start\ Menu/Programs/Startup -type f 2> startup_find_errors.log > startup_items.txt
check_and_flag startup_items.txt
if [ -s startup_find_errors.log ]; then
    echo -e "${YELLOW}[!] Des erreurs de permission détectées (voir startup_find_errors.log)${NC}"
fi

section "EXTRACTION DES CLÉS DE DÉMARRAGE REGISTRE (NTUSER.DAT)"
> registry_keys_found.txt
for file in /mnt/c/Users/*/NTUSER.DAT; do
    echo "[User: $file]" >> registry_keys_found.txt
    strings "$file" 2>/dev/null | grep -iE 'Run|RunOnce|StartupApproved|CurrentVersion' >> registry_keys_found.txt
    echo "" >> registry_keys_found.txt
done
check_and_flag registry_keys_found.txt

section "FICHIERS SYSTEM32 .exe MODIFIÉS RÉCEMMENT"
find /mnt/c/Windows/System32 -type f -iname '*.exe' -mtime -10 2> system32_find_errors.log > services_modifies.txt
if [ -s services_modifies.txt ]; then
    echo -e "${RED}[!] Résultat trouvé – voir services_modifies.txt${NC}"
else
    echo -e "${GREEN}[✓] Aucun exécutable récent détecté dans System32${NC}"
fi
if [ -s system32_find_errors.log ]; then
    echo -e "${YELLOW}[!] Des erreurs de permission détectées (voir system32_find_errors.log)${NC}"
fi

section "TÂCHES PLANIFIÉES"
find /mnt/c/Windows/System32/Tasks -type f 2> tasks_find_errors.log > taches_planifiees.txt
check_and_flag taches_planifiees.txt
if [ -s tasks_find_errors.log ]; then
    echo -e "${YELLOW}[!] Des erreurs de permission détectées (voir tasks_find_errors.log)${NC}"
fi

section "CONFIG DNS ACTUELLE"
cat /etc/resolv.conf > resolv_dns_check.txt
echo -e "${GREEN}[✓] DNS écrit dans resolv_dns_check.txt${NC}"

section "LOGS DE FIREWALL"
ls /mnt/c/Windows/System32/LogFiles/Firewall/*.log > logs_firewall_paths.txt 2> firewall_logs_errors.log
check_and_flag logs_firewall_paths.txt
if [ -s firewall_logs_errors.log ]; then
    echo -e "${YELLOW}[!] Des erreurs de permission détectées (voir firewall_logs_errors.log)${NC}"
fi

section "✅ AUDIT TERMINÉ – FICHIERS À CONSULTER"
ls -lh *.txt *.nmap *.log 2>/dev/null
