////////////////////////////////////////////////////////////////////////////
//
// $Id: MultiPose.lsl 28 2009-01-18 02:45:51Z imohax $
// [Copyright and BSD (free) license included at bottom.]
//
// Go to http://imohax.com/mopose for help, FAQ, video HOWTOs, and comments
//       ^^^^^^^^^^^^^^^^^^^^^^^^
//
////////////////////////////////////////////////////////////////////////////

// Customize your configuration in this section.

vector   TARGET_POS  = <0.0,0.0,0.01>;
rotation TARGET_ROT  = <0.0,0.0,0.0,1.0>;
float    START_TRANS = 1.0;
string   HOVER_TEXT  = "";
vector   HOVER_COLOR = <1.0,0.0,0.0>;
float    HOVER_TRANS = 1.0;
integer  COMMANDS    = TRUE;
integer  SAY_NAMES   = FALSE;
integer  HIDE        = TRUE;
integer  CHANNEL     = 1;
string   START_TEXT  = "Starting up. Please wait for 'Ready' before using.";
string   READY_TEXT  = "Ready.";
string   ANIMS_TEXT  = " animations: ";
string   ANIMS_CARD  = "animations";

// End of configuration section.

////////////////////////////////////////////////////////////////////////////
////////////////   Danger LSL ahead, scripters only. ;) ////////////////////
////////////////////////////////////////////////////////////////////////////

integer  gListener;
key      gCurrentQuery;
integer  gCurrentQueryLine;
vector   gHomeLocalPos;
rotation gHomeLocalRot;
list     gAnimNames;
list     gAnimPosAdjustments;
list     gAnimRotAdjustments;
list     gAnimAliases;
list     gAnimDurations;
integer  gNumOfAnims;
integer  gCurrentAnim;
string   gLastAnimName;
string   gAnimName;
vector   gAnimPosAdj;
rotation gAnimRotAdj;
string   gAnimAlias;
string   gAnimDuration;
key      gAvatar;

////////////////////////////////////////////////////////////////////////////

tell()
{
    integer i;
    list buffer = ["ANIMATIONS"];
    for (i=0; i<gNumOfAnims; i++)
    {
        string c = (string) (i+1);
        buffer += c + "=" + llList2String(gAnimAliases,i+1);
    }
    llSay(CHANNEL,llList2CSV(buffer));
}

//------------------------------------------------------------------------------

fetch()
{
    gLastAnimName = gAnimName;
    gAnimName     = llList2String(gAnimNames,gCurrentAnim);
    gAnimPosAdj   = llList2Vector(gAnimPosAdjustments,gCurrentAnim);
    gAnimRotAdj   = llList2Rot(gAnimRotAdjustments,gCurrentAnim);
    gAnimAlias    = llList2String(gAnimAliases,gCurrentAnim);
    gAnimDuration = llList2String(gAnimDurations,gCurrentAnim);
}

//------------------------------------------------------------------------------

next()
{
    --gCurrentAnim;
    if (gCurrentAnim < 1) gCurrentAnim = gNumOfAnims;
    play(gCurrentAnim);
}

//------------------------------------------------------------------------------

prev()
{
    ++gCurrentAnim;
    if (gCurrentAnim > gNumOfAnims) gCurrentAnim = 1;
    play(gCurrentAnim);
}

//------------------------------------------------------------------------------

play(integer _anim)
{
    gCurrentAnim = _anim;
    fetch();
    if (gLastAnimName != "") llStopAnimation(gLastAnimName);

    if (llGetAgentSize(gAvatar)==ZERO_VECTOR) // lost av from sim
    {
        llUnSit(gAvatar);
        return;
    }

    vector   avPosLocalNew = gHomeLocalPos + gAnimPosAdj;
    rotation avRotLocalNew =
        (gHomeLocalRot * gAnimRotAdj) / llGetRootRotation();

    // TODO verify the gAvatarLink with llGetLinkKey() loop
    integer link = llGetNumberOfPrims();

    llSetLinkPrimitiveParams(link,[
        PRIM_POSITION,avPosLocalNew,
        PRIM_ROTATION,avRotLocalNew]);

    llStartAnimation(gAnimName);
    if (SAY_NAMES) llWhisper(0,gAnimName);

}

//------------------------------------------------------------------------------

show()
{
    if (!HIDE) return;
    llSetAlpha(START_TRANS, ALL_SIDES);
    llSetText(HOVER_TEXT,HOVER_COLOR,HOVER_TRANS);
}

//------------------------------------------------------------------------------

hide()
{
    if (!HIDE) return;
    llSetAlpha(0.0, ALL_SIDES);
    llSetText("",ZERO_VECTOR,0.0);
}

