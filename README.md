# TermiPet Assistant 🐾

## Opis projektu
TermiPet Assistant to interaktywny skrypt powłoki Bash uruchamiany w terminalu, którego celem jest uprzyjemnienie pracy użytkownika[cite: 1]. Pełni funkcję wirtualnego asystenta, oferując pomoc w analizie nastroju, organizacji zdjęć i katalogów, generowaniu codziennych raportów oraz wykonywaniu działań porządkowych[cite: 1]. Skrypt powstał w ramach zajęć Systemy Operacyjne[cite: 2].

## Główne funkcje
* **Analiza czasu pracy:** Monitoruje i oblicza czas spędzony w konkretnych aplikacjach (terminale, edytory kodu, przeglądarki) poprzez parsowanie procesów systemowych przy użyciu polecenia `ps` w połączeniu z `awk` i `grep`[cite: 2].
* **Automatyzacja porządków (Cleanup):** Skanuje wskazane katalogi w poszukiwaniu potencjalnie zbędnych plików tymczasowych i kopii zapasowych (m.in. `.tmp`, `*~`, `.swp`, `.log`), oblicza ich rozmiar i udostępnia interaktywny interfejs do ich weryfikacji i usuwania[cite: 2].
* **Organizacja zdjęć z metadanymi (EXIF):** Wykorzystuje narzędzie `exiftool` do ekstrakcji prawdziwej daty utworzenia zdjęcia z metadanych (np. `DateTimeOriginal`, `CreateDate`), automatycznie przenosząc i zmieniając nazwy plików w celu ich posortowania chronologicznego[cite: 2].
* **Interaktywny interfejs (TUI/GUI):** Wykorzystuje narzędzia `dialog` (dla trybu terminalowego) oraz `zenity` (do wyboru ścieżek z poziomu okien graficznych)[cite: 2].
* **Podręcznik systemowy (man page):** Projekt posiada dołączoną autorską stronę