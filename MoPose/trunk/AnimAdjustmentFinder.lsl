////////////////////////////////////////////////////////////////////////////
//
// $Id$
// [Copyright and BSD (free) license included at bottom.]
//
// Go to http://imohax.com/mopose for help, FAQ, video HOWTOs, and comments
//       ^^^^^^^^^^^^^^^^^^^^^^^^
//
////////////////////////////////////////////////////////////////////////////

// Customize your configuration in this section.

vector   TARGET_POS = <0.0,0.0,0.01>;
rotation TARGET_ROT = ZERO_ROTATION;
string   ANIMS_CARD = "animations";
string   START_TEXT = "Animation Adjustment Tool\n(have a seat)";
string   ADDED_TEXT = "Added animation ";
string   GOTIT_TEXT = "Have already. Skipping ";
string   HOME_TEXT  = "Home not yet set.";
string   PLAY_TEXT  = "Playing ";
string   HAVE_HELP  = "Say 'help' for list of commands.";
string   HELP_TEXT  = "
Version: $Id$
help - Say this help to public chat
add - Rescans inventory for animations and adds them to list
add <NAME> - Scans the directory for anim NAME and adds it to list
save home - Sets current as home position
save or s - Saves current adjustment for current anim playing
save <NAME> - Forces save of current adjustment as anim NAME
play <NAME> - Repositions for and plays anim NAME
play next - Repositions for and plays next animation
next or n - Same as 'play next'
play prev - Repositions for and plays previous animation
prev or p - Same as 'play prev'
go <NAME> - Repositions for anim NAME, but does not play it
go home - Repositions to last saved home position
tell or t - Lists all adjustments for cutting and pasting
stand - Just unsit the sitting avatar
";
    

// End of configuration section

////////////////////////////////////////////////////////////////////////////
////////////////   Danger LSL ahead, scripters only. ;) ////////////////////
////////////////////////////////////////////////////////////////////////////

// 'set home' stores regional position and rotation of avatar
vector   gHomePos         = ZERO_VECTOR;
rotation gHomeRot         = ZERO_ROTATION;
vector   gLastHomePos     = ZERO_VECTOR;
rotation gLastHomeRot     = ZERO_ROTATION;
vector   gLastHomePrimPos = ZERO_VECTOR;
rotation gLastHomePrimRot = ZERO_ROTATION;

// 'set home' stores the prim position and rotation in region coordinates
vector   gHomePrimPos = ZERO_VECTOR;
rotation gHomePrimRot = ZERO_ROTATION;

// hash table of adjustment data
list gAdjNames;
list gAdjPoss;
list gAdjRots;
list gAdjPrimPoss;
list gAdjPrimRots;

// stores the current position in region coordinates
vector   gAvatarPos;
rotation gAvatarRot;
vector   gPrimPos;
rotation gPrimRot;

// stores the difference between current and home as adjustment
string   gAdjName    = "";
vector   gAdjPos     = ZERO_VECTOR;
rotation gAdjRot     = ZERO_ROTATION;
vector   gAdjPrimPos = ZERO_VECTOR;
rotation gAdjPrimRot = ZERO_ROTATION;

key gAvatar = NULL_KEY;
string gPlaying;

////////////////////////////////////////////////////////////////////////////////

updateCurrent()
{
    list details = llGetObjectDetails(gAvatar,[OBJECT_POS,OBJECT_ROT]);
    gAvatarPos = llList2Vector(details,0);
    gAvatarRot = llList2Rot(details,1);

    gPrimPos = llGetRootPosition();
    gPrimRot = llGetRootRotation();

    gAdjPos = (gAvatarPos-gHomePos)/gHomeRot + <0.0,0.0,0.365>; // target err
    gAdjRot = gAvatarRot/gHomeRot;

    gAdjPrimPos = (gPrimPos-gHomePrimPos)/gHomePrimRot;
    gAdjPrimRot = gPrimRot/gHomePrimRot;
}

//------------------------------------------------------------------------------

