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

// This script is not designed to be used in things that move, use OnePose or
// any script that does not use llDetectedObject() for positioning if moving.

// change these depending on language
string START_TEXT = "Starting up. Please wait for 'Ready' before using.";
string READY_TEXT = "Ready.";
string ERROR_TEXT = "ERROR STATE. Correct and reset script.";

// might change this based on language also
string gAnimCard = "animations";

//------------------------------------------------------------------------------

key     gCurrentQuery;
integer gCurrentQueryLine;

// overriden by SITTARGET line in animations notecard if found
vector   gSitTargetPos = <0.0,0.0,0.01>; // never ZERO_VECTOR, which clears
rotation gSitTargetRot = <0.0,0.0,0.0,1.0>;

// home avatar position captured on sit, adjustments added to this
vector   gHomeLocalPos;
rotation gHomeLocalRot;

// hash table of animation data
list gAnimNames;
list gAnimPosAdjustments;
list gAnimRotAdjustments;
list gAnimAliases;
list gAnimDurations;

integer gNumOfAnims;
integer gCurrentAnim = 1;
string gLastAnimName = "sit";

// current animation placeholders
string    gAnimName;
vector    gAnimPosAdj;
rotation  gAnimRotAdj;
string    gAnimAlias;
string    gAnimDuration;

key      gAvatar;

////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llOwnerSay(START_TEXT);
        state reading_animations_notecard;
    }
}

//------------------------------------------------------------------------------

state reading_animations_notecard
{
    state_entry()
    {
        if (llGetInventoryType(gAnimCard)!=INVENTORY_NOTECARD)
        {
            llOwnerSay(gAnimCard + "?");
            state error;
        }

        gCurrentQueryLine = 0;
        gCurrentQuery = NULL_KEY;

        gAnimNames = [""];
        gAnimPosAdjustments = [""];
        gAnimRotAdjustments = [""];
        gAnimAliases = [""];
        gAnimDurations = [""];
        gNumOfAnims = 0;

        gCurrentQuery = llGetNotecardLine(gAnimCard,gCurrentQueryLine);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    dataserver(key _query, string _data)
    {
        if (_data == EOF) state ready;

        if (_query == gCurrentQuery)
        {
            list p = llCSV2List(_data);
            string name     = llStringTrim(llList2String(p,0),STRING_TRIM);
            string posAdj   = llStringTrim(llList2String(p,1),STRING_TRIM);
            string rotAdj   = llStringTrim(llList2String(p,2),STRING_TRIM);
            string alias    = llStringTrim(llList2String(p,3),STRING_TRIM);
            string duration = llStringTrim(llList2String(p,4),STRING_TRIM);

            if (alias == "") alias = name;

            if (posAdj == "") posAdj = "<0.0,0.0,0.0>";
            if (rotAdj == "") rotAdj = "<0.0,0.0,0.0,1.0>";

            if (name == "")
            {
                // just ignore if no name
            }

            else if (name == "SITTARGET")
            {
                gSitTargetPos = (vector) posAdj;
                gSitTargetRot = (rotation) rotAdj;
            }

            else
            {
                gAnimNames          += name;
                gAnimPosAdjustments += (vector) posAdj;
                gAnimRotAdjustments += (rotation) rotAdj;
                gAnimAliases        += alias;
                gAnimDurations      += duration;
                ++gNumOfAnims;
            }

            ++gCurrentQueryLine;
            gCurrentQuery = llGetNotecardLine(gAnimCard,gCurrentQueryLine);
        }
    }
}

//------------------------------------------------------------------------------

state ready
{
    state_entry()
    {
        llOwnerSay(READY_TEXT);
        state waiting_for_avatar;
    }
}

//------------------------------------------------------------------------------

state waiting_for_avatar
{
    state_entry()
    {
        gAvatar = NULL_KEY;
        gLastAnimName = "sit";
        gHomeLocalPos = ZERO_VECTOR;
        gHomeLocalRot = ZERO_ROTATION;
        llSitTarget(gSitTargetPos, gSitTargetRot);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            gAvatar = llAvatarOnSitTarget();
            if (gAvatar != NULL_KEY)
            {
                vector   rootPos = llGetRootPosition();
                rotation rootRot = llGetRootRotation();

                // capture the home pos and rot to which anim adjustments added
                list av = llGetObjectDetails(gAvatar,[OBJECT_POS,OBJECT_ROT]);
                gHomeLocalPos = (llList2Vector(av,0)-rootPos)/rootRot;
                gHomeLocalRot = (llList2Rot(av,1)/rootRot);

                state fetching_current_animation;
            }
        }
    }
}

//------------------------------------------------------------------------------

state switching_to_next
{
    state_entry()
    {
        ++gCurrentAnim;
        if (gCurrentAnim > gNumOfAnims) gCurrentAnim = 1;
        state fetching_current_animation;
    }
}

//------------------------------------------------------------------------------

state switching_to_prev
{
    state_entry()
    {
        --gCurrentAnim;
        if (gCurrentAnim < 1) gCurrentAnim = gNumOfAnims;
        state fetching_current_animation;
    }
}

//------------------------------------------------------------------------------

state fetching_current_animation
{
    state_entry()
    {
        gLastAnimName = gAnimName;

        gAnimName     = llList2String(gAnimNames,gCurrentAnim);
        gAnimPosAdj   = llList2Vector(gAnimPosAdjustments,gCurrentAnim);
        gAnimRotAdj   = llList2Rot(gAnimRotAdjustments,gCurrentAnim);
        gAnimAlias    = llList2String(gAnimAliases,gCurrentAnim);
        gAnimDuration = llList2String(gAnimDurations,gCurrentAnim);

        state animating;
    }
}

//------------------------------------------------------------------------------

state animating
{
    state_entry()
    {
        llRequestPermissions(gAvatar, PERMISSION_TRIGGER_ANIMATION
            | PERMISSION_TAKE_CONTROLS);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    run_time_permissions(integer _perms)
    {
        if (_perms & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS))
        {
            llTakeControls(CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);

            if (llGetAgentSize(gAvatar)==ZERO_VECTOR) // lost av from sim
            {
                llUnSit(gAvatar);
                state waiting_for_avatar;
            }

            llStopAnimation("sit"); // creeps in
            if (gLastAnimName != "") llStopAnimation(gAnimName);

            vector   avPosLocalNew = gHomeLocalPos + gAnimPosAdj;
            rotation avRotLocalNew =
                (gHomeLocalRot * gAnimRotAdj) / llGetRootRotation();

            // TODO verify the gAvatarLink with llGetLinkKey() loop
            integer link = llGetNumberOfPrims();

            llSetLinkPrimitiveParams(link,[
                PRIM_POSITION,avPosLocalNew,
                PRIM_ROTATION,avRotLocalNew]);

            llStartAnimation(gAnimName);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    control(key _id, integer _held, integer _change)
    {
        if      (_held & _change & CONTROL_UP)   state switching_to_next;
        else if (_held & _change & CONTROL_DOWN) state switching_to_prev;
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            if (llAvatarOnSitTarget()==NULL_KEY) state freeing_avatar;
        }
    }
}

//------------------------------------------------------------------------------

state freeing_avatar
{
    state_entry()
    {
        llReleaseControls();
        integer perms = llGetPermissions();
        if (perms & PERMISSION_TRIGGER_ANIMATION)
            llStopAnimation(gAnimName);
        state waiting_for_avatar;
    }
}

//------------------------------------------------------------------------------

state error
{
    state_entry()
    {
        llOwnerSay(ERROR_TEXT);
    }
}