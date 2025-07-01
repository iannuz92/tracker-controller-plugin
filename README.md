# Polyend Tracker Mini Controller - Audio Unit Plugin v1.1.0

Un plugin Audio Unit v3 nativo per Mac M3 Pro che funziona come controller MIDI avanzato per il Polyend Tracker Mini.

## 🆕 Novità v1.1.0

### ✨ **Nuove Funzionalità**
- **Real-Time Safety**: Sistema di logging thread-safe per prestazioni ottimali
- **Controlli Avanzati**: Master Volume, Swing, Pattern Length, Quantize
- **Gestione Errori Robusta**: Sistema completo di error handling e recovery
- **Stato Connessione**: Monitoraggio real-time della connessione MIDI
- **Preset Management**: Sistema di preset migliorato con versioning
- **Performance Features**: Trigger multipli, randomizzazione, mute/unmute globali

### 🔧 **Miglioramenti Tecnici**
- Parameter batching per ridurre il carico MIDI
- Atomic state management per thread safety
- Enhanced MIDI implementation con controlli avanzati
- Logging asincrono per non bloccare il thread audio
- Validazione parametri migliorata

## Descrizione

Questo plugin permette di controllare il Polyend Tracker Mini direttamente dalla tua DAW preferita (Logic Pro, GarageBand, Reaper, etc.) tramite un'interfaccia intuitiva e moderna.

### Caratteristiche Principali

- **Audio Unit v3 nativo** per Apple Silicon M3 Pro
- **Controller MIDI completo** per Polyend Tracker Mini
- **Interfaccia SwiftUI moderna** e responsiva
- **Controllo real-time** per performance live
- **Supporto completo** per tutte le funzioni del Tracker Mini
- **Sistema di preset avanzato** con backup automatico
- **Monitoraggio connessione** con reconnect automatico

### Funzionalità Implementate

#### Transport e Pattern
- Play/Stop/Record pattern
- Selezione pattern (0-127)
- BPM control e sync (60-200 BPM)
- Pattern length control (16-128 steps)
- Loop controls con quantize

#### Mixer e Tracce
- Controllo volume/pan per 8 tracce principali
- Mute/Solo per ogni traccia
- Master volume globale
- Controllo tracce MIDI aggiuntive (9-16)
- Trigger multipli con velocity sensitivity

#### Performance FX
- Delay e Reverb sends
- 6 macro controls personalizzabili
- Swing control per groove
- Real-time FX manipulation

#### Advanced Features
- **MIDI Learn**: Assegnazione dinamica CC
- **Preset System**: Salvataggio/caricamento configurazioni
- **Connection Monitoring**: Stato connessione real-time
- **Error Recovery**: Gestione automatica errori
- **Performance Tools**: Randomizzazione, trigger globali

#### MIDI Features
- Note trigger per samples
- CC mapping completo e ottimizzato
- Program Change per pattern
- Clock sync preciso con host DAW
- All Notes Off / Panic functions

## Requisiti di Sistema

- **macOS**: 13.0 o superiore
- **Hardware**: Mac con chip Apple Silicon (M1/M2/M3)
- **Xcode**: 15.0 o superiore (per compilazione)
- **DAW**: Logic Pro, GarageBand, Reaper, o qualsiasi host AU v3
- **Dispositivo**: Polyend Tracker Mini (connesso via USB)

## Installazione

### Opzione 1: Download Release

1. Scarica l'ultima release da GitHub
2. Estrai l'archivio
3. Esegui `TrackerControllerHost.app` per registrare il plugin
4. Il plugin sarà disponibile nella tua DAW

### Opzione 2: Compilazione da Sorgente

1. Clona il repository:
```bash
git clone [repository-url]
cd plugin_tracker
```

2. **IMPORTANTE**: Installa Xcode completo (non solo Command Line Tools):
```bash
# Verifica installazione Xcode
xcode-select --print-path
# Dovrebbe mostrare: /Applications/Xcode.app/Contents/Developer
```

3. Compila il progetto:
```bash
chmod +x build_plugin.sh
./build_plugin.sh
```

4. Esegui l'app host per registrare il plugin:
```bash
open build/Output/TrackerControllerHost.app
```

### Verifica Installazione

```bash
# Verifica che il plugin sia registrato
pluginkit -m | grep TrackerController

# Valida il plugin
auval -v aumu TCTR POLY

# Test real-time safety
auval -v aumu TCTR POLY -real-time-safety
```

## Utilizzo

### Setup Iniziale

