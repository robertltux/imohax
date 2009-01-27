// $Id: Pose.lsl 17 2009-01-01 17:47:00Z imohax $
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
//The simpliest of pose scripts supporting one pose animation
//No poseball to hide/show. No sit and hover text. No adjustments
//to quirky animation position. No configuration file. [Try other
//MoPose scripts for those.]

//HOWTO USE: Put this script into your object and change the sit
//target setting below to match your chosen animation. Use
//SitTargetReporter or another tool help get this. Set animation
//to name of your animation or just put it into your objects inventory
//where this script is. If you do not put an animation into inventory
//a standard animation will be assumed and gAnimation will have to be set
//below. For a list of standard animations go to
//http://lslwiki.net/lslwiki/wakka.php?wakka=animation although
//these are not reliable in OpenSim currently.

string   gAnimation = "sit";

////////////////////////////////////////////////////////////////////////////////

key gAvatar;

default
{
    state_entry()
    {
        state waiting_for_avatar;
    }
}

//------------------------------------------------------------------------------

state waiting_for_avatar
{
    state_entry()
    {
        // SL and OpenSim can forget prim properties, so we always set,
        // use SitTargetReporter to help get this line, never set
        // position (first arg) to all zeros since that clears it

        llSitTarget(<0.0,0.0,0.01>,<0.0,0.0,0.0,1.0>);
    }

   changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            gAvatar = llAvatarOnSitTarget();
            if (gAvatar != NULL_KEY) state animating;
        }
    }
}

//------------------------------------------------------------------------------

state animating
{
    state_entry()
    {
        llRequestPermissions(gAvatar, PERMISSION_TRIGGER_ANIMATION);
    }

    run_time_permissions(integer _perms)
    {
        if (_perms & (PERMISSION_TRIGGER_ANIMATION))
        {
            llStopAnimation("sit");
            llStartAnimation(gAnimation);
        }
    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            if (llAvatarOnSitTarget() == NULL_KEY)
                state stopping_animation;
        }
    }
}

//------------------------------------------------------------------------------

state stopping_animation
{
    state_entry()
    {
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
            llStopAnimation(gAnimation);
        state waiting_for_avatar;
    }
}