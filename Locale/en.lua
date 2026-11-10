local _, NS = ...
NS.PropertyText = NS.PropertyText or {}
-- Mismo texto que en.properties
NS.PropertyText.en = [===[
# LevelGuide — English
# key=value. Comments start with #. Line breaks with \n.

ui.tab.now=Now
ui.tab.now.tip=What to do now
ui.tab.route=Route
ui.tab.route.tip=Leveling route
ui.tab.dungeons=Dungeons
ui.tab.dungeons.tip=Dungeons for your level
ui.tab.log=Log
ui.tab.log.tip=Quest log
ui.tab.settings=Settings
ui.tab.settings.tip=Options

ui.level=Level %d  ·  %s
ui.levelMax=Max level
ui.xp=XP %s / %s (%d%%)
ui.rested=  -  rested %s
ui.page=Page %d/%d

ui.hero.badge=NEXT STEP
ui.hero.ok=All set
ui.hero.okSub=Keep going with your current quests.
ui.hero.view=View

ui.now.headerDungeon=On this run to %s
ui.now.header=Next steps on the route
ui.now.counter=Step %d of the route
ui.now.counterEmpty=Leveling route
ui.now.footer=Arrow opens this step on the map. Right-click a step to skip it.

ui.route.counter=Your level: %d
ui.route.footer=Community route, not official. Click a zone to open its map.
ui.route.start=Start at %s
ui.route.also=Also: %s

ui.levelTag=Lv. %d
ui.levelRange=Lv. %d-%d

ui.dg.counter=Dungeons on your route
ui.dg.footer=Your faction, in level order. Click: quests and where to pick them up.
ui.dg.detailFooter=Left: quests and where to pick them up. Right: boss, model and loot.
ui.dg.oneQuest=%d quest
ui.dg.manyQuests=%d quests
ui.dg.oneBoss=%d boss
ui.dg.manyBosses=%d bosses
ui.dg.noQuests=Your route has no quests for this dungeon.
ui.dg.back=< List
ui.dg.noBosses=No bosses
ui.dg.noBossesSub=This dungeon has no bosses on the card.
ui.dg.loot=Boss loot. Mouse: view. Shift-click: link.
ui.dg.place=Lv. %d  ·  %s
ui.dg.levelOnly=Lv. %d

ui.log.counter=Active: %d
ui.log.footer=Left-click: track the quest on the map.
ui.log.grey=Grey: very little XP
ui.log.active=In progress
ui.log.turned=Turned in this session (%d)
ui.log.ready=Ready to turn in, the one that opens the next (%d)
ui.log.other=Other

ui.settings.counter=Saved automatically
ui.settings.footer=One click changes the option. Right-click a step on Now to skip it.
ui.settings.title=Settings
ui.settings.route=The route
ui.settings.play=While you play
ui.settings.size=Size: %s
ui.settings.restore=Restore skipped steps
ui.settings.yes=YES
ui.settings.no=NO
ui.settings.lang=Language
ui.settings.langHint=Switches every text in the addon.

ui.size.1=small
ui.size.2=normal
ui.size.3=large
ui.size.4=very large

ui.opt.quest=Accept and turn in quests
ui.opt.quest.hint=Shift pauses it for a moment.
ui.opt.sell=Sell grey items
ui.opt.sell.hint=When you talk to a vendor.
ui.opt.repair=Repair automatically
ui.opt.repair.hint=When you talk to a vendor.
ui.opt.autoloot=Loot automatically
ui.opt.autoloot.hint=No need to click.
ui.opt.dungeons=Dungeons on the route
ui.opt.dungeons.hint=Off means open world only.
ui.opt.arrow=Arrow when the step changes
ui.opt.arrow.hint=Marks the map by itself.
ui.opt.xp=Leveling banner
ui.opt.xp.hint=Off keeps the screen clear. On sits at the bottom.
ui.opt.minimap=Minimap button
ui.opt.minimap.hint=Opens the guide.
ui.opt.contrast=High contrast
ui.opt.contrast.hint=Darker letters and a light background.
ui.opt.voice=Read alerts aloud
ui.opt.voice.hint=If the game can speak.
ui.opt.lock=Lock windows
ui.opt.lock.hint=They stop moving when dragged.

ui.mm.left=Left-click: open or close the guide
ui.mm.right=Right-click: settings
ui.mm.drag=Drag: move the button

track.zone=Level in: %s
track.zoneWait=Level in: working out your level
track.step=Step: %s
track.stepWait=Step: working it out
track.next=Then: %s
track.nextNone=Then: —
track.eta=Level in: %s
track.etaNone=Level in: --
track.xph=XP/h: %s    %s

task.noGuide=No route loaded
task.noGuideSub=Guide.lua is missing. Without that route the addon cannot tell you the step.
task.badge.dungeonEnter=DUNGEON · ENTER
task.badge.travel=ROUTE · TRAVEL
task.badge.dungeonGet=DUNGEON · PICK UP
task.badge.accept=ROUTE · ACCEPT
task.badge.dungeonIn=DUNGEON · INSIDE
task.badge.do=ROUTE · DO THIS
task.badge.dungeonTurn=DUNGEON · TURN IN
task.badge.turn=ROUTE · TURN IN
task.badge.route=ROUTE
task.enter=Enter %s
task.go=Go to %s
task.enterSub=Pick up the %s quests first and do them in one run.
task.goSub=The next stretch of the route is there. It does not matter which zone you are in.
task.openMap=Open map
task.arrow=Arrow
task.map=Map
task.questFallback=Quest %s
task.accept=Accept "%s"
task.give=From %s. 
task.acceptDg=Pick them all up before you enter %s.
task.acceptRoute=This is the next step on the route, not just any quest in your log.
task.do=Do "%s"
task.doFallback=Follow the quest objective.
task.turn=Turn in "%s"
task.to=To %s. 
task.turnDg=After you leave %s.
task.turnRoute=On the route this turn-in is now: it opens the next step.
task.grabN=Pick up the %d quests for %s
task.grabSub=%s. All of them, before you enter: that is what makes the run worth it. The map shows where to get them.
task.grab=Pick up the quests for %s
task.grabSub2=%s. Pick them all up before you enter: they belong to the same run.
task.sameRun= On the same run also do: %s.
task.done=No step left that still gives experience
task.doneSub=You have done, or outleveled, everything the route had for your level.
task.startZone=your starting zone
task.quote="%s"

msg.go=Go to: %s (levels %s)
msg.noMap=(I do not have this zone's map: open it with M.)
msg.tracked=Quest tracked%s. Check the map and the minimap.
msg.trackedTitle=: %s
msg.arrowTo=Arrow to %s.
msg.arrowQuest=the quest
msg.levelNow=Level %d - what to do now:
msg.levelUp=Level %d. The route moved on to the next step.
msg.next=Next step: %s
msg.sold=Sold %d grey items: %s
msg.repaired=Repaired for %s
msg.repairNoGold=Not enough gold to repair (%s).
msg.pinTitle=Pick up here
msg.pinClick=Click: arrow to this spot
msg.on=ON
msg.off=OFF
msg.loaded=loaded. Click the minimap button or type /lg to open the guide.
msg.skipped=Skipped steps restored.
msg.noOutside=This quest has no NPC outside. It is picked up or dropped inside.
msg.helpTitle=commands (/lg or /levelguide):
msg.help1=  /lg: open or close the guide  |  /lg options: settings window
msg.help2=  /lg route: print your next steps  |  /lg read: speak the next step
msg.help3=  /lg size <1-4>: size (now %s)
msg.help4=  /lg restore: show hidden tasks  |  /lg reset: reset the XP counter
msg.help5=  /lg lang <es|en>: change the language
msg.helpOpt=  /lg %s: %s  - %s
msg.size=size: %s
msg.sizeUsage=usage: /lg size <1-4> (1 small, 2 normal, 3 large, 4 very large)
msg.opt=%s: %s
msg.xpReset=XP counter reset.
msg.restored=Hidden tasks restored.
msg.allOk=All set.
msg.lang=Language: %s
msg.langUsage=usage: /lg lang es  |  /lg lang en

faction.Horde=Horde
faction.Alliance=Alliance

dg.Wailing Caverns=Wailing Caverns
dg.The Deadmines=The Deadmines
dg.Shadowfang Keep=Shadowfang Keep
dg.Blackfathom Deeps=Blackfathom Deeps
dg.Ragefire Chasm=Ragefire Chasm
dg.The Stockade=The Stockade
dg.Gnomeregan=Gnomeregan
dg.Razorfen Kraul=Razorfen Kraul
dg.Razorfen Downs=Razorfen Downs
dg.Scarlet Monastery=Scarlet Monastery
dg.Scarlet Monastery: Library=Scarlet Monastery
dg.Uldaman=Uldaman
dg.Zul'Farrak=Zul'Farrak
dg.Maraudon=Maraudon
dg.The Temple of Atal'Hakkar=Temple of Atal'Hakkar
dg.Temple of Atal'Hakkar=Temple of Atal'Hakkar
dg.Blackrock Depths=Blackrock Depths
dg.Blackrock Spire=Blackrock Spire
dg.Dire Maul=Dire Maul
dg.Scholomance=Scholomance
dg.Stratholme=Stratholme
dg.Ruins of Lordaeron=Ruins of Lordaeron
dg.Excavation Site=Excavation Site
dg.City of Dalaran=City of Dalaran
ui.dg.pick=Pick up from %s. Click: map.
ui.dg.pickNpc=the NPC
ui.dg.kind=Lv. %d-%d%s

]===]