1. **Connetti il Tracker Mini**: USB → Mac
2. **Verifica MIDI**: Impostazioni Audio MIDI Setup
3. **Lancia DAW**: Logic Pro / GarageBand / Reaper
4. **Aggiungi Plugin**: MIDI FX → Polyend → Tracker Controller

### In Logic Pro / GarageBand

1. Crea una nuova traccia MIDI
2. Aggiungi il plugin "Tracker Controller" come MIDI FX
3. Configura l'output MIDI verso il Polyend Tracker Mini
4. Verifica lo stato di connessione nel plugin
5. Inizia a controllare il tuo Tracker Mini!

### Controlli Principali

#### Connection Status
- **Indicatore**: Verde = connesso, Rosso = disconnesso
- **Auto-reconnect**: Riconnessione automatica su disconnessione
- **Device Name**: Nome del dispositivo connesso

#### Transport Section
- **Play**: Avvia riproduzione pattern
- **Stop**: Ferma riproduzione
- **Record**: Attiva registrazione
- **BPM**: Controllo tempo (60-200 BPM)
- **Sync**: Sincronizzazione con host DAW

#### Pattern Section
- **Pattern Selector**: Selezione pattern (0-127)
- **Pattern Length**: Lunghezza pattern (16/32/64/128 steps)
- **Loop Mode**: Modalità loop on/off
- **Quantize**: Quantizzazione automatica

#### Advanced Controls
- **Master Volume**: Volume globale
- **Swing**: Controllo groove (0-100%)
- **Tempo Sync**: Sync con DAW
- **Auto-Sync**: Sincronizzazione automatica

#### Mixer Section
- **Track Volume**: Volume individuale (8 tracce)
- **Track Pan**: Panoramica individuale
- **Mute/Solo**: Controlli per ogni traccia
- **Global Controls**: Mute All, Unmute All, Randomize

#### Performance FX
- **Delay Send**: Controllo send delay
- **Reverb Send**: Controllo send reverb
- **Macro 1-6**: Controlli macro personalizzabili
- **Performance Tools**: Trigger All, Randomize Macros

#### Preset Management
- **Load Preset**: Carica configurazione salvata
- **Save Preset**: Salva configurazione corrente
- **Auto-backup**: Backup automatico ogni 5 minuti

## Architettura Tecnica v1.1.0

### Struttura Progetto

```
plugin_tracker/
├── TrackerController.xcodeproj
├── TrackerControllerHost/          # App container
├── TrackerControllerAU/            # Audio Unit Extension
├── TrackerControllerFramework/     # Framework condiviso
│   ├── TrackerControllerAudioUnit.swift    # Core Audio Unit
│   ├── MIDIController.swift                # MIDI Management
│   ├── ControllerUI.swift                  # SwiftUI Interface
│   ├── TrackerControllerViewModel.swift    # State Management
│   └── ErrorHandler.swift                  # Error Management
└── Resources/                      # Risorse UI
```

### Componenti Principali

- **TrackerControllerAudioUnit**: Core Audio Unit con DSP real-time safe
- **MIDIController**: Gestione messaggi MIDI con error recovery
- **TrackerMiniProtocol**: Protocollo specifico Tracker Mini
- **ControllerUI**: Interfaccia SwiftUI reattiva
- **ErrorHandler**: Sistema robusto di gestione errori
- **RTSafeLogger**: Logging thread-safe per real-time

### Real-Time Safety Features

- **Atomic State Management**: Thread-safe state access
- **Parameter Batching**: Raggruppamento aggiornamenti per efficienza
- **Lock-Free Logging**: Sistema di logging senza lock
- **Memory Pool**: Pool di memoria per messaggi MIDI
- **RT-Safe Validation**: Validazione parametri senza allocazioni

### MIDI Implementation v1.1.0

#### Control Change Messages
- CC 1: Modulation (Macro 1)
- CC 7: Master Volume
- CC 10: Pan (Track Pan)
- CC 11: Expression (Macro 2)
- CC 12-19: Track Volumes (1-8)
- CC 20-25: Macro Controls (1-6)
- CC 30-37: Track Mutes (1-8)
- CC 91: Reverb Send
- CC 93: Delay Send
- CC 16: Swing Amount
- CC 17: Pattern Length
- CC 18: Quantize On/Off

#### Program Change
- PC 0-127: Pattern Selection

#### Note Messages
- C3-G3: Track Triggers (1-8)
- C4: Play/Stop Toggle
- D4: Record Toggle

#### System Messages
- CC 121: Reset All Controllers
- CC 123: All Notes Off
- Panic: All Notes Off su tutti i canali

