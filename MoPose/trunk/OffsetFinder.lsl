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

// should leave this 0 and use 'set region channel CHAN'
integer region_channel = 0;
integer region_channel_handle = 0;

///////////////////////////////////////////////////////////////////////////////////

// always local to the containing prim, rarely (if ever) changed
vector   _sit_target_v = <0.0,0.0,0.01>;
rotation _sit_target_r = ZERO_ROTATION;

// sit target of final sit prim, if containing prim is final prim, will be same
vector   sit_target_v = _sit_target_v;
rotation sit_target_r = _sit_target_r;

// containing prim regional position and rotation, all offsets from this
vector   home_p = ZERO_VECTOR;
rotation home_r = ZERO_ROTATION;

list offset_names;
list offset_vectors;
list offset_rotations;

integer waiting_for_sittarget = FALSE;
string last_offset_name = "myoffset";
string start_text = "SitTarget and Offset Tool\n(have a seat)";
key qid;
integer qdex;

///////////////////////////////////////////////////////////////////////////////////

vector avatar_p()
{
    vector prim_p = llGetPos();
    rotation prim_r = llGetRot();
    // corrects SL error between actual avatar pos and llGetPos while seated
    return prim_p + (_sit_target_v * prim_r) - <0,0,0.186> + <0,0,0.4> * prim_r;

}
rotation avatar_r(){return llGetRot() / _sit_target_r;}

vector offset_v(){return llGetPos() - home_p;}
rotation offset_r(){return llGetRot() - home_r;}

///////////////////////////////////////////////////////////////////////////////////

showHelp(){llOwnerSay("Help text here.");}
showHome(){say("HOME:\n" + (string) home_p + "," + (string) home_r);}
showSitTarget(){say("SITTARGET:\n" + (string) sit_target_v + "," + (string) sit_target_r);}

setSitTarget(string message)
{
    integer start = llSubStringIndex(message, "is\n") + 3;
    string parseme = llStringTrim(llGetSubString(message,start,-1),STRING_TRIM);
    list p = llCSV2List(parseme);
    string s_vec = llList2String(p,0);
    string s_rot = llList2String(p,1);
    if ((vector) s_vec != ZERO_VECTOR)
    {
        sit_target_v = (vector) s_vec;
        sit_target_r = (rotation) s_rot;
        showSitTarget();
    }
    else
    {
        say("Sorry, try another position besides this one, which will zero out the sittarget");

    }
    waiting_for_sittarget = FALSE;
}

setOffset(string name)
{
    if (name == "") name = last_offset_name;
    else last_offset_name = name;

    integer i = llListFindList(offset_names,[name]);

    vector v = offset_v();
    rotation r = offset_r();
    string line = name + ", " + (string) v + ", " + (string) r;

    if (i >= 0 )
    {
        offset_names = llListReplaceList(offset_names,[name],i,i);
        offset_vectors = llListReplaceList(offset_vectors,[v],i,i);
        offset_rotations = llListReplaceList(offset_rotations,[r],i,i);
        say("UPDATED:\n" + line);
    }
    else
    {
        offset_names += [name];
        offset_vectors += [v];
        offset_rotations += [r];
        say("SAVED:\n" + line);
    }
}

showOffset(string name)
{
    if (name == "")
        say("OFFSET:\n" + (string) offset_v() + "," + (string) offset_r());
    else
    {
        integer i = llListFindList(offset_names,[name]);
        if (i<0)
            say("Offset '" + name + "' not found. Try 'set " + name +"' first.");
        else
            say("SHOW:\n" + name + ","
                + llList2String(offset_vectors,i) + ","
            + llList2String(offset_rotations,i) );
    }
}

