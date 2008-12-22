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

key     gCurrentQuery;
integer gCurrentQueryLine;

vector   gSitTargetPos = <0.0,0.0,0.01>; // never ZERO_VECTOR, which clears
rotation gSitTargetRot = ZERO_ROTATION;

// hash table of animation data
list gAnimNames;
list gAnimPoss;
list gAnimRots;
list gAliases;
list gAnimDurations;

integer gNumOfAnims;
integer gCurrentAnim = 0;

// current animation placeholders
string  gAnimName;
string  gAnimPos;
string  gAnimRot;
string  gAnimAlias;
string  gAnimDuration;

key      gAvatar;
integer  gAvatarLink;
string   gAvatarName;
vector   gAvatarPos;
vector   gAvatarLocalPos;
rotation gAvatarRot;
rotation gAvatarLocalRot;
vector   gAvatarVelocity;

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
    gAnimPos      = llList2String(gAnimPoss,_index);
    gAnimRot      = llList2String(gAnimRots,_index);
    gAnimAlias    = llList2String(gAliases,_index);
    gAnimDuration = llList2String(gAnimDurations,_index);

    //FIXME: this is wrong, change to match AvLocationDemo
    rotation rot = gAvatarLocalRot * (rotation) gAnimRot;
    vector pos   = gAvatarLocalPos + (vector) gAnimPos;

    llOwnerSay("gSitTargetPos: " + (string) gSitTargetPos);
    llOwnerSay("gSitTargetRot: " + (string) gSitTargetRot);
    llOwnerSay("gAvatarLocalPos: " + (string) gAvatarLocalPos);
    llOwnerSay("gAvatarLocalRot: " + (string) gAvatarLocalRot);

    llOwnerSay("pos: " + (string) pos);
    llOwnerSay("rot: " + (string) rot);
    llSetLinkPrimitiveParams(gAvatarLink,
        [PRIM_POSITION,pos,PRIM_ROTATION,rot]);
   llStartAnimation(gAnimName);
}

////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llOwnerSay("Starting up. Please wait for 'Ready' before using.");
        state reading_animations_notecard;
    }
}

////////////////////////////////////////////////////////////////////////////

state reading_animations_notecard
{
    state_entry()
    {
        if (llGetInventoryType("animations")!=INVENTORY_NOTECARD)
        {
            llOwnerSay("Failed to find required 'animations' notecard.");
            state error;
        }

        gCurrentQueryLine = 0;
        gCurrentQuery = NULL_KEY;

        gAnimNames = [""];
        gAnimPoss = [""];
        gAnimRots = [""];
        gAliases = [""];
        gAnimDurations = [""];
        gNumOfAnims = 0;

        llOwnerSay("Reading animations notecard ...");

        gCurrentQuery = llGetNotecardLine("animations",gCurrentQueryLine);
    }

    dataserver(key query, string data)
    {
        if (data == EOF) state ready;
        if (query == gCurrentQuery)
        {
            list p = llCSV2List(data);
            string name = llStringTrim(llList2String(p,0),STRING_TRIM);
            string offset_v = llStringTrim(llList2String(p,1),STRING_TRIM);
            string offset_r = llStringTrim(llList2String(p,2),STRING_TRIM);
            string alias = llStringTrim(llList2String(p,3),STRING_TRIM);
            string duration = llStringTrim(llList2String(p,4),STRING_TRIM);
            if (offset_v == "") offset_v = "<0.0,0.0,0.0>";
            if (offset_r == "") offset_r = "<0.0,0.0,0.0,1.0>";

            if (name == "")
            {
                llOwnerSay("WARNING: Skipping animation with no name: " + data);
            }
            else if (name == "SITTARGET")
            {
                gSitTargetPos = (vector) offset_v;
                gSitTargetRot = (rotation) offset_r;
            }
            else
            {
                gAnimNames += name;
                gAnimPoss += offset_v;
                gAnimRots += offset_r;
                gAliases += alias;
                gAnimDurations += duration;
                ++gNumOfAnims;
            }

            ++gCurrentQueryLine;
            gCurrentQuery = llGetNotecardLine("animations",gCurrentQueryLine);
        }
    }
}

////////////////////////////////////////////////////////////////////////////

state ready
{
    state_entry()
    {
        llOwnerSay("Ready");
        state waiting_for_avatar;
    }
}

////////////////////////////////////////////////////////////////////////////

state waiting_for_avatar
{
    state_entry()
    {
        gAvatar = NULL_KEY;
        gAvatarLink = 0;
        gAvatarName = "";
        gAvatarPos = ZERO_VECTOR;
        gAvatarRot = ZERO_ROTATION;
        gAvatarLocalPos = ZERO_VECTOR;
        gAvatarLocalRot = ZERO_ROTATION;
        gAvatarVelocity = ZERO_VECTOR;

        llSitTarget(gSitTargetPos, gSitTargetRot);
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            llSleep(0.1); // let's av get to sit target
            key new_avatar = llAvatarOnSitTarget();
            if (new_avatar != NULL_KEY)
            {
                gAvatar = new_avatar;
                gAvatarLink = llGetNumberOfPrims();
                list details = llGetObjectDetails(gAvatar,[
                    OBJECT_NAME, OBJECT_POS, OBJECT_ROT, OBJECT_VELOCITY]);
                gAvatarName = llList2String(details,0);
                gAvatarPos = llList2Vector(details,1);
                gAvatarRot = llList2Rot(details,2);
                gAvatarVelocity = llList2Vector(details,3);
                gAvatarLocalPos = (gAvatarPos - llGetRootPosition())/llGetRootRotation();
                gAvatarLocalRot = gAvatarRot / llGetRootRotation();
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
        llRequestPermissions(gAvatar, PERMISSION_TRIGGER_ANIMATION
            | PERMISSION_TAKE_CONTROLS);
    }

    run_time_permissions(integer perms)
    {
        if (perms & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS))
        {
            llStopAnimation("sit");
            if (gCurrentAnim == 0) gCurrentAnim = 1;
            play(gCurrentAnim);
            llTakeControls(CONTROL_RIGHT|CONTROL_LEFT, TRUE, FALSE);
        }
    }

    control(key id, integer held, integer change)
    {
        if (held & change & CONTROL_RIGHT) playNext();
        if (held & change & CONTROL_LEFT) playPrev();
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key new_avatar = llAvatarOnSitTarget();
            if (new_avatar == NULL_KEY) state stopping_animation;
        }
    }
}

////////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////

state error
{
    state_entry()
    {
        llOwnerSay("ERROR STATE. Correct and reset script.");
    }
}