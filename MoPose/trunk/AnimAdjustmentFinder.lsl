// $Id$
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

// HOWTO: Put this script into a prim, activate, sit, move prim around, save:
// 1) Create a prim (sphere works), don't link it yet to your final creation
// 2) Put this script into the contents of your new prim
// 3) Wait for Ready, then sit on the prim with this script in it
// 4) Find your animations to get adjustments for in inventory
// 5) Start your first animation/pose by double-clicking it from inventory
// 6) Move the prim you are sitting on so your animated/posing avatar is good
// 7) Say 'set home' to save home position and rotation and clear prev adjusts
//        ('go home' always returns prim back home (with you sitting on it))
//        ('show home' displays values)
// 8) Say 'save <myanim>' replacing <myanim> with your playing anim name
//        (you can 'save' again to update it anytime until next 'save <myanim>')
//        ('go <myanim>' moves you to that saved position and rotation)
// 9) Say 'show' or 'show <myanim>' or 'show last' to confirm save
//        ('show <myanim>' diplays values, 'show' displays all saved)
// 10) Stop the saved animation you started from inventory
// 11) Start the next animation to adjust from inventory
//        (you may need to stand up and reset to clear animation artifacts)
//        (if you have loaded the animations/poses into your adjust prim
//            inventory you can also just say 'play <animname>', this works
//            for standard anims also)
// 12) Move the prim like before to make your avatar look correctly placed
// 13) Repeat steps 8-12 for all animations/poses
// 14) Say 'show' to copy and paste the chat text into an 'animations' notecard
// 15) If more than 10 animations cleanup the extra chat from notecard
//
// At this point you can either
//     1) link the adjust prim into your object as the sit prim
//     2) use some prim from your object as the sit prim
//
// If you choose (1):
//     1) Say 'go home' to position the adjust prim at home
//     2) Stand up ('stand' command helps)
//     3) Link in your adjust prim, it can be root or child, no matter
//     4) Remove or deactivate this script in the new sit prim (former adjust)
//     5) For animations that require it, place copies in new sit prim contents
//     6) Copy your 'animations' notecard into the new sit prim (not root)
//     7) Copy in pose script with 'animations' notecard (MultiPose, etc)
//     8) Cut and paste the sit target from this script into pose script
//
// If you choose (2):
//     Do everything for (1), but place everything into your sit prim.
//     Take care to set sit target specific to your sit prim. It will NOT
//     be the same as that from this script. Use SitTargetReporter to help.
//     The 'home' position will be at your sit prim's sit target.
 
// completely ignored in calculations, set whatever is easiest to sit and move,
// pick a good one if linking in this prim as final sit prim
vector   gLocalSitTargetPos = <0.0,0.0,0.01>;
rotation gLocalSitTargetRot = ZERO_ROTATION;

// name of persistent (cache) notecard, will preload on reset or 'set home'
string gCardName = "animations"; // adjustments, offsets, whatever

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

string gStartingText = "Animation Adjustment Tool\n(have a seat)";

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

    gAdjPos = (gAvatarPos-gHomePos)/gHomeRot;
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
        show("home");
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

show(string _name)
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

    integer i;
    integer max = llGetListLength(gAdjNames);

    // just clear all saved adjustments since recalculating all from new home
    // would require calculations involving buggy sit target
    gAdjNames    = [];
    gAdjPoss     = [];
    gAdjRots     = [];
    gAdjPrimPoss = [];
    gAdjPrimRots = [];
}

//------------------------------------------------------------------------------

moveTo(string _name, vector _pos, rotation _rot)
{
    say(_name + ":\n" +(string) _pos + "," + (string) _rot);

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

play(string _name)
{
    if (_name == "") return;
    if (gPlaying != "") llStopAnimation(gPlaying);
    llStartAnimation(_name);
    gPlaying = _name;
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
        llSitTarget(gLocalSitTargetPos, gLocalSitTargetRot);
        llSetText(gStartingText,<1.0,0.0,0.0>,1.0);
        llListen(0,"",NULL_KEY,""); // just a temp tool, so ok
    }

    listen(integer _channel, string _name, key _id, string _text)
    {
        if (llSubStringIndex(_text,"show")==0)
        {
            string name = llStringTrim(llGetSubString(_text,4,-1),STRING_TRIM);
            if (name == "show") name = "";
            show(name);
        }

        else if (llSubStringIndex(_text, "save") == 0)
        {
            string name = llStringTrim(llGetSubString(_text,4,-1),STRING_TRIM);
            if (name == "save") name = "";
            save(name);
        }

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
            }
            else
            {
                llSetText(gStartingText,<1.0,0.0,0.0>,1.0);
                gAvatar = NULL_KEY;
            }
        }
    }

}