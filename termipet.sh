#!/bin/bash
# TermiPet Assistant - wirtualny asystent terminalowy
# Autor: Aleksandra Janiuk
# Wersja: 1.0
# Licencja: MIT
# Opis: Interaktywny skrypt terminalowy z funkcjami motywacyjnymi, porządkowaniem plików i organizacją zdjęć.


# ───────────────────────────────────────────────
# Zmienne globalne
CONFIG="$HOME/.termipet.rc"
PET_TYPE=""
PET_ICON=""
TMP_DIR=""
NASTROJ=""
KOMENTARZ=""
CYTAT=""
ZADANIE=""
ODPOWIEDZ_NA_ZADANIE=""
SPRZATANIE_WYKONANE=""
ZDJECIA_WYKONANE=""
KATALOG_ZRODLOWY=""
TERM_TIME=""
EDIT_TIME=""
BROWSE_TIME=""
POSPRZATANE_KATALOGI=0
ZORGANIZOWANE_ZDJECIA=0

# ───────────────────────────────────────────────
# Plik konfiguracyjny (tworzony jeśli nie istnieje)
[[ ! -f "$CONFIG" ]] && echo "# Konfiguracja TermiPeta" > "$CONFIG"

# Wymagane zależności: dialog i zenity
for tool in dialog zenity; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "❌ Brakuje wymaganego narzędzia: $tool"
    echo "Zainstaluj je komendą: sudo apt install $tool"
    exit 1
  fi
done

# Jeśli brak wybranego zwierzątka, zapytaj użytkownika
if ! grep -q '^pet=' "$CONFIG"; then
  echo -e "\n🐾 Witaj! Wybierz swojego towarzysza TermiPeta:"
  echo "1) 🐶 Pies"
  echo "2) 🐱 Kot"
  echo "3) 🐰 Królik"
  read -p "Wpisz numer (1-3): " CHOICE
  case $CHOICE in
    1) echo "pet=dog" >> "$CONFIG" ;;
    2) echo "pet=cat" >> "$CONFIG" ;;
    3) echo "pet=rabbit" >> "$CONFIG" ;;
    *) echo "pet=pet" >> "$CONFIG" ;;
  esac
fi

# Pobierz ikonę zwierzaka
PET_TYPE=$(grep '^pet=' "$CONFIG" | cut -d'=' -f2)
case "$PET_TYPE" in
  dog) PET_ICON="🐶" ;;
  cat) PET_ICON="🐱" ;;
  rabbit) PET_ICON="🐰" ;;
  *) PET_ICON="🐾" ;;
esac

# Tymczasowe pliki
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT


# ───────────────────────────────────────────────
# Wersja i pomoc
show_help() {
  echo -e "\n📘 TermiPet Assistant - pomoc"
      echo "  -h   pomoc"
      echo "  -v   wersja"
      echo "  -r   szybki wybór czynności"
      echo "  -z   zmiana zwierzaka"
      exit 0
}


show_version() {
  echo -e "TermiPet Assistant v1.0\nAutor: Aleksandra Janiuk\nPolitechnika Gdańska – Systemy Operacyjne"
  exit 0
}



