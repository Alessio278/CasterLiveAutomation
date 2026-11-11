# Languages / Lingue

Il selettore nella scheda **Panoramica** consente di cambiare tra **Italiano**, **English**, **Français** ed **Español**. L'impostazione è persistente nel file personale `CasterLiveAutomation_Settings.ini`, sezione `[UI]`, chiave `Language`, con i codici `it`, `en`, `fr`, `es`.

Le traduzioni coprono le principali etichette, le schede, le intestazioni, i pulsanti e parte dell'editor delle schedulazioni. Alcuni messaggi avanzati e i log rimangono in italiano. La scelta linguistica non deve alterare le chiavi INI, i nomi dei giorni salvati, i token di evento, gli stati sessione o le istruzioni eseguite dal Worker.

Per contribuire con traduzioni, modificare soltanto le stringhe di `InitTranslations()` nella GUI e testare su Windows a 640×640, con DPI 100% e 125%. Non modificare lo scheduler per tradurre l'interfaccia.

## Correzione selettore / Visual fix

La DropDownList usa `r4` (non `h28`): la sua altezza totale deve contenere tutte e quattro le voci. Durante il ridimensionamento non impostare mai il parametro `Height` per questa tendina.

Dopo il cambio lingua il pannello ridisegna anche il contenitore figlio di `Tab3`; non è necessario spostare il mouse sulle etichette per renderle visibili. Il menu delle lingue e i pulsanti usano volutamente i colori nativi ad alto contrasto per essere leggibile indipendentemente dalla modalità scura di Windows.

Per il collaudo manuale su Windows: aprire ciascuna delle quattro lingue, verificare menu aperto con tutte le voci, sfogliare tutte le schede, ridimensionare da 640x640 a schermo intero e tornare alla dimensione iniziale; verificare che i pulsanti e i dati non salvati restino disponibili.
