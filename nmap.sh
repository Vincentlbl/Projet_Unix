#!/bin/bash

# Vérification pour que le script soit exécuté en tant que que sudo
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec sudo ou en tant que root."
  exit 1
fi

# Créer un dossier "rapports" s'il n'existe pas
if [ ! -d "rapports" ]; then
  mkdir -p rapports
  echo "Le dossier 'rapports' a été créé."
fi

# Fonction pour afficher le menu
function show_menu() {
  echo "Sélectionnez le type de scan Nmap:"
  echo "1) Scan rapide (ports les plus courants)"
  echo "2) Scan complet (tous les ports TCP et UDP)"
  echo "3) Scan personnalisé (spécifier les ports)"
  echo "4) Scan avec détection de l'OS et des services"
  read -p "Choisissez une option (1-4): " scan_option
}

# Fonction pour choisir les hôtes
function choose_hosts() {
  echo "Sélectionnez la cible à scanner:"
  echo "1) Un seul hôte"
  echo "2) Plage d'adresses IP"
  echo "3) Plusieurs hôtes spécifiques"
  read -p "Choisissez une option (1-3): " host_option

  case $host_option in
    1)
      read -p "Entrez l'IP de l'hôte: " host
      ;;
    2)
      read -p "Entrez la plage d'adresses IP (ex: 192.168.1.1-50): " host
      ;;
    3)
      read -p "Entrez les adresses IP séparées par des virgules: " host
      host=$(echo $host | tr ',' ' ') 
      ;;
    *)
      echo "Option invalide."
      exit 1
      ;;
  esac
}

# Fonction pour forcer le scan avec option -Pn
function perform_scan() {
  for ip in $host; do
    case $scan_option in
      1)
        echo "Effectuer un scan rapide sur $ip avec l'option -Pn..."
        nmap -F -Pn $ip -oN rapports/scan_rapide_$ip.txt
        ;;
      2)
        echo "Effectuer un scan complet sur $ip avec l'option -Pn..."
        nmap -p 1-65535 -sU -Pn $ip -oN rapports/scan_complet_$ip.txt
        ;;
      3)
        read -p "Entrez les ports à scanner (ex: 22(SSH),80(HTTPS),443(HTTPS)): " ports
        echo "Effectuer un scan personnalisé sur les ports $ports de $ip avec l'option -Pn..."
        nmap -p $ports -Pn $ip -oN rapports/scan_personnalise_$ip.txt
        ;;
      4)
        echo "Effectuer un scan avec détection d'OS et de services sur $ip avec l'option -Pn..."
        nmap -O -sV -Pn $ip -oN rapports/scan_detection_$ip.txt
        ;;
      *)
        echo "Option de scan invalide."
        exit 1
        ;;
    esac
  done
}

# Fonction pour generé le rapport après le scan
function display_report() {
  for ip in $host; do
    echo "Voulez-vous afficher le rapport de scan pour $ip maintenant ? (y/n)"
    read -p "Votre choix: " display_choice
    if [ "$display_choice" == "y" ]; then
      echo "---------------------------------------------------------------------------------------"
      cat rapports/scan_detection_$ip.txt
      echo "---------------------------------------------------------------------------------------"
    else
      echo "Rapport enregistré dans le fichier : rapports/scan_detection_$ip.txt"
    fi
  done
}

# Fonction pour automatisr avec cron
function schedule_scan() {
  read -p "Voulez-vous planifier ce scan? (y/n): " schedule
  if [ "$schedule" == "y" ]; then
    read -p "Entrez la fréquence de cron (ex: 0 0 * * * pour tous les jours à 00h , Minute, Heure, Jour, Mois et Jour de la semaine ): " cron_freq
    (crontab -l; echo "$cron_freq /path/to/ton_script.sh >> /path/to/rapports/rapport_scan.txt") | crontab -
    echo "Scan planifié avec succès."
  fi
}

# Fonction principale
function main() {
  show_menu
  choose_hosts
  perform_scan
  display_report
  schedule_scan
}

# Lancer le script principal
main
