# TermiPet Assistant 🐾

## Opis projektu
TermiPet Assistant to interaktywny skrypt powłoki Bash uruchamiany w terminalu, którego celem jest uprzyjemnienie pracy użytkownika. Pełni funkcję wirtualnego asystenta, oferując pomoc w analizie nastroju, organizacji zdjęć i katalogów, generowaniu codziennych raportów oraz wykonywaniu działań porządkowych. Skrypt powstał w ramach zajęć Systemy Operacyjne.

## Główne funkcje
* **Analiza czasu pracy:** Monitoruje i oblicza czas spędzony w konkretnych aplikacjach (terminale, edytory kodu, przeglądarki) poprzez parsowanie procesów systemowych przy użyciu polecenia `ps` w połączeniu z `awk` i `grep`.
* **Automatyzacja porządków (Cleanup):** Skanuje wskazane katalogi w poszukiwaniu potencjalnie zbędnych plików tymczasowych i kopii zapasowych (m.in. `.tmp`, `*~`, `.swp`, `.log`), oblicza ich rozmiar i udostępnia interaktywny interfejs do ich weryfikacji i usuwania.
* **Organizacja zdjęć z metadanymi (EXIF):** Wykorzystuje narzędzie `exiftool` do ekstrakcji prawdziwej daty utworzenia zdjęcia z metadanych (np. `DateTimeOriginal`, `CreateDate`), automatycznie przenosząc i zmieniając nazwy plików w celu ich posortowania chronologicznego.
* **Interaktywny interfejs (TUI/GUI):** Wykorzystuje narzędzia `dialog` (dla trybu terminalowego) oraz `zenity` (do wyboru ścieżek z poziomu okien graficznych).
* **Podręcznik systemowy (man page):** Projekt posiada dołączoną autorską stronę

## Wymagania i zależności
* **Środowisko:** `bash`
* **Narzędzia systemowe:** `find`, `grep`, `sort`, `sed`, `cut`, `head`, `uniq`, `wc`, `ps`, `awk`
* **Zależności zewnętrzne:** `dialog`, `zenity`, `exiftool`

## Uruchomienie i obsługa
1. Sklonuj repozytorium i nadaj skryptowi uprawnienia do wykonywania:
   ```bash
   chmod +x termipet.sh
2. Uruchom program:
    ```bash
    ./termipet.sh
3. Aby przeczytać dokumentację (man page) projektu użyj:
    ```bash
    man ./termipet.1