# ───────────────────────────────────────────────
# Powitanie i pokazanie ostatnich logów TermiPeta
powitanie() {

clear
echo -e "\n$PET_ICON - Witaj w TermiPet Assistant!\n"

  if [[ -f "$CONFIG" ]]; then
    echo -e "\n🕰️  Ostatnie logi TermiPeta:\n"
    grep '^log_' "$CONFIG" | sort | tail -n 3 | while IFS= read -r LINIA; do
      local DATA=${LINIA%%=*}; DATA=${DATA#log_}
      local WARTOSC=${LINIA#*=}
      echo "📅 $DATA"
      if [[ "$WARTOSC" =~ ([😀-😭][^,]*) ]]; then
        echo "   • Poprzedni nastrój: ${BASH_REMATCH[1]}"
      fi
      [[ "$WARTOSC" =~ cleanup ]] && {
            local COUNT=$(grep '^last_cleanup_count=' "$CONFIG" | cut -d'=' -f2)
            if [[ -n "$COUNT" ]]; then
                echo "   • Wykonano porządki: $COUNT katalogów"
            else
                echo "   • Wykonano porządki"
            fi
        }
      [[ "$WARTOSC" =~ \+photos ]] && {
            local COUNT=$(grep '^last_photo_count=' "$CONFIG" | cut -d'=' -f2)
            if [[ -n "$COUNT" ]]; then
                echo "   • Zorganizowano zdjęcia: $COUNT"
            else
                echo "   • Zorganizowano zdjęcia"
            fi
        }
      [[ "$WARTOSC" =~ term=([^, ]+) ]] && echo "   • Czas w terminalu: ${BASH_REMATCH[1]}"
      [[ "$WARTOSC" =~ edit=([^, ]+) ]] && echo "   • Czas w edytorze: ${BASH_REMATCH[1]}"
      [[ "$WARTOSC" =~ web=([^, ]+) ]] && echo "   • Czas w przeglądarce: ${BASH_REMATCH[1]}"
    done
  fi


echo -e "\n$PET_ICON - Czas na trochę porządków i dobrej energii!\n"
read -p "Zaczynamy? (T/n): " START
START=${START:-T}
[[ ! "$START" =~ ^[Tt]$ ]] && echo -e "\n$PET_ICON - Do zobaczenia następnym razem!" && exit 0

}


# ───────────────────────────────────────────────
# Pytanie o nastrój użytkownika
zapytaj_o_nastroj() {
  local mood_code=""
  mood_code=$(dialog --stdout --radiolist "$PET_ICON - Jak się dziś czujesz?" 15 50 5 \
    1 "🥰 Świetnie" off \
    2 "😊 Dobrze" on \
    3 "😐 Średnio" off \
    4 "😕 Słabo" off \
    5 "😭 Bardzo źle" off)

    echo -e "\n"

  case "$mood_code" in
    1) NASTROJ="🥰 Świetnie";    KOMENTARZ="Super! Twój entuzjazm jest zaraźliwy!" ;;
    2) NASTROJ="😊 Dobrze";      KOMENTARZ="Świetnie, oby tak dalej!" ;;
    3) NASTROJ="😐 Średnio";     KOMENTARZ="Rozumiem. Czasem tak bywa – bądź dla siebie wyrozumiały." ;;
    4) NASTROJ="😕 Słabo";       KOMENTARZ="Przykro mi to słyszeć... Może mały spacer albo herbata pomoże?" ;;
    5) NASTROJ="😭 Bardzo źle";  KOMENTARZ="Trzymaj się! Czasem warto odpuścić i po prostu odpocząć." ;;
    *) NASTROJ="Nie podano";     KOMENTARZ="Nie określono nastroju." ;;
  esac


  echo -e "\n🧠 Twój nastrój: $NASTROJ"
  echo -e "$PET_ICON - $KOMENTARZ"
}


# ───────────────────────────────────────────────
# Mikro-zadanie lub pytanie refleksyjne
zadanie_dnia() {
  local ZADANIA=(
    "Wymień 3 rzeczy, które sprawiły Ci dzisiaj radość:"
    "Za co jesteś dziś wdzięczny?"
    "Jaka jest jedna mała rzecz, którą dziś zrobisz dla siebie?"
    "Jakie marzenie chcesz kiedyś spełnić?"
    "Powiedz, czego się dzisiaj nauczyłeś."
  )

  ZADANIE="${ZADANIA[RANDOM % ${#ZADANIA[@]}]}"
  
  echo -e "\n$PET_ICON - Czy masz ochotę na zadanie dnia?"
  read -p "Wpisz T aby wykonać, lub n aby pominąć (T/n): " ODPOWIEDZ
  ODPOWIEDZ=${ODPOWIEDZ:-T}

  if [[ ! $ODPOWIEDZ =~ ^[Tt]$ ]]; then
    echo -e "\n$PET_ICON - Jasne! Nie musimy dzisiaj wykonywać zadania dnia!\n"
    ZADANIE=""    # nie ustawiamy zadania
    ODPOWIEDZ_NA_ZADANIE=""  # nie ma odpowiedzi
  else
    echo -e "\n🎯 Zadanie dnia: $ZADANIE"
    read -p "Twoja odpowiedź: " ODPOWIEDZ_NA_ZADANIE
  fi
}


