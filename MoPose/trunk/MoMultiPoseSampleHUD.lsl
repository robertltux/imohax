// $Id: CmdMultiPose.lsl 20 2009-01-05 22:56:21Z imohax $
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

// set this to the private channel of the item
integer gChannel = 1;

// set this to the base animation for after 'stop all animations'
string gBaseAnimation = "#1";

// set to seconds to wait for list request to answer before timing out
float gTimeOut = 10.0;

// only change if have changed in item (say, for different language)
string LIST_CMD = "tell";

// could change for different language, etc.
string TIMEOUT_TEXT = "Request for animations list timed out.";
string HOLDON_TEXT  = "Still waiting on last animations list request.";

//------------------------------------------------------------------------------

integer gListener;
list gAnimations;
integer gNumOfAnims;

////////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llOwnerSay("Ready.");
        state awaiting_action;
    }
}

//------------------------------------------------------------------------------

state awaiting_action
{
    state_entry()
    {
        gListener = 0;
    }

    touch_start(integer _total_number)
    {
        integer link = llDetectedLinkNumber(0);
        integer animIndex = link - 3;
        if (link > 2 && animIndex < gNumOfAnims)
        {
            llWhisper(gChannel,llList2String(gAnimations,animIndex));
            return;
        }
        if (link == 1) state requesting_animations_list;
        if (link == 2) state stopping_all_animations;
    }
}

//------------------------------------------------------------------------------

state stopping_all_animations
{
    state_entry()
    {
        llWhisper(gChannel,gBaseAnimation);
        key owner = llGetOwner();
        if (llGetPermissionsKey() != owner)
            llRequestPermissions(owner,PERMISSION_TRIGGER_ANIMATION);
        list anims = llGetAnimationList(owner);
        integer len = llGetListLength(anims);
        integer i;
        for (i=0; i<len; ++i) llStopAnimation(llList2Key(anims,i));
        state awaiting_action;
    }
}

//------------------------------------------------------------------------------

state requesting_animations_list
{
    state_entry()
    {
        gAnimations = [];
        gNumOfAnims = 0;
        gListener = llListen(gChannel,"",NULL_KEY,"");
        llWhisper(gChannel,LIST_CMD);
        llSetTimerEvent(gTimeOut);
    }

    timer()
    {
        llSetTimerEvent(0);
        llOwnerSay(TIMEOUT_TEXT);
        state awaiting_action;
    }

    listen(integer _channel, string _name, key _id, string _message)
    {
        list parsed = llCSV2List(_message);
        if (llList2String(parsed,0) == "ANIMATIONS")
        {
            integer i;
            for (i=1; i<llGetListLength(parsed); i++)
            {
                string numName = llList2String(parsed,i);
                integer eqDex = llSubStringIndex(numName,"=");
                gAnimations += llGetSubString(numName,eqDex+1,-1);
            }
            gNumOfAnims = llGetListLength(gAnimations);
            llListenRemove(gListener);
            state updating_animations_display;
        }
    }
    
    touch_start(integer _total_number)
    {
        llOwnerSay(HOLDON_TEXT);
    }
}

//------------------------------------------------------------------------------

state updating_animations_display
{
    state_entry()
    {
        integer i;
        for (i=3; i<=102; ++i)
        {
            // 1 = LINK_SET_TEXT
            llMessageLinked(LINK_SET,1,"<0.0,0.0,0.0>","");
            llSetLinkAlpha(i,0.0,ALL_SIDES);
        }
        llSleep(0.3);
        for (i=0; i<gNumOfAnims; ++i)
        {
            string anim = llList2String(gAnimations,i);
            llMessageLinked(53+i,1,"<0,0,0>",anim);
            llSetLinkAlpha(i+3,0.5,ALL_SIDES);
        }
        state awaiting_action;
    }
}