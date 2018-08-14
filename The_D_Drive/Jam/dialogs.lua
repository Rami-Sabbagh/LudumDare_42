
--1
DIALOGS[1] = {
1,"Engineer",
[[Oh, you didn't crash while booting up ?

Thanks god for that !]],

1,"Engineer",
[[You're the only bot, from our 10 repair bots, who managed to boot up !]],

1,"Engineer",
[[Hmm....

Requesting diagnostic report...]],

2,"System",
[[Diagnostic Report:
- Robot ID: 8.
- SSD State: Unoperatable.
- ROM Version: v1.5.]],

2,"System",
[[- Available RAM: 6kb
- Available VRAM: 12kb
- Eelectonics Shield State: heavily damaged.]],

2,"System",
[[Warning:

- The ram is vulnerable to radiations !]],

1,"Engineer",
[[Oh no, any radiation would cause your RAM to become static over time !
Except your VRAM...]],

1,"Engineer",
[[Hmmm....]],

1,"Engineer",
[[Hmmmmmm....]],

1,"Engineer",
[[I've turned you on to send you into our factory's power section for repairing it...]],

1,"Engineer",
[[But it's full of power lasers, which emit radiations, that will affect your RAM...]],

1,"Engineer",
[[I'll modify your ROM so that once your RAM is all static, it will switch to use your VRAM as RAM.]],

1,"Engineer",
[[But at some point you'll run out of memory and BSOD..., I'll program you to return to the room entrance.]],

1,"Engineer",
[[At each rom entrance, I'll be able to reach you and replace your RAM with a new one.]],

1,"Engineer",
[[Okay, That's it !

Let's send you to the power section.]]
}
--2
DIALOGS[2] = {
1,"Engineer",
[[Use your arrow keys to move.]],

1,"Engineer",
[[On the top there is your memory bar:
Gray: Available RAM.
Indigo: Available VRAM.
]],

1,"Engineer",
[[The bar will be filled over time with red,
Red is the amount of memory changed to be static.]],

1,"Engineer",
[[You better finish the section as fast as you can, and not risk your bot.]],

1,"Engineer",
[[As I said before sending you here, Your memory will be replaced at each room start.]],

1,"Engineer",
[[GO GO GO !]]
}
--3
DIALOGS[3] = {
1,"Engineer",
[[Okay, this is the first room with lasers.]],

1,"Engineer",
[[You'll only have to block the laser for once,
and the door will open.]]
}
--4
DIALOGS[4] = {
1,"Engineer",
[[This room has a "mirror box", you can pick it up by and facing it and pressing [Z].]],

1,"Engineer",
[[You'll have to redirect this laser to the receiver in the bottom.]],

1,"Engineer",
[[You can toggle slow movement mode to help you position the box by pressing [X].]],

3,"Info",
[[You can skip any dialog by pressing [C], so you won't have to read the memory reload dialog again.]],
}
--5
DIALOGS[5] = {
1,"Engineer",
[[I've got something to work on, won't be able to help you for some rooms...]]
}

DIALOGS[6] = {
1,"Engineer",
[[Thanks robot #8 !

All the systems are back online :)]],

1,"Engineer",
[[I guess it's time to power you off.
Don't worry you'll be turned on again when in need.]],

4,"Developer",
[[Thanks for playing my Ludum Dare 42 Jam game !]],

4,"Developer",
[[I've spent lots of time working on the lasers system...]],

4,"Developer",
[[And then spent more time working on internal wires/signals system...]],

4,"Developer",
[[So didn't have enough time to work on the levels, managed to only do 6 :#]],

4,"Developer",
[[There were plans to do music, and more levels, but my school and life didn't allow me.]],

4,"Developer",
[[I hope you enjoyed it, tell me your thoughts in the comments, and please rate !]],

4,"Developer",
[[The game will now close and open the LudumDare page of it.]]
}

--Reset RAM dialog
DIALOGS[-1] = {
1,"Engineer",
[[Inserting new memory...]],

2,"System",
[[- New memory detected.
- Copying data from old memory.
- Unmounting old memory.]],

1,"Engineer",
[[Okay, all done, continue to the next stage !]]
}

--Crush dialog
DIALOGS[-2] = {
1,"Engineer",
[[Woah, what was that explosion sound ?]],

1,"Engineer",
[[Ah, the robot got crushed :(

I'll have to repair another robot...]],

3,"Info",
[[Your robot has been crushed.

You'll have to restart...]],

3,"Info",
[[TIP: Press [C] to skip the dialogs, so you won't have to read them when starting again.]]
}

--Death dialog
DIALOGS[0] = {
2,"System",
[[Operating system crashed !
Syntax error: BSOD_FALLBACK.lua:1073:unexpected symbol near ')']],

1,"Engineer",
[[WHAT !, 9 BEEPS !, SYSTEM CRASHED ?!?!
What did I do wrong in my code O_O]],

1,"Engineer",
[[OH, THAT DAMN BRACKET

I've lost that bot q-q]],

1,"Engineer",
[[Back into repairing the other bots...

-_-]],

3,"Info",
[[Your robot has been lost in the power section.

You'll have to restart...]],

3,"Info",
[[TIP: Press [C] to skip the dialogs, so you won't have to read them when starting again.]]
}