# ───────────────────────────────────────────────
# Funkcja pomocnicza: Formatowanie czasu z sekund na godziny i minuty
format_time() {
  local total_seconds=$1
  local hours=$((total_seconds / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  echo "${hours}h ${minutes}min"
}

# ───────────────────────────────────────────────
# Funkcja: Liczenie czasu w aplikacjach (terminal, edytory, przeglądarki)
zlicz_czas_w_aplikacjach() {
  echo -e "\n📊 Analiza czasu spędzonego w aplikacjach...\n"
  local TERMINAL_INFO=$(ps -eo etimes,comm | grep -E "(gnome-terminal|konsole|xterm|bash|zsh|fish)" | awk '{sum+=$1; count++} END {print sum, count}')
  local EDITOR_INFO=$(ps -eo etimes,comm | grep -E "(code|vim|nano|subl|gedit)" | awk '{sum+=$1; count++} END {print sum, count}')
  local BROWSER_INFO=$(ps -eo etimes,comm | grep -E "(chrome|firefox|brave|chromium)" | awk '{sum+=$1; count++} END {print sum, count}')

  TERM_TIME=$(format_time $(echo $TERMINAL_INFO | awk '{print $1}'))
  EDIT_TIME=$(format_time $(echo $EDITOR_INFO | awk '{print $1}'))
  BROWSE_TIME=$(format_time $(echo $BROWSER_INFO | awk '{print $1}'))

  local TERM_PROC="$(echo $TERMINAL_INFO | awk '{print $2}')"
  local EDIT_PROC="$(echo $EDITOR_INFO | awk '{print $2}')"
  local BROWSE_PROC="$(echo $BROWSER_INFO | awk '{print $2}')"

local TOTAL_PROC=$((TERM_PROC + EDIT_PROC + BROWSE_PROC))
echo -e "⏱️  Czas spędzony dziś w aplikacjach: \t ilość procesów: $TOTAL_PROC"
echo "   • 🖥️  Terminal:     $TERM_TIME"
echo "   • 📝 Edytory:      $EDIT_TIME"
echo "   • 🌐 Przeglądarki: $BROWSE_TIME"
}


# ───────────────────────────────────────────────
# Sprzątanie katalogu: analiza wielkości, śmieci, plików tymczasowych
sprzataj_katalog() {
    echo -e "\n"
    read -p "Posprzątamy dzisiaj trochę? (T/n) " -r ODPOWIEDZ
    ODPOWIEDZ=${ODPOWIEDZ:-T}
    if [[ ! $ODPOWIEDZ =~ ^[Tt]$ ]]; then
        echo -e "\n$PET_ICON - Okej, w takim razie przechodzimy dalej bez sprzątania!\n"
        return
    fi

    echo -e "\n $PET_ICON - W takim razie zaczynamy! - wybierz katalog źródłowy:\n"
    sleep 1

    local DIR
    if command -v zenity >/dev/null && [ -n "$DISPLAY" ]; then
        DIR=$(zenity --file-selection --directory --title="Wybierz katalog do sprzątania")
        [[ -z "$DIR" ]] && echo "❌ Nie wybrano katalogu." && return
    else
        if command -v dialog >/dev/null; then
            DIR=$(dialog --stdout --title "Wybierz katalog" --dselect "$HOME/" 10 60)
            clear
        else
            echo "Podaj ścieżkę do katalogu:"
            read -r DIR
        fi
    fi

    [[ ! -d "$DIR" ]] && echo "❌ Niepoprawny katalog." && return

    local PODSUM_FULL="$TMP_DIR/podsumowanie_sprzatania_full.txt"
    local PODSUM_USUWANIE="$TMP_DIR/podsumowanie_usuniete_zachowane.txt"
    > "$PODSUM_FULL"
    > "$PODSUM_USUWANIE"

    echo "📁 Analiza katalogu: $DIR" >> "$PODSUM_FULL"

    echo -e "\n📄 Największe pliki:" >> "$PODSUM_FULL"
    find "$DIR" -type f -exec du -h {} + 2>/dev/null | sort -hr | head -n 5 >> "$PODSUM_FULL"


    find "$DIR" -type f \( \
        -name "*.tmp" -o \
        -name "*~" -o \
        -name "*.swp" -o \
        -name "*.bak" -o \
        -name "*.log" -o \
        -name ".DS_Store" -o \
        -name "Thumbs.db" -o \
        -name "*.old" \
    \) > "$TMP_DIR/tmp_files.txt"

    local tmp_count
    tmp_count=$(wc -l < "$TMP_DIR/tmp_files.txt")
    echo -e "\n🧹 Znaleziono $tmp_count potencjalnie zbędnych plików." >> "$PODSUM_FULL"

    if [[ $tmp_count -gt 0 ]]; then
        echo -e "\n🗑️ Lista znalezionych plików:" >> "$PODSUM_FULL"
        cat "$TMP_DIR/tmp_files.txt" >> "$PODSUM_FULL"

        dialog --title "🔍 Znalezione pliki" --ok-label "OK" --textbox "$PODSUM_FULL" 20 80

        while IFS= read -r FILE; do
            if [[ -f "$FILE" ]]; then
                FILE_SIZE=$(du -h "$FILE" 2>/dev/null | cut -f1)
                dialog --yesno "Czy chcesz usunąć ten plik?\n\n$FILE ($FILE_SIZE)" 10 70
                if [[ $? -eq 0 ]]; then
                    rm -f "$FILE"
                    echo -e "✓ Usunięto:\n $FILE ($FILE_SIZE)" >> "$PODSUM_USUWANIE"
                    echo -e "\n"
                else
                    echo -e "⏩ Zachowano:\n $FILE ($FILE_SIZE)" >> "$PODSUM_USUWANIE"
                fi
            fi
        done < "$TMP_DIR/tmp_files.txt"

        # ⚠️ Dodajemy brakujące końcowe okienko z decyzjami
        dialog --title "📋 Podsumowanie operacji na plikach" --textbox "$PODSUM_USUWANIE" 20 80
    else
        echo "✔️ Brak zbędnych plików do usunięcia." >> "$PODSUM_FULL"
        dialog --title "📋 Podsumowanie sprzątania" --textbox "$PODSUM_FULL" 20 80
    fi

    SPRZATANIE_WYKONANE="Tak"
    ((POSPRZATANE_KATALOGI++))
    sleep 2
}


# ───────────────────────────────────────────────
# Organizator zdjęć - rozbudowany
organizuj_zdjecia() {
  echo -e "\n"
  read -p "$PET_ICON - Czy chcesz rozpocząć proces organizacji zdjęć? (T/n) " -r ODPOWIEDZ
  ODPOWIEDZ=${ODPOWIEDZ:-T}
  [[ ! $ODPOWIEDZ =~ ^[Tt]$ ]] && echo -e "\n$PET_ICON - Anulowano przez użytkownika." && return

  while true; do
    KATALOG_ZRODLOWY=$(zenity --file-selection --directory --title="📷 Wybierz katalog źródłowy ze zdjęciami")
    [[ ! -d "$KATALOG_ZRODLOWY" ]] && dialog --msgbox "❌ Niepoprawny katalog!" 7 50 && continue

    local ILE_ZDJEC=$(find "$KATALOG_ZRODLOWY" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | wc -l)
    if [[ "$ILE_ZDJEC" -eq 0 ]]; then
      zenity --error --text="Brak zdjęć w tym katalogu! Wybierz inny."
      continue
    else
      break
    fi
  done

  echo -e "\n📷 Organizuję zdjęcia..."

  local BAZA=${KATALOG_ZRODLOWY##*/}
  local PARENT=${KATALOG_ZRODLOWY%/*}
  local KATALOG_ORGANIZER="$PARENT/${BAZA}_organizer"
  local i=1
  while [[ -e "$KATALOG_ORGANIZER" ]]; do
    KATALOG_ORGANIZER="${PARENT}/${BAZA}_organizer_$(printf "%02d" $i)"
    i=$((i+1))
  done
  mkdir "$KATALOG_ORGANIZER"

  find "$KATALOG_ZRODLOWY" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | while read -r PLIK; do
    d1=$(exiftool -DateTimeOriginal -d "%Y-%m-%d %H:%M:%S" -s -s -s "$PLIK")
    d2=$(exiftool -CreateDate        -d "%Y-%m-%d %H:%M:%S" -s -s -s "$PLIK")
    d3=$(exiftool -DateCreated       -d "%Y-%m-%d %H:%M:%S" -s -s -s "$PLIK")
    d4=$(exiftool -FileModifyDate    -d "%Y-%m-%d %H:%M:%S" -s -s -s "$PLIK")
    DATA=$(printf "%s\n%s\n%s\n%s\n" "$d1" "$d2" "$d3" "$d4" | grep -Ev '^(-)?$' | sort | sed '1q')
    [[ -z "$DATA" ]] && DATA=$(stat -c "%y" "$PLIK" | cut -d'.' -f1)

    PREFIX_1=${DATA%% *}
    PREFIX_2=${PLIK%/*}; PREFIX_2=${PREFIX_2##*/}
    PREFIX="${PREFIX_1}_${PREFIX_2}_"

    NR=$(( $(ls "$KATALOG_ORGANIZER/${PREFIX}"* 2>/dev/null | wc -l) + 1 ))
    EXT=${PLIK##*.}; EXT=${EXT,,}
    NOWA="${PREFIX}${NR}.${EXT}"
    cp --update=none "$PLIK" "$KATALOG_ORGANIZER/$NOWA"
  done

  ORIG=$(find "$KATALOG_ZRODLOWY" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | wc -l)
  NEW=$(find "$KATALOG_ORGANIZER" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | wc -l)

  local KOMUNIKAT="📦 Organizacja zakończona.\n📁 Oryginalny katalog: $ORIG zdjęć\n📂 Nowy katalog: $NEW zdjęć skopiowano."

  if [[ "$ORIG" -eq "$NEW" ]]; then
    dialog --yesno "$KOMUNIKAT\n\nCzy chcesz usunąć oryginalny katalog?\n$KATALOG_ZRODLOWY" 12 60
    [[ $? -eq 0 ]] && rm -rf "$KATALOG_ZRODLOWY"
  else
    dialog --msgbox "⚠️ Uwaga: liczba zdjęć się nie zgadza – nie usuwaj katalogu źródłowego!\n\n$KOMUNIKAT" 10 60
  fi

  ZDJECIA_WYKONANE="Tak"
  ((ZORGANIZOWANE_ZDJECIA+=NEW))
}

# ───────────────────────────────────────────────
# Funkcja: Czy chcesz coś jeszcze zrobić?
co_dalej() {
  while true; do
    dialog --menu "📋 Co chcesz zrobić dalej?" 14 60 4 \
      1 "🧹 Posprzątaj kolejny katalog" \
      2 "📷 Zorganizuj kolejne zdjęcia" \
      3 "📝 Utwórz raport dnia i zakończ" \
      4 "🚪 Zakończ bez tworzenia raportu" 2> "$TMP_DIR/menu_wybor"

        local WYBOR=$(< "$TMP_DIR/menu_wybor")
    if [[ -z "$WYBOR" || "$WYBOR" == "4" ]]; then
      echo -e "\n$PET_ICON - Do zobaczenia!"
      return 0
    fi

    case $(< "$TMP_DIR/menu_wybor") in
      1) echo -e "\n$PET_ICON - Porządkujemy dalej..."
            sprzataj_katalog
            SPRZATANIE_WYKONANE="Tak"
            ;;
      2) echo -e "\n$PET_ICON - Organizujemy kolejne zdjęcia..."
            organizuj_zdjecia
            ZDJECIA_WYKONANE="Tak"
            ;;
      3)
        echo -e "\n📄 Tworzę raport..."
        zapisz_raport
        return 0
        ;;
    esac
  done
}

# ───────────────────────────────────────────────
# Tworzenie i zapis raportu dziennego (z zapytaniem)
zapisz_raport() {
  local DATA=$(date +"%Y-%m-%d %H:%M")
  local PLIK="$HOME/Desktop/raport_TermiPet_$(date +%Y%m%d_%H%M).txt"

  echo -e "📘 Raport TermiPet Assistant\n===========================\n" > "$PLIK"
  echo -e "📅 Data: $DATA\n" >> "$PLIK"

  [[ -n "$NASTROJ" ]] && echo -e "🧠 Nastrój użytkownika: $NASTROJ" >> "$PLIK"
  [[ -n "$ZADANIE" ]] && {
    echo -e "\n🎯 Zadanie dnia: $ZADANIE" >> "$PLIK"
    echo -e "✍️  Twoja odpowiedź: $ODPOWIEDZ_NA_ZADANIE" >> "$PLIK"
  }

  echo -e "\n🕓 Czas spędzony w aplikacjach:" >> "$PLIK"
  echo -e "🖥️  Terminal:     $TERM_TIME" >> "$PLIK"
  echo -e "📝 Edytory:      $EDIT_TIME" >> "$PLIK"
  echo -e "🌐 Przeglądarki: $BROWSE_TIME" >> "$PLIK"

  echo -e "\n🧹 Operacje systemowe:" >> "$PLIK"
  echo -e "- Ilość posprzątanych katalogów: $POSPRZATANE_KATALOGI" >> "$PLIK"
  echo -e "- Ilość zorganizowanych zdjęć: $ZORGANIZOWANE_ZDJECIA" >> "$PLIK"

  echo -e "✅ Raport zapisany na pulpicie jako: $PLIK"
}

# ───────────────────────────────────────────────
# Cytat dnia (losowany z tablicy)
pokaz_cytat() {
  local CYTATY=(
    "Poznaj granice, potem je przekrocz."
    "Kod to życie, kompilator to sędzia."
    "Błędy? To tylko kolejne wyzwania."
    "Nie zatrzymuj się, aż kod będzie czysty jak łza."
    "Debugowanie to jak bycie detektywem, gdzie jesteś też przestępcą."
    "Nigdy nie rezygnuj z nauki – kod sam się nie napisze."
    "Zanim obwinisz komputer – sprawdź swój kod."
    "Jeśli działa – nie dotykaj (chyba że chcesz lepiej)."
    "Sukces to suma małych wysiłków powtarzanych każdego dnia."
    "Nie wszystko, co skomplikowane, jest mądre."
  )


  CYTAT="${CYTATY[RANDOM % ${#CYTATY[@]}]}"
  echo -e "\n💬 Cytat dnia: \"$CYTAT\""
}


# ───────────────────────────────────────────────
# Zapis danych do pliku ~/.termipet.rc
aktualizuj_konfiguracje() {
  local dzisiaj=$(date +%F)


  # Wyczyść poprzednie wpisy (zastąp je)
  sed -i "/^last_/d" "$CONFIG"
  sed -i "/^log_$dzisiaj=/d" "$CONFIG"


  [[ -n "$KATALOG_ZRODLOWY" ]] && echo "last_dir=$KATALOG_ZRODLOWY" >> "$CONFIG"
  [[ -n "$NASTROJ" ]] && echo "last_mood=$NASTROJ" >> "$CONFIG"
  [[ -n "$SPRZATANIE_WYKONANE" ]] && echo "last_cleanup=$SPRZATANIE_WYKONANE" >> "$CONFIG"
  [[ -n "$POSPRZATANE_KATALOGI" ]] && echo "last_cleanup_count=$POSPRZATANE_KATALOGI" >> "$CONFIG"
  [[ -n "$ZDJECIA_WYKONANE" ]] && echo "last_photo_org=$ZDJECIA_WYKONANE" >> "$CONFIG"
  [[ -n "$ZORGANIZOWANE_ZDJECIA" ]] && echo "last_photo_count=$ZORGANIZOWANE_ZDJECIA" >> "$CONFIG"
  [[ -n "$TERM_TIME" ]] && echo "last_terminal_time=${TERM_TIME}m" >> "$CONFIG"
  [[ -n "$EDIT_TIME" ]] && echo "last_editor_time=${EDIT_TIME}m" >> "$CONFIG"
  [[ -n "$BROWSE_TIME" ]] && echo "last_browser_time=${BROWSE_TIME}m" >> "$CONFIG"


  # Zbuduj linię logu dziennego
  local log="log_$dzisiaj=$NASTROJ"
  [[ "$SPRZATANIE_WYKONANE" == "Tak" ]] && log+=", cleanup"
  [[ "$ZDJECIA_WYKONANE" == "Tak" ]] && log+="+photos"
  [[ -n "$TERM_TIME" ]] && log+=", term=${TERM_TIME}m"
  [[ -n "$EDIT_TIME" ]] && log+=", edit=${EDIT_TIME}m"
  [[ -n "$BROWSE_TIME" ]] && log+=", web=${BROWSE_TIME}m"
  echo "$log" >> "$CONFIG"
}


# ───────────────────────────────────────────────
# Parsowanie opcji

while getopts "hvrz" opt; do
  case $opt in
    h) show_help ;;
    v) show_version ;;
    r) co_dalej; exit 0;;
    z)
      echo -e "\n🔄 Zmieniamy Twojego TermiPeta:"
      echo "1) 🐶 Pies"
      echo "2) 🐱 Kot"
      echo "3) 🐰 Królik"
      read -p "Wpisz numer (1-3): " ZMIANA
      sed -i '/^pet=/d' "$CONFIG"
      case $ZMIANA in
        1) echo "pet=dog" >> "$CONFIG" ;;
        2) echo "pet=cat" >> "$CONFIG" ;;
        3) echo "pet=rabbit" >> "$CONFIG" ;;
        *) echo "pet=pet" >> "$CONFIG" ;;
      esac
      echo "✅ Zmieniono zwierzaka! Uruchom ponownie, aby zobaczyć efekt."
      exit 0
      ;;
    *) echo "❌ Nieznana opcja. Użyj -h." >&2; exit 1 ;;
  esac
done


# ───────────────────────────────────────────────
# Wywołanie modułów
    powitanie
    zapytaj_o_nastroj
    zadanie_dnia
    zlicz_czas_w_aplikacjach
    sprzataj_katalog
    organizuj_zdjecia
    co_dalej
    pokaz_cytat
    aktualizuj_konfiguracje

