local _, NS = ...
NS.PropertyText = NS.PropertyText or {}
-- Mismo texto que es.properties
NS.PropertyText.es = [===[
# LevelGuide — español
# clave=valor. Comentarios con #. Saltos de línea con \n.

ui.tab.now=Ahora
ui.tab.now.tip=Qué hacer ahora
ui.tab.route=Ruta
ui.tab.route.tip=Ruta de leveo
ui.tab.dungeons=Mazmorras
ui.tab.dungeons.tip=Mazmorras para tu nivel
ui.tab.log=Diario
ui.tab.log.tip=Diario de misiones
ui.tab.settings=Ajustes
ui.tab.settings.tip=Opciones

ui.level=Nivel %d  ·  %s
ui.levelMax=Nivel máximo
ui.xp=XP %s / %s (%d%%)
ui.rested=  -  descanso %s
ui.page=Página %d/%d

ui.hero.badge=SIGUIENTE PASO
ui.hero.ok=Todo en orden
ui.hero.okSub=Sigue con tus misiones actuales.
ui.hero.view=Ver

ui.now.headerDungeon=En esta ida a %s
ui.now.header=Siguientes pasos de la ruta
ui.now.counter=Paso %d de la ruta
ui.now.counterEmpty=Ruta de leveo
ui.now.footer=Flecha abre el mapa de este paso. Clic derecho en un paso: saltarlo.

ui.route.counter=Tu nivel: %d
ui.route.footer=Ruta sugerida por la comunidad, no oficial. Clic en una zona para abrir su mapa.
ui.route.start=Empieza en %s
ui.route.also=También: %s

ui.levelTag=Niv. %d
ui.levelRange=Niv. %d-%d

ui.dg.counter=Mazmorras de tu ruta
ui.dg.footer=Las de tu facción, en el orden de nivel. Clic: misiones y dónde se cogen.
ui.dg.detailFooter=Izquierda: misiones y dónde se cogen. Derecha: jefe, modelo y botín.
ui.dg.oneQuest=%d misión
ui.dg.manyQuests=%d misiones
ui.dg.oneBoss=%d jefe
ui.dg.manyBosses=%d jefes
ui.dg.noQuests=Tu ruta no manda misiones de esta mazmorra.
ui.dg.back=< Lista
ui.dg.noBosses=Sin jefes
ui.dg.noBossesSub=Esta mazmorra no tiene jefes en la ficha.
ui.dg.loot=Botín del jefe. Ratón: ver. Mayús+clic: enlace.
ui.dg.place=Niv. %d  ·  %s
ui.dg.levelOnly=Niv. %d

ui.log.counter=En curso: %d
ui.log.footer=Clic izquierdo: marcar la misión en el mapa.
ui.log.grey=Gris: da muy poca XP
ui.log.active=En curso
ui.log.turned=Entregadas en esta sesión (%d)
ui.log.ready=Para entregar, la que abre primero (%d)
ui.log.other=Otras

ui.settings.counter=Se guarda solo
ui.settings.footer=Un clic cambia la opción. Clic derecho en un paso de Ahora lo salta.
ui.settings.title=Ajustes
ui.settings.route=La ruta
ui.settings.play=Mientras juegas
ui.settings.size=Tamaño: %s
ui.settings.restore=Recuperar pasos saltados
ui.settings.yes=SÍ
ui.settings.no=NO
ui.settings.lang=Idioma
ui.settings.langHint=Cambia todos los textos del addon.

ui.size.1=pequeño
ui.size.2=normal
ui.size.3=grande
ui.size.4=muy grande

ui.opt.quest=Aceptar y entregar solas
ui.opt.quest.hint=Shift pausa un momento.
ui.opt.sell=Vender lo gris
ui.opt.sell.hint=Al hablar con un vendedor.
ui.opt.repair=Reparar solo
ui.opt.repair.hint=Al hablar con un vendedor.
ui.opt.autoloot=Recoger el botín solo
ui.opt.autoloot.hint=Sin tener que pulsar.
ui.opt.dungeons=Mazmorras en la ruta
ui.opt.dungeons.hint=Si lo apagas, solo mundo abierto.
ui.opt.arrow=Flecha al cambiar de paso
ui.opt.arrow.hint=Marca el mapa ella sola.
ui.opt.xp=Cartel de leveo
ui.opt.xp.hint=Apagado no tapa la pantalla. Abajo si lo enciendes.
ui.opt.minimap=Botón del minimapa
ui.opt.minimap.hint=Para abrir la guía.
ui.opt.contrast=Alto contraste
ui.opt.contrast.hint=Letras más negras y fondo claro.
ui.opt.voice=Leer los avisos
ui.opt.voice.hint=En voz alta, si el juego puede.
ui.opt.lock=Fijar las ventanas
ui.opt.lock.hint=Dejan de moverse al arrastrar.

ui.mm.left=Clic izquierdo: abrir/cerrar la guía
ui.mm.right=Clic derecho: ajustes
ui.mm.drag=Arrastrar: mover el botón

track.zone=Levea en: %s
track.zoneWait=Levea en: calculando tu nivel
track.step=Paso: %s
track.stepWait=Paso: calculando
track.next=Luego: %s
track.nextNone=Luego: —
track.eta=Nivel en: %s
track.etaNone=Nivel en: --
track.xph=XP/h: %s    %s

task.noGuide=No hay ruta cargada
task.noGuideSub=Falta Guide.lua. Sin esa ruta el addon no puede decirte el paso.
task.badge.dungeonEnter=MAZMORRA · ENTRA
task.badge.travel=RUTA · VIAJA
task.badge.dungeonGet=MAZMORRA · COGE
task.badge.accept=RUTA · ACEPTA
task.badge.dungeonIn=MAZMORRA · DENTRO
task.badge.do=RUTA · HAZ ESTO
task.badge.dungeonTurn=MAZMORRA · ENTREGA
task.badge.turn=RUTA · ENTREGA
task.badge.route=RUTA
task.enter=Entra en %s
task.go=Ve a %s
task.enterSub=Coge primero las misiones de %s y hazlas en una sola ida.
task.goSub=El siguiente tramo de la ruta está ahí. No importa en qué zona estés ahora.
task.openMap=Abrir mapa
task.arrow=Flecha
task.map=Mapa
task.questFallback=Misión %s
task.accept=Acepta «%s»
task.give=La da %s. 
task.acceptDg=Cógelas todas antes de entrar en %s.
task.acceptRoute=Es el siguiente paso de la ruta, no una misión cualquiera del diario.
task.do=Haz «%s»
task.doFallback=Sigue el objetivo de la misión.
task.turn=Entrega «%s»
task.to=A %s. 
task.turnDg=Al salir de %s.
task.turnRoute=En la ruta esta entrega va ahora: abre el paso siguiente.
task.grabN=Coge las %d misiones de %s
task.grabSub=%s. Todas, antes de entrar: es lo que hace rentar la ida. En el mapa salen donde se cogen.
task.grab=Coge las misiones de %s
task.grabSub2=%s. Cógelas todas antes de entrar: van en la misma ida.
task.sameRun= En la misma ida haz también: %s.
task.done=No queda ningún paso que aún dé experiencia
task.doneSub=Has hecho, o ya no rinde, todo lo que la ruta tenía para tu nivel.
task.startZone=tu zona de inicio
task.quote=«%s»

msg.go=Ve a: %s (niveles %s)
msg.noMap=(No tengo el mapa de esta zona: ábrelo con M.)
msg.tracked=Misión marcada%s. Mira el mapa y el minimapa.
msg.trackedTitle=: %s
msg.arrowTo=Flecha hasta %s.
msg.arrowQuest=la misión
msg.levelNow=Nivel %d - qué hacer ahora:
msg.levelUp=Nivel %d. La ruta avanzó al siguiente paso.
msg.next=Siguiente paso: %s
msg.sold=Vendidos %d objetos grises: %s
msg.repaired=Reparado por %s
msg.repairNoGold=No tienes oro suficiente para reparar (%s).
msg.pinTitle=Coge aquí
msg.pinClick=Clic: flecha hasta este sitio
msg.on=ACTIVADO
msg.off=DESACTIVADO
msg.loaded=cargado. Pulsa el botón del minimapa o escribe /lg para abrir la guía.
msg.skipped=Pasos saltados recuperados.
msg.noOutside=Esta misión no tiene un NPC fuera. Se coge o cae dentro.
msg.helpTitle=comandos (/lg o /levelguide):
msg.help1=  /lg: abre o cierra la guía  |  /lg opciones: ventana de opciones
msg.help2=  /lg ruta: escribe tus próximos pasos en el chat  |  /lg leer: el siguiente paso en voz alta
msg.help3=  /lg tamano <1-4>: tamaño (ahora %s)
msg.help4=  /lg restaurar: muestra las tareas ocultas  |  /lg reset: reinicia el contador de XP
msg.help5=  /lg idioma <es|en>: cambia el idioma
msg.helpOpt=  /lg %s: %s  - %s
msg.size=tamaño: %s
msg.sizeUsage=uso: /lg tamano <1-4> (1 pequeño, 2 normal, 3 grande, 4 muy grande)
msg.opt=%s: %s
msg.xpReset=contador de XP reiniciado.
msg.restored=tareas ocultas restauradas.
msg.allOk=Todo en orden.
msg.lang=Idioma: %s
msg.langUsage=uso: /lg idioma es  |  /lg idioma en

faction.Horde=Horda
faction.Alliance=Alianza

dg.Wailing Caverns=Cuevas de los Lamentos
dg.The Deadmines=Minas de la Muerte
dg.Shadowfang Keep=Castillo de Colmillo Oscuro
dg.Blackfathom Deeps=Cavernas de Brazanegra
dg.Ragefire Chasm=Sima Ígnea
dg.The Stockade=Las Mazmorras
dg.Gnomeregan=Gnomeregan
dg.Razorfen Kraul=Horado Rajacieno
dg.Razorfen Downs=Zahúrda Rajacieno
dg.Scarlet Monastery=Monasterio Escarlata
dg.Scarlet Monastery: Library=Monasterio Escarlata
dg.Uldaman=Uldaman
dg.Zul'Farrak=Zul'Farrak
dg.Maraudon=Maraudon
dg.The Temple of Atal'Hakkar=Templo de Atal'Hakkar
dg.Temple of Atal'Hakkar=Templo de Atal'Hakkar
dg.Blackrock Depths=Profundidades de Roca Negra
dg.Blackrock Spire=Cumbre de Roca Negra
dg.Dire Maul=La Masacre
dg.Scholomance=Scholomance
dg.Stratholme=Stratholme
dg.Ruins of Lordaeron=Ruinas de Lordaeron
dg.Excavation Site=Excavación de los Humedales
dg.City of Dalaran=Ciudad de Dalaran
ui.dg.pick=Coge con %s. Clic: mapa.
ui.dg.pickNpc=el NPC
ui.dg.kind=Niv. %d-%d%s

]===]