////////////////////////////////////////////////////////////////////////////

default
{
    state_entry()
    {
        llWhisper(0,START_TEXT);
        
        show();

        gCurrentAnim        = 1;
        gLastAnimName       = "sit";
        gAnimNames          = [""];
        gAnimPosAdjustments = [""];
        gAnimRotAdjustments = [""];
        gAnimAliases        = [""];
        gAnimDurations      = [""];
        gNumOfAnims         = 0;

        gHomeLocalPos = TARGET_POS
            + <0.0,0.0,0.186>/llGetRot() + <0.0,0.0,0.365>; // for sl bug
        gHomeLocalRot = TARGET_ROT;

        if (llGetInventoryType(ANIMS_CARD) == INVENTORY_NOTECARD)
            state reading_animations_notecard;
        else
            state scan_inventory_for_animations;
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    on_rez(integer _param)
    {
        llResetScript();
    }
}

//------------------------------------------------------------------------------

state reading_animations_notecard{

    state_entry()
    {
        gCurrentQueryLine = 0;
        gCurrentQuery = NULL_KEY;
        gCurrentQuery = llGetNotecardLine(ANIMS_CARD,0);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    on_rez(integer _param)
    {
        llResetScript();
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    dataserver(key _query, string _data)
    {
        if (_data == EOF)
        {
            llWhisper(0,(string) gNumOfAnims + ANIMS_TEXT
                + llList2CSV(llList2List(gAnimAliases,1,-1)));
            state ready;
        }

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

            if (name == "") ; // skip
            else if (name == "SITTARGET")
            {
                TARGET_POS = (vector) posAdj;
                TARGET_ROT = (rotation) rotAdj;
            }
            else
            {
                gAnimNames          += name;
                gAnimPosAdjustments += (vector)   posAdj;
                gAnimRotAdjustments += (rotation) rotAdj;
                gAnimAliases        += alias;
                gAnimDurations      += duration;
                ++gNumOfAnims;
            }

            ++gCurrentQueryLine;
            gCurrentQuery = llGetNotecardLine(ANIMS_CARD,gCurrentQueryLine);
        }
    }
}

//------------------------------------------------------------------------------

state scan_inventory_for_animations
{
    state_entry()
    {
        state ready;
        //TODO
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    on_rez(integer _param)
    {
        llResetScript();
    }
}

//------------------------------------------------------------------------------

state ready
{
    state_entry()
    {
        gAvatar       = NULL_KEY;
        gLastAnimName = "sit";
        gHomeLocalPos = ZERO_VECTOR;
        gHomeLocalRot = ZERO_ROTATION;

        llSitTarget(TARGET_POS, TARGET_ROT);
        llSetText(HOVER_TEXT, HOVER_COLOR, HOVER_TRANS);
        llWhisper(0,READY_TEXT);
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    on_rez(integer _param)
    {
        llResetScript();
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    changed(integer _change)
    {
        if (_change & CHANGED_LINK)
        {
            llSleep(0.3); // lets av get to sit target
            gAvatar = llAvatarOnSitTarget();
            if (gAvatar != NULL_KEY)
            {
                llRequestPermissions(gAvatar, PERMISSION_TRIGGER_ANIMATION
                    | PERMISSION_TAKE_CONTROLS);
                if (COMMANDS == TRUE)
                    gListener = llListen(CHANNEL,"",NULL_KEY,"");
            }
            else
            {
                llReleaseControls();
                integer perms = llGetPermissions();
                if ((perms & PERMISSION_TRIGGER_ANIMATION)
                    && (llGetAgentSize(gAvatar)!=ZERO_VECTOR))
                        llStopAnimation(gAnimName);
                llListenRemove(gListener);
                show();
            }
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    run_time_permissions(integer _perms)
    {
        if (_perms & (PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS))
        {
            llTakeControls(CONTROL_UP|CONTROL_DOWN, TRUE, FALSE);
            llStopAnimation("sit");
            hide();
            play(gCurrentAnim);
        }
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    control(key _id, integer _held, integer _change)
    {
        if      (_held & _change & CONTROL_UP)   next();
        else if (_held & _change & CONTROL_DOWN) prev();
    }

    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

    listen(integer _channel, string _name, key _id, string _message)
    {
        if (_message == "") return;

        if      (_message == "next") next();
        else if (_message == "prev") prev();
        else if (_message == "tell") tell();
        else if (llSubStringIndex(_message,"#")==0)
        {
            play((integer) llGetSubString(_message,1,-1));
        }
        else
        {
            integer anim = llListFindList(gAnimAliases, [_message]);
            if (anim == -1)
                anim = llListFindList(gAnimNames,[_message]);
            if (anim == -1) return;
            play(anim);
        }
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