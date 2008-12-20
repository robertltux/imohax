// $Id$
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

// if >0 says everything to that region channel as well, useful for TP hacks
integer gChannel = 8;
integer gChannelHandle;

say(string _text)
{
    llWhisper(0,_text);
    if (gChannelHandle > 0) llRegionSay(gChannel,_text);
    llMessageLinked(LINK_SET,71992513,_text,NULL_KEY);
}

answer(string _text)
{
    // What is the sittarget for <pos>,<rot>?
    list cur = llCSV2List(llGetSubString(_text,26,-2));
    vector pos = (vector) llStringTrim(llList2String(cur,0),STRING_TRIM);
    rotation rot = (rotation) llStringTrim(llList2String(cur,1),STRING_TRIM);

    vector sitTargetPos   = (pos-llGetPos())/llGetRot();
    rotation sitTargetRot = (rot/llGetRot())/llGetRot;

    // correct for SL bug, which is why we don't like sit targets for offsets
    sitTargetPos = sitTargetPos + <0.0,0.0,0.186>/llGetRot() - <0.0,0.0,0.4>;

    say("The sittarget for " + (string) pos + "," + (string) rot
        + " is\n" + (string) sitTargetPos + "," + (string) sitTargetRot);
}

default
{
    state_entry()
    {
        llListen(0,"",NULL_KEY,"");
        if (gChannel>0)
        {
            gChannelHandle = llListen(gChannel,"",NULL_KEY,"");
            say("Communicating with region on channel " + (string) gChannel);
        }
        say("Ready. Ask me 'What is the sittarget for <pos>,<rot>?'");
        string text = "SitTarget Reporter:\n";
        if (gChannelHandle>0) text += "Listening on 0 and " + (string) gChannel + "\n";
        else text += "Listening on 0\n";
        text += "Ask me 'What is the sittarget for <pos>,<rot>?'";
        llSetText(text,<1.0,0.0,0.0>,1.0);
    }

    listen(integer _channel, string _name, key _id, string _message)
    {
        if (llSubStringIndex(_message,"What is the sittarget for ")==0)
            answer(_message);
    }

    link_message(integer _num, integer _proto, string _str, key _key)
    {
        if (_proto == 71992513)
        {
            if (llSubStringIndex(_str,"What is the sittarget for ")==0)
                answer(_str);
        }
    }
}
