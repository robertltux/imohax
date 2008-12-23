// $Id: RemotePose.lsl 7 2008-12-22 17:58:28Z imohax $

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

key     gCurrentQuery;
integer gCurrentQueryLine;

// overriden by SITTARGET line in animations notecard if found    
vector   gSitTargetPos = <0.0,0.0,0.01>; // never ZERO_VECTOR, which clears
rotation gSitTargetRot = ZERO_ROTATION;

// hash table of animation data
list gAnimNames;
list gAnimPosAdjustments;
list gAnimRotAdjustments;
list gAnimAliases;
list gAnimDurations;

integer gNumOfAnims;
integer gCurrentAnim = 0;

// current animation placeholders
string    gAnimName;
vector    gAnimPosAdj;
rotation  gAnimRotAdj;
string    gAnimAlias;
string    gAnimDuration;

key      gAvatar;
integer  gAvatarLink;
string   gAvatarName;
vector   gAvatarPos;
rotation gAvatarRot;
vector   gAvatarLocalPos;
rotation gAvatarLocalRot;
vector   gAvatarVelocity;

string gStartText = "Starting up. Please wait for 'Ready' before using.";
string gAnimCard = "animations";

////////////////////////////////////////////////////////////////////////////

playNext()
{
    integer next = gCurrentAnim+1;
    if (next <= gNumOfAnims) play(next);
    else play(1);
}

playPrev()
{
    integer prev = gCurrentAnim-1;
    if (prev >= 1) play(prev);
    else play(gNumOfAnims);
}

play(integer _index)
{
    if (gAnimName != "") llStopAnimation(gAnimName);

    gCurrentAnim  = _index;
    gAnimName     = llList2String(gAnimNames,_index);
    gAnimPosAdj   = llList2Vector(gAnimPosAdjustments,_index);
    gAnimRotAdj   = llList2Rot(gAnimRotAdjustments,_index);
    gAnimAlias    = llList2String(gAnimAliases,_index);
    gAnimDuration = llList2String(gAnimDurations,_index);

    vector   pos = gAvatarLocalPos + (gAnimPosAdj * gAvatarLocalRot);
    rotation rot = gAvatarLocalRot * gAnimRotAdj;

    llSetLinkPrimitiveParams(gAvatarLink,[
        PRIM_POSITION,pos,
        PRIM_ROTATION,rot]);

    llStartAnimation(gAnimName);
}

////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llOwnerSay(gStartText);
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
        llOwnerSay("Ready");
        state waiting_for_avatar;
    }
}

//------------------------------------------------------------------------------

state waiting_for_avatar
{
    state_entry()
    {
        gAvatar         = NULL_KEY;
        gAvatarLink     = 0;
        gAvatarName     = "";
        gAvatarPos      = ZERO_VECTOR;
        gAvatarRot      = ZERO_ROTATION;
        gAvatarLocalPos = ZERO_VECTOR;
        gAvatarLocalRot = ZERO_ROTATION;
        gAvatarVelocity = ZERO_VECTOR;

        llSitTarget(gSitTargetPos, gSitTargetRot);
    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            key _avatar = llAvatarOnSitTarget();
            if (_avatar != NULL_KEY)
            {
                list details = llGetObjectDetails(_avatar,[
                    OBJECT_NAME, OBJECT_POS, OBJECT_ROT, OBJECT_VELOCITY]);

                vector   posRoot = llGetRootPosition();
                rotation rotRoot = llGetRootRotation();

                gAvatar         = _avatar;
                gAvatarLink     = llGetNumberOfPrims();
                gAvatarName     = llList2String(details,0);
                gAvatarPos      = llList2Vector(details,1);
                gAvatarRot      = llList2Rot(details,2);
                gAvatarVelocity = llList2Vector(details,3);
                gAvatarLocalPos = (gAvatarPos-posRoot)/rotRoot;
                gAvatarLocalRot = (gAvatarRot/rotRoot)/rotRoot;

                state animating;
            }
        }
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

    run_time_permissions(integer _perms)
    {
        if (_perms & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS))
        {
            llStopAnimation("sit");
            if (gCurrentAnim == 0) gCurrentAnim = 1;
            play(gCurrentAnim);
            llTakeControls(CONTROL_RIGHT|CONTROL_LEFT, TRUE, FALSE);
        }
    }

    //TODO: change this back to pgup and pgdown for switching for consistency
    control(key _id, integer _held, integer _change)
    {
        if (_held & _change & CONTROL_RIGHT) playNext();
        if (_held & _change & CONTROL_LEFT)  playPrev();
    }

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            if (llAvatarOnSitTarget() == NULL_KEY) state stopping_animation;
        }
    }
}

//------------------------------------------------------------------------------

state stopping_animation
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
        llOwnerSay("ERROR STATE. Correct and reset script.");
    }
}