showAll()
{
    string buffer;
    integer i;
    integer start = 1;
    integer max = llGetListLength(offset_names);

    for (i=0; i<max; i++)
    {
        if (i==0)
            buffer = "SITTARGET," + (string) sit_target_v + "," + (string) sit_target_r;

        buffer += "\n" + llList2String(offset_names,i)
            + ", " + llList2String(offset_vectors,i)
            + ", " + llList2String(offset_rotations,i);

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
    home_p = llGetPos();
    home_r = llGetRot();

    say("What is the sittarget for " + (string) avatar_p()
        + "," + (string) avatar_r() + "?");
    waiting_for_sittarget = TRUE;

    // and we always clear any offsets so new will be from current new home
    offset_names = [];
    offset_vectors = [];
    offset_rotations = [];

    // and end with loading persistent offsets from notecard
    if (llGetInventoryType("offsets")==INVENTORY_NOTECARD)
        qid = llGetNotecardLine("offsets",qdex);
}

moveTo(string name, vector p, rotation r)
{
    say("Moving to " + name + ":\n" +(string) p + "," + (string) r);

    integer max = 100;
    integer i = 0;
    llSetPos(p);
    llSetRot(r);
    while (llGetPos() != p) {
        llSetPos(p);
        llSetRot(r);
        if (i == max)
        {
            say("Failed to reach home. Something blocking. Giving up.");
            jump OutAgain;
        }
        ++i;
    }
    @OutAgain;
}

goHome(){ moveTo("HOME", home_p, home_r); }

goOffset(string name)
{
    if (name == "") name = last_offset_name;

    integer i = llListFindList(offset_names,[name]);
    if (i<0)
    {
        say("Offset name (" + name
            + ") not found. Try 'set " + name +"' first.");
    }

    moveTo(name, home_p + llList2Vector(offset_vectors,i),
        home_r + llList2Rot(offset_rotations,i));

}

///////////////////////////////////////////////////////////////////////////////////

say(string text)
{
    llWhisper(0,text);
    if (region_channel_handle > 0) llRegionSay(region_channel,text);
    llMessageLinked(LINK_SET,71992513,text,NULL_KEY);
}

///////////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llSitTarget(_sit_target_v, _sit_target_r);
        llSetText(start_text,<1.0,0.0,0.0>,1.0);
        llListen(0,"",NULL_KEY,"");
        if (region_channel>0) region_channel_handle = llListen(region_channel,"",NULL_KEY,"");
        setHome();
    }

    listen(integer channel, string name, key id, string message)
    {
        if (   message == "sethome" || message == "set home"
            || message == "set sittarget"
            || message == "set sit target"
            || message == "save sittarget"
            || message == "save sit target") setHome();
        else if (waiting_for_sittarget &&
            llSubStringIndex(message,"The sittarget for " + (string) avatar_p()
                + "," + (string) avatar_r())==0)
            setSitTarget(message);
        else if (llSubStringIndex(message,"set region channel ")==0)
        {
            integer chan = (integer) llStringTrim(llGetSubString(message, 19, -1),STRING_TRIM);
            if (chan > 0)
            {
                if (region_channel_handle > 0)
                {
                    say("Closing communication with entire region on channel " + (string) region_channel);
                    llListenRemove(region_channel_handle);
                }
                region_channel = chan;
                region_channel_handle = llListen(region_channel, "", NULL_KEY, "");
                say("Now communicating with entire region on channel " + (string) region_channel);
            }
            else
            {
                llListenRemove(region_channel_handle);
                region_channel_handle = 0;
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
            setOffset(last_offset_name);

        else if (llSubStringIndex(message, "go ") == 0)
            goOffset(llGetSubString(message,3,-1));
        else if (message == "go last" || message == "golast")
            goOffset(last_offset_name);

        else if (message == "last") showOffset(last_offset_name);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            llSleep(0.5);
            key sitter = llAvatarOnSitTarget();
            if (sitter != NULL_KEY)
            {
                llRequestPermissions(sitter, PERMISSION_TRIGGER_ANIMATION);
                llStopAnimation("sit");
                if (home_p == ZERO_VECTOR) say("No home (sittarget) position set. Awaiting 'set home' (or 'set sittarget').");
                llSetText("",ZERO_VECTOR,1.0);
                showHelp();
            }
            else
            {
                llSetText(start_text,<1.0,0.0,0.0>,1.0);
            }
        }
    }

    dataserver(key this_id, string data)
    {
        if (data != EOF)
        {
            list d = llCSV2List(data);
            string name = llList2String(d,0);
            vector v = (vector) llStringTrim(llList2String(d,1),STRING_TRIM);
            rotation r = (rotation) llStringTrim(llList2String(d,2),STRING_TRIM);

            if (name=="SITTARGET")
            {
                sit_target_v = v;
                sit_target_r = r;
            }
            else
            {
                offset_names += name;
                offset_vectors += v;
                offset_rotations += r;
            }
            qdex++;
            qid = llGetNotecardLine("offsets", qdex);

        }
        else
        {
            qid = NULL_KEY;
            qdex = 0;
        }
    }

    link_message(integer num, integer proto, string s, key k)
    {
        llOwnerSay(s);
        if (proto == 71992513)
        {
            if (waiting_for_sittarget &&
                llSubStringIndex(s,"The sittarget for " + (string) avatar_p()
                    + "," + (string) avatar_r())==0)
                setSitTarget(s);
        }
    }

}