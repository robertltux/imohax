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
//
//Tool to help adjust position of sitting avatar to desired sit target.
//Clicking object sets the sit target of that prim and displays for
//use in persistent pose script or configuration.
//
//HOWTO USE: Drop this script into the prim for which you wish to set
//the sit target. Make sure it is the actual prim if you are working
//on a set of linked prims in a single object. Otherwise the script
//will only be working with the sittarget of the root prim, unless
//that is what you want. Then use the arrow keys to adjust position:
//
//left arrow (rotate left) - rotates left
//right arrow (rotate right) - rotates right
//...

integer whisper = TRUE;
integer say_every = FALSE;

say(string text)
{
    if (whisper == TRUE) llWhisper(0,text);
    else llOwnerSay(text);
}

default
{
    state_entry()
    {

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