save(string _name)
{
    if (_name == "") _name = gAdjName;
    else gAdjName = _name;

    if (_name == "" || gAvatar == NULL_KEY)
    {
        say("?");
        return;
    }

    if (_name == "home")
    {
        updateHome();
        tell("home");
        return;
    }

    updateCurrent();

    integer i = llListFindList(gAdjNames,[_name]);

    string line = _name + ", " + (string) gAdjPos + ", " + (string) gAdjRot;

    if (i >= 0 )
    {
        gAdjNames    = llListReplaceList(gAdjNames,[_name],i,i);
        gAdjPoss     = llListReplaceList(gAdjPoss,[gAdjPos],i,i);
        gAdjRots     = llListReplaceList(gAdjRots,[gAdjRot],i,i);
        gAdjPrimPoss = llListReplaceList(gAdjPrimPoss,[gAdjPrimPos],i,i);
        gAdjPrimRots = llListReplaceList(gAdjPrimRots,[gAdjPrimRot],i,i);
    }
    else
    {
        gAdjNames    += [gAdjName];
        gAdjPoss     += [gAdjPos];
        gAdjRots     += [gAdjRot];
        gAdjPrimPoss += [gAdjPrimPos];
        gAdjPrimRots += [gAdjPrimRot];
    }

    say(line);
}

//------------------------------------------------------------------------------

tell(string _name)
{
    if (_name == "" || _name == "all")
    {
        string buffer;
        integer i;
        integer start = 1;
        integer max = llGetListLength(gAdjNames);

        for (i=0; i<max; i++)
        {
            buffer += "\n" + llList2String(gAdjNames,i)
                + ", " + llList2String(gAdjPoss,i)
                + ", " + llList2String(gAdjRots,i);

            if ( (i+1) % 10 == 0)
            {
                say((string) (i-10) + "-" + (string) (i+1)
                    + ":\n" + buffer + "\n");
                start = i+2;
                buffer = "";
            }
        }

        if (buffer != "")
        {
            say((string) start + "-" + (string) (i) + ":\n" + buffer + "\n");
        }
    }

    else if (_name == "last")
    {
        say("\n" + gAdjName + "," + (string) gAdjPos + "," + (string) gAdjRot);
    }

    else if (_name == "home")
    {
        say("\nhome," + (string) gHomePos + "," + (string) gHomeRot);
    }

    else
    {
        integer i = llListFindList(gAdjNames,[_name]);
        if (i<0) say(_name + "?");
        else
        {
            say("\n" + _name + "," + llList2String(gAdjPoss,i)
                + "," + llList2String(gAdjRots,i) );
        }
    }
}

//------------------------------------------------------------------------------

updateHome()
{
    updateCurrent();

    gLastHomePos     = gHomePos;
    gLastHomeRot     = gHomeRot;
    gLastHomePrimPos = gHomePrimPos;
    gLastHomePrimRot = gHomePrimRot;

    gHomePos     = gAvatarPos;
    gHomeRot     = gAvatarRot;
    gHomePrimPos = gPrimPos;
    gHomePrimRot = gPrimRot;

    gAdjNames    = [];
    gAdjPoss     = [];
    gAdjRots     = [];
    gAdjPrimPoss = [];
    gAdjPrimRots = [];

    add("");
}

//------------------------------------------------------------------------------

moveTo(string _name, vector _pos, rotation _rot)
{
    integer max = 100;
    integer i = 0;

    llSetPrimitiveParams([PRIM_POSITION,_pos,PRIM_ROTATION,_rot]);

    while (llGetPos() != _pos) {
        llSetPrimitiveParams([PRIM_POSITION,_pos,PRIM_ROTATION,_rot]);
        if (i == max)
        {
            jump OutAgain;
        }
        ++i;
    }
    @OutAgain;
}

//------------------------------------------------------------------------------

go(string _name)
{
    if (gHomePrimPos==ZERO_VECTOR)
    {
        llOwnerSay(HOME_TEXT);
        return;
    }

    updateCurrent();

    if (_name == "")
    {
        _name = gAdjName;
    }

    else if (_name == "home")
    {
        moveTo("home",gHomePrimPos,gHomePrimRot);
        return;
    }

    integer i = llListFindList(gAdjNames,[_name]);
    if (i<0)
    {
        say(_name + "?");
    }

    else
    {
        vector   adjPrimPos = llList2Vector(gAdjPrimPoss,i);
        rotation adjPrimRot = llList2Rot(gAdjPrimRots,i);

        vector   newPrimPos = gHomePrimPos + (adjPrimPos * gHomePrimRot);
        rotation newPrimRot = gHomePrimRot * adjPrimRot;

        moveTo(_name, newPrimPos, newPrimRot);
        return;
    }
}

//------------------------------------------------------------------------------

_play(string _name)
{
    if (gPlaying != "") llStopAnimation(gPlaying);
    go(_name);
    llStartAnimation(_name);
    say(PLAY_TEXT + "'" + _name + "'");
    gPlaying = _name;
    gAdjName = _name;
}

//------------------------------------------------------------------------------

