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
//
//The simpliest of pose scripts supporting one pose animation
//No poseball to hide/show. No sit and hover text. No adjustments
//to quirky animation position. No configuration file. [Try other
//MoPose scripts for those.]

//HOWTO USE: Put this script into your object and change the sit
//target setting below to match your chosen animation. Use
//MoSitTargetReporter or another tool help get this. Set animation
//to name of your animation and put into your objects inventory
//where this script is. You can also just specify one of the
//standard animations that do not require an uploaded animation:
//http://lslwiki.net/lslwiki/wakka.php?wakka=animation although
//these are not reliable in OpenSim currently.

vector sit_target_vec = <0.0,0.0,0.01>; //no ZERO_VECTOR, that clears
rotation sit_target_rot = ZERO_ROTATION;
string animation = "sit";

////////////////////////////////////////////////////////////////////////////

key avatar;

default{
    state_entry()
    {
        state waiting_for_avatar;
    }
    on_rez(integer p){llResetScript();}
}

////////////////////////////////////////////////////////////////////////////

state waiting_for_avatar
{
    state_entry()
    {
        avatar = NULL_KEY;

        // SL and OpenSim can forget prim properties, so we always set
        llSitTarget(sit_target_vec,sit_target_rot);
    }

    on_rez(integer p){llResetScript();}

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            key new_avatar = llAvatarOnSitTarget();
            if (new_avatar != NULL_KEY)
            {
                avatar = new_avatar;
                state animating;

            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state animating
{
    state_entry()
    {
        llRequestPermissions(avatar, PERMISSION_TRIGGER_ANIMATION);
    }

    on_rez(integer p){llResetScript();}

    run_time_permissions(integer perms)
    {
        if (perms & (PERMISSION_TRIGGER_ANIMATION))
        {
            llStopAnimation("sit");
            llStartAnimation(animation);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key new_avatar = llAvatarOnSitTarget();
            if (llAvatarOnSitTarget()==NULL_KEY) state stopping_animation;
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state stopping_animation
{
    state_entry()
    {
        integer perms = llGetPermissions();
        if (perms & PERMISSION_TRIGGER_ANIMATION)
            llStopAnimation(animation);
        state waiting_for_avatar;
    }
    on_rez(integer p){llResetScript();}
}