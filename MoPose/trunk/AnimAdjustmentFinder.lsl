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

// should leave this 0 and say 'set region channel <channel>' command
integer gChannel = 0;
integer gChannelHandle = 0;

// always local to the containing prim, rarely (if ever) changed
vector   gLocalSitTargetPos = <0.0,0.0,0.01>;
rotation gLocalSitTargetRot = ZERO_ROTATION;

// sit target of final sit prim, if containing prim is final prim, will be same
vector   gSitTargetPos = gLocalSitTargetPos;
rotation gSitTargetRot = gLocalSitTargetRot;

// containing prim regional position and rotation, all offsets from this,
// stores each time 'set home' is called
vector   gHomePos = ZERO_VECTOR;
rotation gHomeRot = ZERO_ROTATION;

// poor man's hash table of adjustment data
list gNames;
list gPositions;
list gRotations;

integer gWaitingForSitTarget = FALSE;
string  gNameLastUsed = "myoffset";
string  gStartingText = "SitTarget and Offset Tool\n(have a seat)";

key     gCurrentQuery;
integer gCurrentQueryLine;

////////////////////////////////////////////////////////////////////////////////

vector avatarPos()
{
    vector prim_p = llGetPos();
    rotation prim_r = llGetRot();
    // corrects SL error between actual avatar pos and llGetPos while seated
    return prim_p + (gLocalSitTargetPos * prim_r)
        - <0,0,0.186> + <0,0,0.4> * prim_r;
}

rotation avatarRot()
{
    return llGetRot() / gLocalSitTargetRot;
}

vector posAdjustment()
{
    return llGetPos() - gHomePos;
}

rotation rotAdjustment()
{
    return llGetRot() - gHomeRot;
}

////////////////////////////////////////////////////////////////////////////////

showHelp()
{
    llOwnerSay("Help text here.");
}

showHome()
{
    say("HOME:\n" + (string) gHomePos + "," + (string) gHomeRot);
}

showSitTarget()
{
    say("SITTARGET:\n" + (string) gSitTargetPos +
        "," + (string) gSitTargetRot);
}

setSitTarget(string _message)
{
    integer start = llSubStringIndex(_message, "is\n") + 3;
    string parseme = llStringTrim(llGetSubString(_message,start,-1),STRING_TRIM);
    list p = llCSV2List(parseme);
    string vecStr = llList2String(p,0);
    string rotStr = llList2String(p,1);
    if ((vector) vecStr != ZERO_VECTOR)
    {
        gSitTargetPos = (vector) vecStr;
        gSitTargetRot = (rotation) rotStr;
        showSitTarget();
    }
    else
    {
        say("Sorry, try another besides zero change");

    }
    gWaitingForSitTarget = FALSE;
}

setOffset(string _name)
{
    if (_name == "") _name = gNameLastUsed;
    else gNameLastUsed = _name;

    integer i = llListFindList(gNames,[_name]);

    vector v = posAdjustment();
    rotation r = rotAdjustment();
    string line = _name + ", " + (string) v + ", " + (string) r;

    if (i >= 0 )
    {
        gNames = llListReplaceList(gNames,[_name],i,i);
        gPositions = llListReplaceList(gPositions,[v],i,i);
        gRotations = llListReplaceList(gRotations,[r],i,i);
        say("UPDATED:\n" + line);
    }
    else
    {
        gNames += [_name];
        gPositions += [v];
        gRotations += [r];
        say("SAVED:\n" + line);
    }
}

showOffset(string _name)
{
    if (_name == "")
        say("OFFSET:\n" + (string) posAdjustment() +
        "," + (string) rotAdjustment());
    else
    {
        integer i = llListFindList(gNames,[_name]);
        if (i<0)
            say("Offset '" + _name + "' not found. Try 'set " + _name +"' first.");
        else
            say("SHOW:\n" + _name + ","
                + llList2String(gPositions,i) + ","
            + llList2String(gRotations,i) );
    }
}

showAll()
{
    string buffer;
    integer i;
    integer start = 1;
    integer max = llGetListLength(gNames);

    for (i=0; i<max; i++)
    {
        if (i==0)
            buffer = "SITTARGET," + (string) gSitTargetPos + "," + (string) gSitTargetRot;

        buffer += "\n" + llList2String(gNames,i)
            + ", " + llList2String(gPositions,i)
            + ", " + llList2String(gRotations,i);

        if ( (i+1) % 10 == 0)
        {
            say("OFFSETS " + (string) (i-10) + "-" + (string) (i+1) + ":\n" + buffer + "\n");
            start = i+2;
            buffer = "";
        }
    }

    if (buffer != "")
        say("OFFSETS " + (string) start + "-" + (string) (i) + ":\n" + buffer + "\n");
}

setHome()
{

    // sittarget or not, we set home to regional settings so offset cmds will work
    gHomePos = llGetPos();
    gHomeRot = llGetRot();

    say("What is the sittarget for " + (string) avatarPos()
        + "," + (string) avatarRot() + "?");
    gWaitingForSitTarget = TRUE;

    // and we always clear any offsets so new will be from current new home
    gNames = [];
    gPositions = [];
    gRotations = [];

    // and end with loading persistent offsets from notecard
    if (llGetInventoryType("offsets")==INVENTORY_NOTECARD)
        gCurrentQuery = llGetNotecardLine("offsets",gCurrentQueryLine);
}

