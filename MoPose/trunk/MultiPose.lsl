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
    
    // overriden by SITTARGET line in animations notecard if found
    // (pos is never all zeros, which clears sit target completely)
    vector   SITTARGET_POS = <0.0,0.0,0.01>;
    rotation SITTARGET_ROT = <0.0,0.0,0.0,1.0>;
    
    // TODO: flesh out all the MultiPose variants into one with switches here:
    // TODO: document impact of each
    integer ACCEPT_REMOTE_COMMANDS = TRUE;
    
    // Same as MultiPose but 'hears' the following commands when avatar sitting:
    //     /1prev, /1next, /1list, /1<name>
    
    // set to a channel from 1 to 2147483647, only used when listener needed
    // (can also set to negative if using with Menu and/or HUD remote)
    // (avoid setting to 0 to reduce lag, but can if you need to for debugging)
    integer CHANNEL = 1;
    
    // change these depending on language
    string START_TEXT = "Starting up. Please wait for 'Ready' before using.";
    string READY_TEXT = "Ready.";
    
    // might change this based on language also
    string ANIMATIONS_CARD = "animations";
    
    string  HOVER_TEXT  = "";
    vector  HOVER_COLOR = <1.0,0.0,0.0>;
    float   HOVER_TRANS = 1.0;
    
    // set to TRUE to whisper each name as played, good for pose stands
    integer WHISPER_NAMES = TRUE;
    
    //------------------------------------------------------------------------------
    // (don't need to change anything beyond here)
    
    integer gListener;
    key     gCurrentQuery;
    integer gCurrentQueryLine;
    
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
    
    key gAvatar;
    
    ////////////////////////////////////////////////////////////////////////////
    
    show()
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
        if (WHISPER_NAMES) llWhisper(0,gAnimName);
    
    }
    
    ////////////////////////////////////////////////////////////////////////////
    
    default
    {
        state_entry()
        {
            llWhisper(0,START_TEXT);
    
            gAnimNames          = [""];
            gAnimPosAdjustments = [""];
            gAnimRotAdjustments = [""];
            gAnimAliases        = [""];
            gAnimDurations      = [""];
            gNumOfAnims         = 0;
    
            gHomeLocalPos = SITTARGET_POS
              
              +<0.0,0.0,0.186>/llGetRot() + <0.0,0.0,0.365>;
            gHomeLocalRot = SITTARGET_ROT;
                
    llOwnerSay((string) gHomeLocalPos +", " +(string)gHomeLocalRot);
    
            if (llGetInventoryType(ANIMATIONS_CARD) == INVENTORY_NOTECARD)
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
            gCurrentQuery = llGetNotecardLine(ANIMATIONS_CARD,1);
        }
    
        // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
        on_rez(integer _param)
        {
            llResetScript();
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
                    SITTARGET_POS = (vector) posAdj;
                    SITTARGET_ROT = (rotation) rotAdj;
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
                gCurrentQuery = llGetNotecardLine(ANIMATIONS_CARD,gCurrentQueryLine);
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
            gAvatar = NULL_KEY;
            gLastAnimName = "sit";
            gHomeLocalPos = ZERO_VECTOR;
            gHomeLocalRot = ZERO_ROTATION;
            llSitTarget(SITTARGET_POS, SITTARGET_ROT);
            llSetText(HOVER_TEXT, HOVER_COLOR, HOVER_TRANS);
            llOwnerSay(READY_TEXT);
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
                llSleep(0.3); // let's av get to sit target
                gAvatar = llAvatarOnSitTarget();
                if (gAvatar != NULL_KEY)
                {
                    llRequestPermissions(gAvatar, PERMISSION_TRIGGER_ANIMATION
                        | PERMISSION_TAKE_CONTROLS);
                    if (ACCEPT_REMOTE_COMMANDS == TRUE)
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
            else if (_message == "list") show();
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
