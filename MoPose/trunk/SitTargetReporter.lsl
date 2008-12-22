// $Id$
//
// MAKE SURE TO REMOVE THIS SCRIPT BEFORE DISTRIBUTING YOUR OBJECT
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

// HOWTO:
// 1) Drop this script in specific prim to be sat upon. Wait for Ready.
// 2) Create any prim and sit on it.
// 3) Play your desired animation/pose from inventory directly.
// 4) Move prim you are sitting on so that your animated avatar appears where
//    you like ultimately on the sit target prim. Say, 'sittarget?'
// 5) Copy the llSitTarget() code from chat and replace or add to pose script.
// 6) Save your pose script. Test sit on your sittable prim with new target.

// This can also be used with RegionRelay to find sit targets within 300
// meters away for building objects that us the teleport hack
// if >0 says everything answered and spoken to the region channel as well
integer gChannel = 0;
integer gChannelHandle;

say(string _text)
{
    llWhisper(0,_text);
    if (gChannelHandle > 0) llRegionSay(gChannel,_text);
    llMessageLinked(LINK_SET,71992513,_text,NULL_KEY);
}

saySitTargetFor(list _loc)
{
    vector   pos = llList2Vector(_loc,0);
    rotation rot = llList2Rot(_loc,1);
    
    vector   sitTargetPos = (pos-llGetPos())/llGetRot();
    rotation sitTargetRot = (rot/llGetRot())/llGetRot();
    
    // correct SL sit target bug, once for this prim
    sitTargetPos = sitTargetPos + <0.0,0.0,0.186>/llGetRot() - <0.0,0.0,0.365>;
    
    // and again assuming asker is sitting on something
    sitTargetPos = sitTargetPos + <0.0,0.0,0.186>/llGetRot() - <0.0,0.0,0.365>;
    
    say("\nllSitTarget(" + (string) sitTargetPos + ", " 
      + (string) sitTargetRot + ");");
}

////////////////////////////////////////////////////////////////////////////////

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
        
        say("Ready.");
        say("Ask me 'What is my sit target?' and I'll tell you.");
        say("Or ask me 'What is the sit target for <pos>,<rot>?'");
        
        string text = "SitTarget Reporter:\n";
        if (gChannelHandle>0)
        {
            text += "Listening on 0 and " + (string) gChannel + "\n";
        }
        
        else
        {
            text += "Listening on 0\n";
        }
        
        text += "Ask me 'What is my sit target?'";
        
        llSetText(text,<1.0,0.0,0.0>,1.0);
    }

    //--------------------------------------------------------------------------

    listen(integer _channel, string _name, key _id, string _message)
    {
        if (_message == "What is my sit target?" || _message == "sit target?"
            || _message == "sittarget?" || _message == "target?")
        {
            saySitTargetFor(
                llGetObjectDetails(_id,[OBJECT_POS,OBJECT_ROT]) );
        }
        
        else if (llSubStringIndex(_message,"What is the sit target for ")==0)
        {
            list cur = llCSV2List(llGetSubString(_message,26,-2));
            vector pos =
                (vector) llStringTrim(llList2String(cur,0),STRING_TRIM);
            rotation rot = 
                (rotation) llStringTrim(llList2String(cur,1),STRING_TRIM);

            saySitTargetFor([pos,rot]);

        }
    }

}