moveTo(string _name, vector _p, rotation _r)
{
    say("Moving to " + _name + ":\n" +(string) _p + "," + (string) _r);

    integer max = 100;
    integer i = 0;
    llSetPos(_p);
    llSetRot(_r);
    while (llGetPos() != _p) {
        llSetPos(_p);
        llSetRot(_r);
        if (i == max)
        {
            say("Failed to reach home. Something blocking. Giving up.");
            jump OutAgain;
        }
        ++i;
    }
    @OutAgain;
}

goHome()
{
    moveTo("HOME", gHomePos, gHomeRot);
}

goOffset(string _name)
{
    if (_name == "") _name = gNameLastUsed;

    integer i = llListFindList(gNames,[_name]);
    if (i<0)
    {
        say("Offset name (" + _name
            + ") not found. Try 'set " + _name +"' first.");
    }

    moveTo(_name, gHomePos + llList2Vector(gPositions,i),
        gHomeRot + llList2Rot(gRotations,i));

}

say(string _text)
{
    llWhisper(0,_text);
    if (gChannelHandle > 0) llRegionSay(gChannel,_text);
    llMessageLinked(LINK_SET,71992513,_text,NULL_KEY);
}

///////////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llSitTarget(gLocalSitTargetPos, gLocalSitTargetRot);
        llSetText(gStartingText,<1.0,0.0,0.0>,1.0);
        llListen(0,"",NULL_KEY,"");
        if (gChannel>0) gChannelHandle = llListen(gChannel,"",NULL_KEY,"");
        setHome();
    }

    listen(integer channel, string name, key id, string message)
    {
        if (   message == "sethome" || message == "set home"
            || message == "set sittarget"
            || message == "set sit target"
            || message == "save sittarget"
            || message == "save sit target") setHome();
        else if (gWaitingForSitTarget &&
            llSubStringIndex(message,"The sittarget for " + (string) avatarPos()
                + "," + (string) avatarRot())==0)
            setSitTarget(message);
        else if (llSubStringIndex(message,"set region channel ")==0)
        {
            integer chan = (integer) llStringTrim(llGetSubString(message, 19, -1)
                ,STRING_TRIM);
            if (chan > 0)
            {
                if (gChannelHandle > 0)
                {
                    say("Closing communication with entire region on channel "
                        + (string) gChannel);
                    llListenRemove(gChannelHandle);
                }
                gChannel = chan;
                gChannelHandle = llListen(gChannel, "", NULL_KEY, "");
                say("Now communicating with entire region on channel "
                    + (string) gChannel);
            }
            else
            {
                llListenRemove(gChannelHandle);
                gChannelHandle = 0;
                say("Communication with entire region now closed");
            }
        }
        else if (message == "gohome" || message == "go home"
            || message == "go sittarget" || message == "go sit target") goHome();
        else if (message == "home" || message == "show home") showHome();
        else if (message == "offset" || message == "show offset") showOffset("");
        else if (message == "show" || message == "show all") showAll();
        else if (message == "sittarget" || message == "show sittarget"
            || message == "show sit target") showSitTarget();
        else if (message == "help") showHelp();


        else if (llSubStringIndex(message,"show offset ")==0)
            showOffset(llGetSubString(message,12,-1));
        else if (llSubStringIndex(message,"show ")==0)
            showOffset(llGetSubString(message,5,-1));


        else if (llSubStringIndex(message, "save offset ")==0)
            setOffset(llGetSubString(message,12,-1));
        else if (llSubStringIndex(message, "set offset ")==0)
            setOffset(llGetSubString(message, 11, -1));
        else if (llSubStringIndex(message, "set ") == 0)
            setOffset(llGetSubString(message, 4,-1));
        else if (llSubStringIndex(message, "save ") == 0)
            setOffset(llGetSubString(message, 5, -1));
        else if (message == "save" || message == "set")
            setOffset(gNameLastUsed);

        else if (llSubStringIndex(message, "go ") == 0)
            goOffset(llGetSubString(message,3,-1));
        else if (message == "go last" || message == "golast")
            goOffset(gNameLastUsed);

        else if (message == "last") showOffset(gNameLastUsed);
    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.5);
            key sitter = llAvatarOnSitTarget();
            if (sitter != NULL_KEY)
            {
                llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
                llStopAnimation("sit");
                if (gHomePos == ZERO_VECTOR) say("No home (sittarget) position set. Awaiting 'set home' (or 'set sittarget').");
                llSetText("",ZERO_VECTOR,1.0);
                showHelp();
            }
            else
            {
                llSetText(gStartingText,<1.0,0.0,0.0>,1.0);
            }
        }
    }

    dataserver(key _query, string _data)
    {
        if (_data != EOF)
        {
            list d = llCSV2List(_data);
            string name = llList2String(d,0);
            vector v = (vector) llStringTrim(llList2String(d,1),STRING_TRIM);
            rotation r = (rotation) llStringTrim(llList2String(d,2),STRING_TRIM);

            if (name=="SITTARGET")
            {
                gSitTargetPos = v;
                gSitTargetRot = r;
            }
            else
            {
                gNames += name;
                gPositions += v;
                gRotations += r;
            }
            gCurrentQueryLine++;
            gCurrentQuery = llGetNotecardLine("offsets", gCurrentQueryLine);

        }
        else
        {
            gCurrentQuery = NULL_KEY;
            gCurrentQueryLine = 0;
        }
    }

    link_message(integer _num, integer _proto, string _str, key _key)
    {
        llOwnerSay(_str);
        if (_proto == 71992513)
        {
            if (gWaitingForSitTarget &&
                llSubStringIndex(_str,"The sittarget for " + (string) avatarPos()
                    + "," + (string) avatarRot())==0)
                setSitTarget(_str);
        }
    }

}