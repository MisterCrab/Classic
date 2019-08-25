-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
--[[
If you use lua then you can skip it. If you didn't read 1. Introduction.lua you have to read before continue
]]

-------------------------------------------------------------------------------
-- №1 Create for profile groups
-------------------------------------------------------------------------------
--[[
1. First you need create own profile:
Write in chat /tmw > Right click on some opened frame > Click on 'General' > 'Main settings' (or 'Main options') > at the top you will see dropdown menu abd below 'Write name'
Write your own name and press 'Enter'
Then you can (recommend) copy template '[GGL] Template' or '[GGL] Basic' by overwrite current profile 

'[GGL] Template' is mostly used for 'The Action' but it's totally clear empty profile to build even without LUA
'[GGL] Basic' is already preconfigured profile with PvE and PvP groups 

It will apply for you content of copied profile which you can edit and skip next steps 

2. If you don't use template then you have to create from scretch important group:

For "Shown Cast Bars":
1. You have to create in /tmw new profile group with 3-9 icons with type "Casting" 
2. Right click on "Casting" make checked "Hide Always"
3. Don't forget which colors as casting bar icons use (look any [GGL] profile for colors), and also make sure what profile has "Flat" texture (you can check it in /tmw > 'General' > 'Main settings' (or 'Main options')

3. The most popular is to create at first 2 groups PvE and PvP
Write in chat /tmw > Right click on some opened frame > Click on 'Groups' > '+' > Write your own name 
Set required for yourself number of icons and rows with scale and position
]]

-------------------------------------------------------------------------------
-- №2 Create content and logic for profile groups
-------------------------------------------------------------------------------
--[[
If you finished with №1 and you see at the left upper corner group with name "Shown Main" and it's 1 like "Shown Main (1)" then you did all correctly, if not then return to look above

TellMeWhen interface of edit is very easy and allows make very solid functional without know lua with intuite understand able menu

1. You have to create any icon in group of PvE or PvP for example
2. Select type Icon, like 'Cooldown', and write below ID of 'What to track' with settings like 'Range Check'
3. Select enabled 'Hide Always'
4. For more logic you have to use 'Conditions' tab of this icon where you can click '+' and use any suggested conditions which you want
5. After conditions are done drag abd move this icon to "Meta Icon" of the "Shown Group" and select from opened menu "Add to this meta"

Which "Meta Icon" I have to use? 
Mostly for begin is enough #3 which is Single rotation, you can look 1. Introduction.lua about what and which meta does for explain

Priority:
Rotation is based on priority: 1. Spell > 2. Spell > 3. Spell > and etc.. 
To change it and edit whenver you need, you have to right click on "Meta Icon" which you used for adding created icons and there are you will see some kind of list which exactly does priority from top to down
You can moe any elements where as you need 

Make sure what each "Meta Icon" in "Shown Main" and "Shown Cast Bars" has UNCHECKED "Hide always"

How to get at the middle of the center on my screen display of the next spell / action?
Create new group and create there icon with type "Meta Icon"
Drag from "Shown Main" required "Meta Icon" to created at the center "Meta Icon" and click "Add to meta"

Is that's all? 
Probably yes because for TellMeWhen no any guide or video movie education about how to because interface is 'click able to learn', you can ask help by people who use TMW about how to configure your conditions if you're confused
You also can use this guide to edit and modify existed profiles which uses by 'The Action' like [GGL] Monk
]]

