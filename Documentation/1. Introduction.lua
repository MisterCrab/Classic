-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
--[[
This documentation describes the behavior and methods of writing user profiles 
]]

-------------------------------------------------------------------------------
-- Conception and Basics
-------------------------------------------------------------------------------
--[[
TellMeWhen initiates the frame editor with self API, and 'The Action' loads own API

API (Application Programming Interface)
Both TellMeWhen and The Action API's are used for profiles and they are shared betwen themselves
You can't edit these API's because if you will make changes then in the next time of update through ProfileInstall they will be overwritten by github version
If you want to use github updates and at same time own changed API then you will need use global 'Snippets' (look about that below, in title 'About profile')

About TMW.db
This is DataBase is used to store your profile and his settings for TellMeWhen 

About DataBase 
DataBase stores on the following path **World of Warcraft\WTF\Account\YOUR ACCOUNT NAME\SavedVariables\TellMeWhen.lua** which is used to Export and share your all profiles, settings with other people by ProfileInstall and they can Import it by your exported file (we will return to this moment at the end of the documentation steps)

About profile 
---
When you login in game you can open TMW by chat command /tmw and enter in TMW interface by right click on some frame. Then go to 'General' tab then 'Main Options' (or 'Main Settings') and here is at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy', 'Delete'. This is TMW.db
Also there are 'LUA Snippets' (or just 'Snippets') tab which will be used for 'The Action' and you're not limited to use it only for that, you can use it for HeroLib API and any your own lua. This is optional because you can create profile without known lua skills 
Snippets are 'Profile Snippets' and 'Global Snippets':
* 'Profile Snippets' is local which means what they are attached only for CURRENT profile 
* 'Global Snippets' is super global (TMW.db.global) which means they are attached for EACH profile. If you want to use custom API then use global 

Profile must has 2 local groups. The groups are same like 'Snippets' - local and global
First group must be named "Shown Main" without quotes, it must contain 8 icons inside and should be in the upper left corner of the screen, like [1][2][3][4][5][6][7][8], type of group must be "Icon"
* [1] is AntiFake CC rotation (limited, usually is single color like 0x00FF00 which is green)
* [2] is AntiFake Kick rotation (racial, primary specialization interrupt spell)
* [3] is Single rotation (supports all actions)
* [4] is AoE rotation (supports all actions)
* [5] is Trinket rotation (racial, specialization spells which can remove CC)
* [6] is Passive rotation (limited actions, usually @player, @raid1, @arena1)
* [7] is Passive rotation (limited actions, usually @party1, @raid2, @arena2)
* [8] is Passive rotation (limited actions, usually @party2, @raid3, @arena3)
Passive rotation doesn't require button use like it does [1] -> [5] rotations 
"Shown Main" in group settings must have x-29, y12, scale 60% and both padding to the left upper corner 

Second group must be named "Shown Cast Bars" and contain max 3 icons per 1 row, this means what you can have totally 9 icons with 3 rows, type of group must be "Bar" (horizontal) and follow right after "Shown Main". It does use "Flat" texture of casting bar, make sure what you have selected it in /tmw > 'General' > 'Main Options' (or 'Main Settings') 
[1]		[2]		[3]
[4]		[5]		[6]
[7]		[8]		[9]
@arena1 @arena2 @arena3
This is used to interrupt by Kick Arena1-3 and option timings
* [1] -> [3] is green (Heals) / red (PvP) PlayerKick / yellow AutCastBarsSpells (such as Reflect, Paralyzes, Ground Totem)
* [4] -> [6] is green (Heals) / red (PvP) PetKick
* [7] -> [9] is red Simulacrum (currently used only on Death Knight)
"Shown Cast Bars" must have x507, y17, scale 40% and both padding to the left upper corner

These 2 groups must be first groups at the top of group list e.g. TellMeWhen_Group1 ("Shown Main") and TellMeWhen_Group2 ("Shown Cast Bars"). Rest after that doesn't matter at all, you can use own groups like to display at the middle of the center on your screen next rotation action to use with graphic mode PvE PvP and etc 
Each icon in each group must be as 'meta icon' type (this is green eye)

After "Shown Cast Bars" group to the right of it follows HealingEngine frame, so if you make 4+ icons in 1 row of "Shown Cast Bars" group it will has position higher than HealingEngine which will make you conflict on healers

Also your name of profile must be different than has it ProfileInstall Import (from server), because if you name will be same it will be overwritten by server version, use own name, like [GGL] My Profile 
---

Hard to figure? 
Let's make it easier, I prepared template profile named '[GGL] Template', you can create new profile with own name and then use 'Copy' from '[GGL] Template' which will make for you prepared for 'The Action' API these 2 groups. So when that is done you can build own routine now.
]]

-------------------------------------------------------------------------------
-- Summarize
-------------------------------------------------------------------------------
--[[
Begin starts by profile create: Write in chat /tmw go to 'General' then 'Main Options' (or 'Main Settings') and there are at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy'

Use template profile named '[GGL] Template' or ('[GGL] Basic' if you don't plan to use LUA) with own name either keep in mind and follow by the next tips:
1. Your profile name must be different than it has loaded from ProfileInstall > Import TellMeWhen (from server)
2. Your profile must have first groups with following names: "Shown Main", "Shown Cast Bars"
3. "Shown Main" must have 8 icons with type "meta icon" and group type "Icon" in only 1 row at the left upper corner of your screen
4. "Shown Cast Bars" must have max 3 icons with type "meta icon" per 1 row and group type "Bar" following in the right side of "Shown Main"
5. "Shown Cast Bars" uses "Flat" texture of casting bar, make sure what you have selected it in /tmw > 'General' > 'Main Options' (or 'Main Settings') 
6. "Shown Main" in group settings must have x-29, y12, scale 60% and both padding to the left upper corner 
7. "Shown Cast Bars" must have x507, y17, scale 40% and both padding to the left upper corner
]]