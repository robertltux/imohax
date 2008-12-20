// $Id: MoSitTargetReporter.lsl 11 2008-12-15 15:01:20Z imohax $
//
// MAKE SURE TO REMOVE THIS SCRIPT FROM ANY CONTAINING OBJECT BEFORE GIVING OBJECT!
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

integer region_channel = 8;
integer region_channel_handle;

say(string text)
{
    llWhisper(0,text);
    if (region_channel_handle > 0) llRegionSay(region_channel,text);
    llMessageLinked(LINK_SET,71992513,text,NULL_KEY);
}

answer(string text)
{
    list cur = llCSV2List(llGetSubString(text,26,-2));
    vector pos = (vector) llStringTrim(llList2String(cur,0),STRING_TRIM);
    rotation rot = (rotation) llStringTrim(llList2String(cur,1),STRING_TRIM);
    vector sit_target_pos = (pos - llGetPos()) / llGetRot();
    sit_target_pos = sit_target_pos + <0.0,0.0,0.186>/llGetRot() - <0.0,0.0,0.4>;
    rotation sit_target_rot = rot / llGetRot();
    say("The sittarget for " + (string) pos + "," + (string) rot
        + " is\n" + (string) sit_target_pos + "," + (string) sit_target_rot);
}

default
{
    state_entry()
    {
        llListen(0,"",NULL_KEY,"");
        if (region_channel>0)
        {
            region_channel_handle = llListen(region_channel,"",NULL_KEY,"");
            say("Communicating with region on channel " + (string) region_channel);
        }
        say("Ready. Ask me 'What is the sittarget for <pos>,<rot>?'");
        string text = "SitTarget Reporter:\n";
        if (region_channel_handle>0) text += "Listening on 0 and " + (string) region_channel + "\n";
        else text += "Listening on 0\n";
        text += "Ask me 'What is the sittarget for <pos>,<rot>?'";
        llSetText(text,<1.0,0.0,0.0>,1.0);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (llSubStringIndex(message,"What is the sittarget for ")==0)
            answer(message);
    }

    link_message(integer num, integer proto, string str, key akey)
    {
        if (proto == 71992513)
        {
            if (llSubStringIndex(str,"What is the sittarget for ")==0)
                answer(str);
        }
    }
}
