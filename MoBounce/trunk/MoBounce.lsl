////////////////////////////////////////////////////////////////////////////
//
// $Id$
// [Copyright and BSD (free) license included at bottom.]
//
// Go to http://imohax.com for help, FAQ, video HOWTOs, and comments
//       ^^^^^^^^^^^^^^^^^
//
////////////////////////////////////////////////////////////////////////////

// replace these with any site you like to promote by clicking on ball

string CLICK_URL = "http://imohax.com";
string CLICK_TEXT = "Visit Mo's Site";

// These must match the exact name of your animations in objects inventory

string bounce_super = "MoBounce_Jump_Super by Mo Hax";
string bounce       = "MoBounce_Jump by Mo Hax";
string bounce_walk  = "MoBounce_Jump_Walk by Mo Hax";
string still        = "MoBounce_Still by Mo Hax";
string left         = "MoBounce_Left by Mo Hax";
string right        = "MoBounce_Right by Mo Hax";


string power_default = "<10.0,0.0,20.0>";

////////////////////////////////////////////////////////////////////////////

string power;
vector power_vector;
key owner;
string last;
string current;
float poll_interval = 0.1;

////////////////////////////////////////////////////////////////////////////

stopAll()
{
    llStopAnimation(left);
    llStopAnimation(right);
    llStopAnimation(bounce);
    llStopAnimation(bounce_walk);
    llStopAnimation(bounce_super);
    llStopAnimation(still);
}

//------------------------------------------------------------------------------

set_power()
{
    power = llToLower(llGetObjectDesc());
    integer start = llSubStringIndex(power,"power=");
    power = llGetSubString(power, start+6, -1);
    integer end = llSubStringIndex(power,">");
    power = llStringTrim(llGetSubString(power,0,end),STRING_TRIM);
    if (start >= 0 && end >= 0)
    {
        llOwnerSay("Super bounce power set to " + (string) power);
        power_vector = (vector) power;
    }
    else
    {
        power = power_default;
        power_vector = (vector) power;
        llOwnerSay("Super bounce power set to default " + power);
    }
}

//------------------------------------------------------------------------------

default
{
    state_entry()
    {
        owner = llGetOwner();
        set_power();
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    attach(key attached)
    {
        if (attached == NULL_KEY)
        {
            owner = NULL_KEY;
            stopAll();
        }
        else
        {
            owner = llGetOwner();
            llRequestPermissions(owner, (PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS));
            llSetTimerEvent(poll_interval);
            llOwnerSay("Normal movement. Control-r to run always. PageUp to super bounce.");
            llOwnerSay("Don't forget to turn off your AO.");
            set_power();
            llStartAnimation(still);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    touch(integer detected)
    {
        if (llDetectedKey(0) == owner) set_power();
        llOwnerSay((string) llKey2Name(llDetectedKey(0)) + " touched your ball.");
        llLoadURL(llDetectedKey(0),CLICK_TEXT, CLICK_URL);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TAKE_CONTROLS)
        {
            llTakeControls(CONTROL_UP, TRUE, FALSE);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    control(key id, integer held, integer change)
    {
        if (held & change & CONTROL_UP)
        {
            llSetTimerEvent(0);
            llStopAnimation(still);
            llStopAnimation(left);
            llStopAnimation(right);
            llStopAnimation(bounce);
            llStopAnimation(bounce_walk);
            llStartAnimation(bounce_super);
            llPlaySound("MoBounceTakeOff",1.0);
            llPushObject(owner, power_vector*llGetObjectMass(owner),
                <0.0,0.0,0.0>, TRUE);
            llSleep(2.0);
            llSetTimerEvent(poll_interval);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    timer()
    {
        current = llGetAnimation(owner);

        if (current == last) return;

        //llOwnerSay("New State: " + current);
        if (current == "Walking")
        {
            llStopAnimation(still);
            llStopAnimation(left);
            llStopAnimation(right);
            llStopAnimation(bounce);
            llStopAnimation(bounce_super);
            llStartAnimation(bounce_walk);
        }
        else if (current == "Running")
        {
            llStopAnimation(bounce_walk);
            llStopAnimation(left);
            llStopAnimation(right);
            llStopAnimation(still);
            llStopAnimation(bounce_super);
            llStartAnimation(bounce);
        }
        else if (current == "Standing")
        {
            llStopAnimation(bounce_walk);
            llStopAnimation(bounce);
            llStopAnimation(left);
            llStopAnimation(right);
            llStopAnimation(bounce_super);
            llStartAnimation(still);
        }
        else if (current == "Turning Left")
        {
            llStopAnimation(bounce_walk);
            llStopAnimation(bounce_super);
            llStopAnimation(bounce);
            llStopAnimation(still);
            llStopAnimation(right);
            llStartAnimation(left);
        }
        else if (current == "Turning Right")
        {
            llStopAnimation(bounce_super);
            llStopAnimation(bounce_walk);
            llStopAnimation(bounce);
            llStopAnimation(still);
            llStopAnimation(left);
            llStartAnimation(right);
        }
        last = current;
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