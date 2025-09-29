# Code Merge Tools

Sammlung von Bash-Skripten zum Zusammenführen von Source-Code-Dateien in einzelne Dokumente - optimal für die Analyse durch KI-Assistenten wie Claude.

## 🚀 Features

- **Sprachspezifische Merger** für C#, Python und Web-Dateien
- Rekursive Verzeichnissuche mit konfigurierbaren Ausschlüssen
- Automatische Backups bei bestehenden Ausgabedateien
- Metadaten-Einbettung (Dateipfad, Größe, Änderungsdatum)
- Farbige Terminal-Ausgabe für bessere Übersicht

## 📦 Verfügbare Skripte

- `merge-csharp-files.sh` - Führt .cs Dateien zusammen
- `merge-python-files.sh` - Führt .py Dateien zusammen (mit smart excludes für venv, __pycache__ etc.)
- `merge-web-files.sh` - Führt HTML/CSS/JS/TS Dateien zusammen

## 💻 Verwendung
```bash
# Beispiel: Python-Dateien rekursiv zusammenführen
./merge-python-files.sh -r -d ./src -o projekt_code.py

# Hilfe anzeigen
./merge-csharp-files.sh --help