play(string _name)
{
    if (_name == "") return;

    integer i = llListFindList(gAdjNames,[_name]);
    if (i>=0)
    {
        _play(_name);
        return;
    }

    integer count = llGetListLength(gAdjNames);

    integer current = 0;
    if (gAdjName != "")
        current = llListFindList(gAdjNames,[gAdjName]);

    if (_name == "next")
    {
        current++;
        if (current==count) current = 0;
        _play(llList2String(gAdjNames,current));
        return;
    }

    else if (_name == "prev")
    {
        current--;
        if (current<0) current = count-1;
        _play(llList2String(gAdjNames,current));
        return;
    }

    say(_name + "?");
    return;
}

//------------------------------------------------------------------------------

_add(string _name)
{
    if (llListFindList(gAdjNames,[_name])<0)
    {
        gAdjNames    += _name;
        gAdjPoss     += ZERO_VECTOR + <0.0,0.0,0.365>; // target err;
        gAdjRots     += ZERO_ROTATION;
        gAdjPrimPoss += ZERO_VECTOR;
        gAdjPrimRots += ZERO_ROTATION;
        say(ADDED_TEXT + "'" + _name + "'");
    }
    else
        say (GOTIT_TEXT + "'" + _name + "'");
}

//------------------------------------------------------------------------------

add(string _name)
{
    if (_name == "")
    {
        integer count = llGetInventoryNumber(INVENTORY_ANIMATION);
        integer i;
        for (i = 0; i<count; ++i)
        {
            string name = llGetInventoryName(INVENTORY_ANIMATION, i);
            _add(name);
        }
    }
    else
    {
        _add(_name);
    }
}

//------------------------------------------------------------------------------

say(string _text)
{
    llWhisper(0,_text);
}

////////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llSitTarget(TARGET_POS, TARGET_ROT);
        llSetText(START_TEXT,<1.0,0.0,0.0>,1.0);
        llListen(0,"",NULL_KEY,""); // just a temp tool, so ok
    }

    listen(integer _channel, string _name, key _id, string _text)
    {
        if (llSubStringIndex(_text,"tell")==0)
        {
            string name = llStringTrim(llGetSubString(_text,4,-1),STRING_TRIM);
            if (name == "tell") name = "";
            tell(name);
        }

        else if (_text == "t") tell("");

        else if (llSubStringIndex(_text, "save") == 0)
        {
            string name = llStringTrim(llGetSubString(_text,4,-1),STRING_TRIM);
            if (name == "save") name = "";
            save(name);
        }

        else if (_text == "s") save("");

        else if (llSubStringIndex(_text, "go") == 0)
        {
            string name = llStringTrim(llGetSubString(_text,2,-1),STRING_TRIM);
            if (name == "go") name = "";
            go(name);
        }

        else if (llSubStringIndex(_text, "play") == 0)
        {
            string name = llStringTrim(llGetSubString(_text,4,-1),STRING_TRIM);
            if (name == "play") name = "";
            play(name);
        }

        else if (_text == "next" || _text == "n") play("next");
        else if (_text == "prev" || _text == "p") play("prev");

        else if (llSubStringIndex(_text,"add")==0)
        {
            string name = llStringTrim(llGetSubString(_text,3,-1),STRING_TRIM);
            if (name == "add") name = "";
            add(name);
        }

        else if (_text == "help")
        {
            say(HELP_TEXT);
        }

        else if (_text == "stand")
        {
            if (gAvatar!=NULL_KEY) llUnSit(gAvatar);
        }

    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.1);
            key avatar = llAvatarOnSitTarget();
            if (avatar != NULL_KEY)
            {
                gAvatar = avatar;
                llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
                llStopAnimation("sit");
                llSetText("",ZERO_VECTOR,1.0);
                if (gHomePos == ZERO_VECTOR) updateHome();
                string first = llList2String(gAdjNames,0);
                say(HAVE_HELP);
                if (first != "") _play(first);
            }
            else
            {
                llSetText(START_TEXT,<1.0,0.0,0.0>,1.0);
                gAvatar = NULL_KEY;
            }
        }
    }

}

////////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2008, Mo Hax
// All rights reserved.
//
// Simplified BSD License granted to all:
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
//     * Redistributions of source code must retain the above copyright notice,
//         this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//         notice, this list of conditions and the following disclaimer in the
//         documentation and/or other materials provided with the distribution.
//     * Neither the name of Mo Hax nor the names of its contributors may be
//         used to endorse or promote products derived from this software
//         without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
////////////////////////////////////////////////////////////////////////////////