## Sviluppo

### Build Configuration

- **Target**: macOS 13.0+
- **Architecture**: arm64 (Apple Silicon nativo)
- **Language**: Swift 5.9+ con interop Objective-C
- **Framework**: AudioUnit, CoreMIDI, SwiftUI, AVFoundation
- **Real-Time Safety**: Compliant con Audio Unit v3

### Testing

```bash
# Test base
auval -v aumu TCTR POLY

# Test real-time safety
auval -v aumu TCTR POLY -real-time-safety

# Test performance
auval -v aumu TCTR POLY -performance

# Debug logging
log stream --predicate 'subsystem == "com.polyend.TrackerController"'

# Error monitoring
log stream --predicate 'subsystem == "com.polyend.TrackerController" AND category == "ErrorHandler"'
```

### Debugging

Il plugin include logging dettagliato per debug:

```swift
// Abilita debug logging
RTSafeLogger.log("Debug message", level: .debug)

// Error handling
TrackerControllerErrorHandler.shared.addErrorCallback { error in
    print("Error occurred: \(error.localizedDescription)")
}
```

### Performance Monitoring

```bash
# Monitor CPU usage
top -pid $(pgrep -f TrackerController)

# Monitor memory usage
leaks --atExit -- /path/to/TrackerControllerHost.app

# Profile real-time performance
instruments -t "Time Profiler" TrackerControllerHost.app
```

## Troubleshooting

### Plugin non appare nella DAW
1. Verifica che l'app host sia stata eseguita almeno una volta
2. Controlla registrazione con `pluginkit -m | grep TrackerController`
3. Riavvia la DAW
4. Verifica che Xcode completo sia installato (non solo Command Line Tools)

### Problemi di connessione MIDI
1. Verifica che il Tracker Mini sia connesso e acceso
2. Controlla impostazioni MIDI nella DAW
3. Verifica routing MIDI output
4. Usa il pulsante "Reconnect" nel plugin
5. Controlla Console.app per errori MIDI

### Performance Issues
1. Usa buffer size appropriato (256-512 samples)
2. Verifica che altri plugin Rosetta non interferiscano
3. Monitora CPU usage con Activity Monitor
4. Disabilita logging debug se non necessario
5. Controlla real-time safety con auval

### Errori di Compilazione
1. Assicurati di avere Xcode completo installato
2. Verifica versione macOS (13.0+)
3. Pulisci build folder: `rm -rf build/`
4. Controlla code signing settings

## Licenza

MIT License - Vedi file LICENSE per dettagli

## Contributi

I contributi sono benvenuti! Per favore:

1. Fork il repository
2. Crea un branch per la tua feature (`git checkout -b feature/amazing-feature`)
3. Commit le modifiche (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Apri una Pull Request

### Linee Guida per Contributi

- Mantieni real-time safety in tutti i cambiamenti
- Aggiungi test per nuove funzionalità
- Aggiorna documentazione per API changes
- Segui Swift style guide
- Includi error handling appropriato

## Supporto

Per supporto e bug reports:
- **GitHub Issues**: [Link al repository]
- **Email**: support@trackercontroller.com
- **Discord**: [Link al server Discord]

### Quando riporti un bug, includi:
- Versione macOS e DAW utilizzata
- Log di debug (`log stream --predicate 'subsystem == "com.polyend.TrackerController"'`)
- Passi per riprodurre il problema
- Configurazione hardware (Mac model, Tracker Mini firmware)

## Roadmap

### v1.2.0 (Prossimo)
- [ ] MIDI Learn UI completa
- [ ] Pattern visualization in tempo reale
- [ ] Multiple device support
- [ ] Custom MIDI mapping
- [ ] Automation curves

### v1.3.0 (Futuro)
- [ ] Standalone app version
- [ ] iOS companion app
- [ ] Cloud preset sharing
- [ ] Advanced pattern sequencing
- [ ] VST3 port

## Crediti

- **Sviluppo**: Community Polyend Tracker Mini
- **Framework**: Apple AudioUnit e CoreMIDI
- **UI**: SwiftUI e Combine
- **Testing**: Polyend Tracker Mini community
- **Ispirazione**: Polyend per aver creato un fantastico dispositivo

---

**Nota**: Questo plugin non è affiliato con Polyend. È un progetto open source della community.

**Versione**: 1.1.0  
**Data Rilascio**: Gennaio 2025  
**Compatibilità**: macOS 13.0+, Apple Silicon nativo 