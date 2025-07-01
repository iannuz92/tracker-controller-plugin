# 🚀 Compilare Tracker Controller senza Xcode locale

## Problema: Spazio insufficiente per Xcode

Se non hai spazio per installare Xcode (15GB richiesti), puoi usare **GitHub Actions** per compilare il plugin nel cloud gratuitamente.

## ✅ Soluzione: GitHub Actions (Raccomandato)

### Passo 1: Crea Repository GitHub

1. Vai su [GitHub.com](https://github.com)
2. Crea nuovo repository pubblico
3. Nome suggerito: `tracker-controller-plugin`
4. ✅ Inizializza con README
5. ✅ Aggiungi .gitignore (Swift)

### Passo 2: Connetti Repository Locale

```bash
# Sostituisci USERNAME con il tuo username GitHub
git remote add origin https://github.com/USERNAME/tracker-controller-plugin.git

# Push del codice
git branch -M main
git push -u origin main
```

### Passo 3: Attiva GitHub Actions

1. Vai al tuo repository su GitHub
2. Click su tab **"Actions"**
3. GitHub rileverà automaticamente il workflow `.github/workflows/build.yml`
4. Click **"I understand my workflows, go ahead and enable them"**

### Passo 4: Trigger Build

Ogni volta che fai push, GitHub Actions:
- ✅ Compila il plugin con Xcode nel cloud
- ✅ Valida Audio Unit con `auval`
- ✅ Crea package scaricabile
- ✅ Salva artifacts per 30 giorni

```bash
# Per triggerare una build:
git add .
git commit -m "Update plugin"
git push
```

### Passo 5: Scarica Plugin Compilato

1. Vai su GitHub → Repository → **Actions**
2. Click sull'ultima build (verde = successo)
3. Scroll down a **"Artifacts"**
4. Download **"tracker-controller-plugin"**
5. Estrai e esegui `TrackerControllerHost.app`

## 🔄 Workflow Automatico

Il file `.github/workflows/build.yml` fa automaticamente:

```yaml
✅ Setup Xcode latest
✅ Build Framework
✅ Build Audio Unit Extension  
✅ Build Host App
✅ Validate Audio Unit
✅ Create Release Archive
✅ Upload Artifacts
```

## 🎯 Vantaggi GitHub Actions

- **🆓 Gratuito**: 2000 minuti/mese per repository pubblici
- **⚡ Veloce**: Build completa in ~5-10 minuti
- **🔒 Sicuro**: Ambiente pulito per ogni build
- **📦 Automatico**: Artifacts pronti per download
- **✅ Validato**: Include test `auval` automatici

## 🛠️ Sviluppo Locale (Senza Xcode)

Puoi continuare a sviluppare localmente usando:

```bash
# Controlla sintassi Swift
./develop_without_xcode.sh syntax

# Analizza codice
./develop_without_xcode.sh lint

# Testa MIDI
./develop_without_xcode.sh midi

# Push per build cloud
./develop_without_xcode.sh push
```

## 📋 Checklist Setup

- [ ] Repository GitHub creato
- [ ] Codice pushato con `git push`
- [ ] GitHub Actions abilitato
- [ ] Prima build completata con successo
- [ ] Plugin scaricato e testato

## 🚨 Troubleshooting

### Build fallisce?
- Controlla tab "Actions" per errori
- Verifica che tutti i file Swift siano validi
- Controlla che `project.pbxproj` sia corretto

### Non vedi Artifacts?
- Aspetta che build sia completata (icona verde)
- Scroll down nella pagina della build
- Artifacts appaiono solo se build è successo

### Plugin non funziona?
- Scarica `tracker-controller-plugin.zip`
- Estrai e esegui `TrackerControllerHost.app`
- Il plugin si registrerà automaticamente

## 💡 Pro Tips

1. **Branch Development**: Usa branch separati per features
2. **Draft Releases**: Crea release per versioni stabili
3. **Issue Tracking**: Usa GitHub Issues per bug reports
4. **Wiki**: Documenta setup e usage nella Wiki

## 🔗 Link Utili

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Cloud Alternative](https://developer.apple.com/xcode-cloud/)
- [Audio Unit Programming Guide](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/AudioUnitProgrammingGuide/)

---

**Risultato**: Plugin Audio Unit professionale compilato nel cloud, zero spazio disco locale richiesto! 🎉 